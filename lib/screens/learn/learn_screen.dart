import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import 'article_screen.dart';
import 'video_screen.dart';

// ─── Content-type filter ──────────────────────────────────────────────────────

enum _TypeFilter { all, articles, videos }

extension _TypeFilterX on _TypeFilter {
  String labelOf(AppLocalizations l10n) => switch (this) {
        _TypeFilter.all => l10n.learnFilterAll,
        _TypeFilter.articles => l10n.learnFilterArticles,
        _TypeFilter.videos => l10n.learnFilterVideos,
      };
  IconData get icon => switch (this) {
        _TypeFilter.all => Icons.apps_rounded,
        _TypeFilter.articles => Icons.menu_book_rounded,
        _TypeFilter.videos => Icons.play_circle_rounded,
      };
  bool matches(LearningContentModel item) => switch (this) {
        _TypeFilter.all =>
          item.type == ContentType.article || item.type == ContentType.video,
        _TypeFilter.articles => item.type == ContentType.article,
        _TypeFilter.videos => item.type == ContentType.video,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _learningService = LearningService();
  final _topicsService = TopicsService();

  _TypeFilter _typeFilter = _TypeFilter.all;
  String? _selectedCategoryId; // null = all categories

  // categoryId -> name  (loaded from Firestore)
  Map<String, String> _categoryNames = {};
  // topicId -> name  (for card labels)
  Map<String, String> _topicNames = {};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final cats = await _topicsService.getCategories();
    final topics = await _topicsService.getAllTopics();
    if (!mounted) return;
    setState(() {
      _categoryNames = {for (final c in cats) c.id: c.title};
      _topicNames = {for (final t in topics) t.id: t.name};
    });
  }

  String _categoryLabel(String id) => AppCategoryIcon.localizedTitle(
      _categoryNames[id] ?? _slugToTitle(id), AppLocalizations.of(context));

  String _topicLabel(String id) =>
      _topicNames[id] ?? _slugToTitle(id);

  static String _slugToTitle(String slug) => slug
      .split('_')
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join(' ');


  // Ordered unique category IDs in the type-filtered list (skips untagged items)
  List<String> _categoriesFrom(List<LearningContentModel> items) {
    final seen = <String>{};
    return items
        .where((i) => i.categoryId.isNotEmpty && seen.add(i.categoryId))
        .map((i) => i.categoryId)
        .toList();
  }

