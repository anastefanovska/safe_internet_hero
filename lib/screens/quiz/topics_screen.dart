import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/topic_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import 'quiz_screen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class TopicsScreen extends StatefulWidget {
  /// When set, shows only topics for this category. Otherwise shows all.
  final String? filterCategoryId;
  final String? filterCategoryTitle;

  const TopicsScreen({
    super.key,
    this.filterCategoryId,
    this.filterCategoryTitle,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _topicsService = TopicsService();
  final _questionService = QuestionService();
  final _searchController = TextEditingController();
  String _searchText = '';
  String? _activeCategoryId;

  @override
  void initState() {
    super.initState();
    _activeCategoryId = widget.filterCategoryId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<double> _topicProgress(
      UserModel? user, String categoryId, String topicId) async {
    if (user == null) return 0;
    final total = await _questionService.getTotalQuestionsCount(
        categoryId: categoryId, topicId: topicId);
    if (total == 0) return 0;
    final all = await _questionService.getQuestions(
        categoryId: categoryId, topicId: topicId, limit: 1000);
    final answered =
        all.where((q) => user.answeredQuestions.contains(q.id)).length;
    return answered / total;
  }

  Future<void> _openQuiz(
      BuildContext context, CategoryModel category, TopicModel topic) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    if (!isGuest && user != null) {
      final progress = await _topicProgress(user, category.id, topic.id);
      if (progress >= 1.0) {
        if (!context.mounted) return;
        _showCompletedDialog(context, category, topic);
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => QuizScreen(
          categoryId: category.id,
          categoryName: category.title,
          topicId: topic.id,
          topicName: topic.name,
          color: AppCategoryIcon.colorFor(category.title),
        ),
      ),
    );
  }

  void _showCompletedDialog(
      BuildContext context, CategoryModel category, TopicModel topic) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/lottie/trophy.json',
                    width: 100, height: 100, repeat: false),
                const SizedBox(height: 4),
                Text(
                  l10n.quizTopicComplete,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.topicsCompletedBody(topic.name),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: l10n.topicsPlayAgain,
                  variant: AppButtonVariant.primary,
                  icon: Icons.replay_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => QuizScreen(
                          categoryId: category.id,
                          categoryName: category.title,
                          topicId: topic.id,
                          topicName: topic.name,
                          color: AppCategoryIcon.colorFor(category.title),
                          forReplay: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: l10n.quizResultBackToTopics,
                  variant: AppButtonVariant.secondary,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamError(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textLight, size: 40),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).topicsCouldNotLoad,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {}),
                child: Text(AppLocalizations.of(context).commonRetry),
              ),
            ],
          ),
        ),
      );

  // Build flat item list: CategoryModel (header) + _TopicRow entries
  List<Object> _buildItems(
    List<CategoryModel> cats,
    List<TopicModel> allTopics,
    String query,
  ) {
    final items = <Object>[];
    final showHeaders = _activeCategoryId == null;
    int globalIndex = 0;

    for (final cat in cats) {
      final topics = allTopics
          .where((t) => t.categoryId == cat.id)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      final filtered = query.isEmpty
          ? topics
          : topics
              .where((t) =>
                  t.name.toLowerCase().contains(query) ||
                  t.desc.toLowerCase().contains(query))
              .toList();

      if (filtered.isEmpty) continue;

      if (showHeaders) items.add(cat);
      for (final t in filtered) {
        items.add(_TopicEntry(
            topic: t, category: cat, index: globalIndex));
        globalIndex++;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    final headerTitle = widget.filterCategoryTitle ?? l10n.topicsAllTopics;
    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          // Desktop gets a compact title (no oversized gradient bar, and the
          // browser's back button replaces the in-app arrow).
          if (desktop)
            _DesktopTopicsHeader(
              title: headerTitle,
              showSubtitle: widget.filterCategoryId == null,
              showIcon: widget.filterCategoryId != null,
            ),
          if (!desktop)
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, Color(0xFF5AB4F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row (matches create-account / login)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (widget.filterCategoryId != null)
                        AppCategoryIcon(
                          title: headerTitle,
                          size: 36,
                          overrideColor: Colors.white.withValues(alpha: 0.9),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title + subtitle below the arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppCategoryIcon.localizedTitle(headerTitle, l10n),
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (widget.filterCategoryId == null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.topicsSubtitle,
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search + chips + list ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _topicsService.watchCategories(),
              builder: (context, catSnap) {
                if (catSnap.hasError) return _buildStreamError(context);
                if (!catSnap.hasData) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children:
                        List.generate(4, (_) => const TopicSkeletonCard()),
                  );
                }

                return StreamBuilder<List<TopicModel>>(
                  stream: _topicsService.watchAllTopics(),
                  builder: (context, topicSnap) {
                    if (topicSnap.hasError) return _buildStreamError(context);
                    if (!topicSnap.hasData) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: List.generate(
                            4, (_) => const TopicSkeletonCard()),
                      );
                    }

                    final allCategories = catSnap.data!;
                    final allTopics = topicSnap.data!;

                    // Apply active category filter
                    final visibleCats = _activeCategoryId != null
                        ? allCategories
                            .where((c) => c.id == _activeCategoryId)
                            .toList()
                        : allCategories;

                    final query = _searchText.trim().toLowerCase();
                    final items = _buildItems(visibleCats, allTopics, query);

                    const maxW = 740.0;

                    Widget searchBar = Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _SearchBar(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchText = v),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      ),
                    );

                    Widget? chips;
                    if (widget.filterCategoryId == null &&
                        allCategories.length > 1) {
                      chips = SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          children: [
                            _Chip(
                              label: l10n.topicsFilterAll,
                              selected: _activeCategoryId == null,
                              color: AppColors.blue,
                              onTap: () => setState(
                                  () => _activeCategoryId = null),
                            ),
                            ...allCategories.map(
                              (cat) => _Chip(
                                label: AppCategoryIcon.localizedTitle(cat.title, l10n),
                                selected: _activeCategoryId == cat.id,
                                color: AppCategoryIcon.colorFor(
                                    cat.title),
                                onTap: () => setState(
                                    () => _activeCategoryId = cat.id),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget topicList = items.isEmpty
                        ? _EmptyState(query: query)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 4, 16, 32),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final item = items[i];
                              if (item is CategoryModel) {
                                return _SectionHeader(
                                    category: item);
                              }
                              if (item is _TopicEntry) {
                                return _TopicCard(
                                  entry: item,
                                  user: user,
                                  isGuest: isGuest,
                                  topicProgress: _topicProgress,
                                  onTap: () => _openQuiz(
                                      ctx, item.category, item.topic),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );

                    if (desktop) {
                      searchBar = Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: maxW),
                          child: searchBar,
                        ),
                      );
                      if (chips != null) {
                        chips = Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: maxW),
                            child: chips,
                          ),
                        );
                      }
                      topicList = Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: maxW),
                          child: topicList,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        searchBar,
                        if (chips != null) ...[
                          const SizedBox(height: 10),
                          chips,
                        ],
                        const SizedBox(height: 8),
                        Expanded(child: topicList),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Desktop header ───────────────────────────────────────────────────────────

class _DesktopTopicsHeader extends StatelessWidget {
  final String title;
  final bool showSubtitle;
  final bool showIcon;
  const _DesktopTopicsHeader({
    required this.title,
    required this.showSubtitle,
    required this.showIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
            child: Row(
              children: [
                if (showIcon) ...[
                  AppCategoryIcon(title: title, size: 36),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppCategoryIcon.localizedTitle(title, AppLocalizations.of(context)),
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context).topicsSubtitle,
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data entry ───────────────────────────────────────────────────────────────

class _TopicEntry {
  final TopicModel topic;
  final CategoryModel category;
  final int index;
  _TopicEntry(
      {required this.topic, required this.category, required this.index});
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final CategoryModel category;
  const _SectionHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppCategoryIcon.colorFor(category.title);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          AppCategoryIcon(title: category.title, size: 24),
          const SizedBox(width: 8),
          Text(
            AppCategoryIcon.localizedTitle(category.title, AppLocalizations.of(context)),
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Topic card ───────────────────────────────────────────────────────────────

class _TopicCard extends StatefulWidget {
  final _TopicEntry entry;
  final UserModel? user;
  final bool isGuest;
  final Future<double> Function(UserModel?, String, String) topicProgress;
  final VoidCallback onTap;

  const _TopicCard({
    required this.entry,
    required this.user,
    required this.isGuest,
    required this.topicProgress,
    required this.onTap,
  });

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  Future<double>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(_TopicCard old) {
    super.didUpdateWidget(old);
    if (old.user?.id != widget.user?.id ||
        old.entry.topic.id != widget.entry.topic.id ||
        old.user?.answeredQuestions.length !=
            widget.user?.answeredQuestions.length) {
      _initFuture();
    }
  }

  void _initFuture() {
    if (!widget.isGuest && widget.user != null) {
      _progressFuture = widget.topicProgress(
          widget.user, widget.entry.category.id, widget.entry.topic.id);
    } else {
      _progressFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.entry.topic;
    final category = widget.entry.category;
    final catColor = AppCategoryIcon.colorFor(category.title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Category icon
            AppCategoryIcon(title: category.title, size: 46),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (topic.isNew)
                        _Badge(label: AppLocalizations.of(context).topicsBadgeNew, color: AppColors.pink),
                      if (topic.isUpdated)
                        _Badge(label: AppLocalizations.of(context).topicsBadgeUpd, color: AppColors.amber),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    topic.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  if (!widget.isGuest && widget.user != null &&
                      _progressFuture != null)
                    FutureBuilder<double>(
                      future: _progressFuture,
                      builder: (ctx, snap) {
                        final p = snap.data ?? 0.0;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(topic.id),
                            tween: Tween(begin: 0, end: p),
                            duration: const Duration(milliseconds: 700),
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  catColor),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(catColor),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Arrow button
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: catColor,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(
            delay: Duration(
                milliseconds: (widget.entry.index * 45).clamp(0, 360)))
        .fadeIn(duration: const Duration(milliseconds: 280))
        .slideY(
            begin: 0.06,
            end: 0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut);
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).topicsSearchHint,
          hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.blue, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon:
                      const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty
                  ? AppLocalizations.of(context).topicsNoMatch(query)
                  : AppLocalizations.of(context).topicsNoneAvailable,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small badge ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