  void _openContent(LearningContentModel item) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => item.type == ContentType.video
            ? VideoScreen(content: item)
            : ArticleScreen(content: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = context.watch<AuthProvider>().user;

    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header (mobile only — desktop reads the page from the rail
          // and stats from the side panel) ────────────────────────────
          if (!desktop)
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppTopBar(
                    stars: user?.totalStars ?? 0,
                    streak: user?.currentStreak ?? 0,
                    coins: user?.coins ?? 0,
                  ),
                if (!desktop) Container(height: 1, color: AppColors.border),
                TabHeader(
                  title: l10n.navLearn,
                  subtitle: l10n.learnSubtitle,
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Content list ─────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                      child: StreamBuilder<List<LearningContentModel>>(
              stream: _learningService.getAllContent(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Column(
                    children: [
                      _FilterBarSkeleton(),
                      Expanded(
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: List.generate(
                              3, (_) => const ContentSkeletonCard()),
                        ),
                      ),
                    ],
                  );
                }

                final allItems = snap.data!
                    .where((i) =>
                        i.type == ContentType.article ||
                        i.type == ContentType.video)
                    .toList();

                // Type-filtered list (used to build category chips)
                final typeFiltered =
                    allItems.where(_typeFilter.matches).toList();

                final categories = _categoriesFrom(typeFiltered);

                // Reset category if it no longer exists in current type
                if (_selectedCategoryId != null &&
                    !categories.contains(_selectedCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => setState(() => _selectedCategoryId = null));
                }

                final filtered = typeFiltered
                    .where((i) =>
                        _selectedCategoryId == null ||
                        i.categoryId == _selectedCategoryId)
                    .toList();

                return Column(
                  children: [
                    // ── Filter bar ───────────────────────────────────
                    _FilterBar(
                      typeFilter: _typeFilter,
                      categories: categories,
                      selectedCategoryId: _selectedCategoryId,
                      categoryLabel: _categoryLabel,
                      onTypeChanged: (t) => setState(() {
                        _typeFilter = t;
                        _selectedCategoryId = null;
                      }),
                      onCategoryChanged: (id) =>
                          setState(() => _selectedCategoryId = id),
                    ),

                    // ── List ─────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              label: _selectedCategoryId != null
                                  ? _categoryLabel(_selectedCategoryId!)
                                  : _typeFilter != _TypeFilter.all
                                      ? _typeFilter.labelOf(l10n)
                                      : null)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 40),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final item = filtered[i];
                                return _ContentCard(
                                  item: item,
                                  topicLabel: _topicLabel(item.topicId),
                                  onTap: () => _openContent(item),
                                )
                                    .animate(
                                        delay: Duration(
                                            milliseconds: i * 60))
                                    .fadeIn(duration: 280.ms)
                                    .slideY(
                                        begin: 0.06,
                                        end: 0,
                                        duration: 280.ms,
                                        curve: Curves.easeOut);
                              },
                            ),
                    ),
                  ],
                );
              },
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _TypeFilter typeFilter;
  final List<String> categories;
  final String? selectedCategoryId;
  final String Function(String) categoryLabel;
  final void Function(_TypeFilter) onTypeChanged;
  final void Function(String?) onCategoryChanged;

  const _FilterBar({
    required this.typeFilter,
    required this.categories,
    required this.selectedCategoryId,
    required this.categoryLabel,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showCategories =
        typeFilter != _TypeFilter.all && categories.isNotEmpty;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Row 1 — type (3 equal full-width chips)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: _TypeFilter.values.map((f) {
                final selected = typeFilter == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTypeChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? AppColors.blue : AppColors.border,
                          width: 1.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.blue.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            f.icon,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 17,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.labelOf(l10n),
                            style: GoogleFonts.nunito(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Row 2 — category chips (only when Articles or Videos selected)
          if (showCategories) ...[
            Container(height: 1, color: AppColors.background),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                children: [
                  _Chip(
                    label: l10n.topicsFilterAll,
                    selected: selectedCategoryId == null,
                    color: AppColors.blue,
                    onTap: () => onCategoryChanged(null),
                  ),
                  ...categories.map((id) => _Chip(
                        label: categoryLabel(id),
                        selected: selectedCategoryId == id,
                        color: AppCategoryIcon.colorFor(id),
                        onTap: () => onCategoryChanged(
                            selectedCategoryId == id ? null : id),
                      )),
                ],
              ),
            ),
          ],

          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}


class _FilterBarSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: List.generate(
                3,
                (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1000));
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? label;
  const _EmptyState({this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.blue, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              label != null ? AppLocalizations.of(context).learnNoContentFor(label!) : AppLocalizations.of(context).learnNoContent,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).learnCheckBackSoon,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _extractVideoId(String input) {
  final s = input.trim();
  if (!s.contains('/') && !s.contains('?')) return s;
  try {
    final uri = Uri.parse(s);
    if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v']!;
    }
    final embedIdx = uri.pathSegments.indexOf('embed');
    if (embedIdx >= 0 && embedIdx + 1 < uri.pathSegments.length) {
      return uri.pathSegments[embedIdx + 1];
    }
  } catch (_) {}
  return s;
}

// ─── Content card ─────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final LearningContentModel item;
  final String topicLabel;
  final VoidCallback onTap;

  const _ContentCard({
    required this.item,
    required this.topicLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == ContentType.video;
    final accent = AppCategoryIcon.colorFor(item.categoryId);
    final darkAccent = AppCategoryIcon.darkColorFor(item.categoryId);
    final catIcon = AppCategoryIcon.iconFor(item.categoryId);
    final xpLabel = isVideo
        ? '+5 XP'
        : '+${(item.readTimeMinutes * 2).clamp(4, 20)} XP';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // ── Left panel (stretches to the card's natural height) ──
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: SizedBox(
                    width: 80,
                    child: isVideo
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                'https://img.youtube.com/vi/${_extractVideoId(item.content)}/mqdefault.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFF4444),
                                        Color(0xFFCC0000),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                  color: Colors.black.withValues(alpha: 0.32)),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_filled_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent, darkAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(children: [
                              Positioned(
                                top: -18,
                                right: -18,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              Center(
                                child:
                                    Icon(catIcon, color: Colors.white, size: 30),
                              ),
                            ]),
                          ),
                  ),
                ),
              ),

              // ── Right content ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 80),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Topic pill
                        if (topicLabel.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              topicLabel,
                              style: GoogleFonts.nunito(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Title
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.05,
                          ),
                        ),

                        // Description
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            // Show only first line of description
                            item.description.split('\n').first,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Footer
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.green
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.green, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    xpLabel,
                                    style: GoogleFonts.nunito(
                                      color: AppColors.greenDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ]),
                          ),
                          if (!isVideo && item.readTimeMinutes > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${item.readTimeMinutes} min',
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            isVideo
                                ? Icons.play_arrow_rounded
                                : Icons.arrow_forward_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

