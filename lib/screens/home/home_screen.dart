import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/enums.dart';
import '../../models/moderator_request_model.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/moderator_service.dart';
import '../../services/notification_service.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../admin/admin_dashboard_screen.dart';
import '../moderator/moderator_request_screen.dart';
import '../moderator/moderator_screen.dart';
import '../quiz/quiz_screen.dart';
import '../quiz/topics_screen.dart';
import '../social/notifications_screen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicsService = TopicsService();
  final _questionService = QuestionService();

  Future<int> _completedTopicCount(
      UserModel user, String categoryId, List<TopicModel> topics) async {
    if (topics.isEmpty) return 0;
    final results = await Future.wait(topics.map((t) async {
      final total = await _questionService.getTotalQuestionsCount(
          categoryId: categoryId, topicId: t.id);
      if (total == 0) return false;
      final all = await _questionService.getQuestions(
          categoryId: categoryId, topicId: t.id, limit: 1000);
      return all.where((q) => user.answeredQuestions.contains(q.id)).length >=
          total;
    }));
    return results.where((done) => done).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final username = isGuest ? l10n.homeDefaultName : (user?.username ?? l10n.homeDefaultName);
    final stars = user?.totalStars ?? 0;
    final streak = user?.currentStreak ?? 0;
    final coins = user?.coins ?? 0;

    final desktop = isDesktop(context);

    // Content children shared between desktop and mobile layouts.
    final contentChildren = <Widget>[
      // Practice weak spots — surfaced at the top when the user has enough
      // review material.
      if (!isGuest &&
          user != null &&
          user.incorrectlyAnsweredIds.length >= 3) ...[
        _PracticeCard(
          count: user.incorrectlyAnsweredIds.length,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => QuizScreen(
                categoryId: 'practice',
                categoryName: l10n.homePracticeCategory,
                topicId: '',
                topicName: l10n.homeWeakSpots,
                color: AppColors.orange,
                specificIds: user.incorrectlyAnsweredIds.take(10).toList(),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.06, end: 0, duration: 350.ms),
        const SizedBox(height: 20),
      ],

      // Section header
      _SectionHeader(
        onSeeAll: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => const TopicsScreen()),
        ),
      ).animate(delay: 80.ms).fadeIn(duration: 300.ms),

      const SizedBox(height: 14),

      // Category quest cards
      StreamBuilder<List<CategoryModel>>(
        stream: _topicsService.watchCategories(),
        builder: (context, catSnap) {
          if (catSnap.hasError) return _buildError();
          return StreamBuilder<List<TopicModel>>(
            stream: _topicsService.watchAllTopics(),
            builder: (context, topicSnap) {
              if (topicSnap.hasError) return _buildError();
              if (!catSnap.hasData || !topicSnap.hasData) {
                return Column(
                  children:
                      List.generate(3, (_) => const _QuestCardSkeleton()),
                );
              }
              final categories = catSnap.data!;
              final allTopics = topicSnap.data!;
              List<TopicModel> topicsFor(String catId) => allTopics
                  .where((t) => t.categoryId == catId)
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));

              return Column(
                children: categories.asMap().entries.map((e) {
                  final cat = e.value;
                  final topics = topicsFor(cat.id);
                  return _QuestCard(
                    category: cat,
                    topics: topics,
                    user: user,
                    isGuest: isGuest,
                    completedTopics: _completedTopicCount,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => TopicsScreen(
                          filterCategoryId: cat.id,
                          filterCategoryTitle: cat.title,
                        ),
                      ),
                    ),
                  )
                      .animate(
                          delay: Duration(
                              milliseconds: 120 + e.key * 60))
                      .fadeIn(duration: 300.ms)
                      .slideY(
                          begin: 0.07,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOut);
                }).toList(),
              );
            },
          );
        },
      ),

      // Admin button — badged with the open review workload.
      if (user?.isAdmin == true) ...[
        const SizedBox(height: 8),
        const _AdminPanelButton().animate(delay: 500.ms).fadeIn(),
      ],

      // Moderator tools (for approved moderators) — badged with the number of
      // their submissions that need changes.
      if (user?.isModerator == true) ...[
        const SizedBox(height: 8),
        _ModeratorToolsButton(userId: user!.id)
            .animate(delay: 500.ms)
            .fadeIn(),
      ]
      // Become-a-moderator entry (logged-in, non-admin, non-moderator users)
      else if (!isGuest && user != null && user.isAdmin != true) ...[
        const SizedBox(height: 8),
        AppButton(
          label: l10n.homeBecomeModerator,
          variant: AppButtonVariant.secondary,
          icon: Icons.shield_outlined,
          onTap: () => Navigator.push(
              context,
              AppPageRoute(
                  builder: (_) => const ModeratorRequestScreen())),
        ).animate(delay: 500.ms).fadeIn(),
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top stats bar (hidden on desktop) ─────────────────────────────
          if (!desktop)
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  AppTopBar(stars: stars, streak: streak, coins: coins),
                  Container(height: 1, color: AppColors.border),
                ],
              ),
            ),

          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero banner — full-width ─────────────────────────────
                  _HeroBanner(
                    username: username,
                    streak: streak,
                    // Guests are unauthenticated and have no notifications.
                    notificationsUserId: isGuest ? null : user?.id,
                    notificationsIsAdmin: user?.isAdmin == true,
                  ).animate().fadeIn(duration: 400.ms),

                  // ── Padded content (centered on all sizes) ───────────────
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: kContentMaxWidth),
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: contentChildren,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textLight, size: 36),
              const SizedBox(height: 10),
              Text(l10n.homeCouldNotLoad,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              TextButton(
                  onPressed: () => setState(() {}),
                  child: Text(l10n.commonRetry)),
            ],
          ),
        ),
      );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String username;
  final int streak;
  final String? notificationsUserId;
  final bool notificationsIsAdmin;
  const _HeroBanner({
    required this.username,
    required this.streak,
    this.notificationsUserId,
    this.notificationsIsAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue, Color(0xFF1A7FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background circles
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: 80,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Streak badge (if active)
                      if (streak > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Colors.white,
                                  size: 13),
                              const SizedBox(width: 4),
                              Text(
                                l10n.homeStreakBadge(streak),
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        const SizedBox(height: 4),
                      ],

                      Text(
                        l10n.homeGreeting(username),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.homeHeroSubtitle,
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Arrow down hint
                      Row(
                        children: [
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 16),
                          Text(
                            l10n.homeChooseTopic,
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Mascot
                SizedBox(
                  width: 90,
                  height: 148,
                  child: SvgPicture.asset(
                    'assets/images/mascot.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ],
            ),
          ),

          // Notification bell (top-right) — only for signed-in users.
          if (notificationsUserId != null)
            Positioned(
              top: 8,
              right: 8,
              child: _NotificationBell(
                userId: notificationsUserId!,
                isAdmin: notificationsIsAdmin,
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlays a small red workload count pill on the top-right of a home button.
class _BadgedButton extends StatelessWidget {
  final Widget child;
  final int count;
  const _BadgedButton({required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -2,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              constraints: const BoxConstraints(minWidth: 22),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}

/// Admin Panel button badged with pending submissions + pending moderator
/// requests (the admin's open review workload).
class _AdminPanelButton extends StatelessWidget {
  const _AdminPanelButton();

  @override
  Widget build(BuildContext context) {
    final button = AppButton(
      label: AppLocalizations.of(context).homeAdminPanel,
      variant: AppButtonVariant.secondary,
      icon: Icons.admin_panel_settings_rounded,
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (_) => const AdminDashboardScreen()),
      ),
    );
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchPendingSubmissions(),
      builder: (context, subSnap) {
        final subs = subSnap.data?.length ?? 0;
        return StreamBuilder<List<ModeratorRequestModel>>(
          stream: ModeratorService().watchPendingRequests(),
          builder: (context, reqSnap) {
            final reqs = reqSnap.data?.length ?? 0;
            return _BadgedButton(count: subs + reqs, child: button);
          },
        );
      },
    );
  }
}

/// Moderator Tools button badged with the count of the moderator's own
/// submissions that need changes (their actionable items).
class _ModeratorToolsButton extends StatelessWidget {
  final String userId;
  const _ModeratorToolsButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    final button = AppButton(
      label: AppLocalizations.of(context).homeModeratorTools,
      variant: AppButtonVariant.secondary,
      icon: Icons.shield_rounded,
      onTap: () => Navigator.push(
        context,
        AppPageRoute(builder: (_) => const ModeratorScreen()),
      ),
    );
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchSubmissionsByAuthor(userId),
      builder: (context, snap) {
        final count = (snap.data ?? const <QuestionModel>[])
            .where((q) => q.status == QuestionStatus.needsRevision)
            .length;
        return _BadgedButton(count: count, child: button);
      },
    );
  }
}

/// White notification bell with an unread-count badge, sitting over the hero
/// banner. Opens the (previously unreachable) notifications screen.
class _NotificationBell extends StatelessWidget {
  final String userId;

  /// Admins get no notification docs of their own, so their bell also surfaces
  /// the live review queue (pending requests + submissions) — this is what makes
  /// it light up when new questions come in. It reflects work still waiting, so
  /// it clears as items are approved/rejected/deleted, not merely on open.
  final bool isAdmin;
  const _NotificationBell({required this.userId, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(userId),
      builder: (context, unreadSnap) {
        final unread = unreadSnap.data ?? 0;
        if (!isAdmin) return _bell(context, unread);
        return StreamBuilder<List<ModeratorRequestModel>>(
          stream: ModeratorService().watchPendingRequests(),
          builder: (context, reqSnap) {
            return StreamBuilder<List<QuestionModel>>(
              stream: QuestionService().watchPendingSubmissions(),
              builder: (context, subSnap) {
                final total = unread +
                    (reqSnap.data?.length ?? 0) +
                    (subSnap.data?.length ?? 0);
                return _bell(context, total);
              },
            );
          },
        );
      },
    );
  }

  Widget _bell(BuildContext context, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).settingsNotifications,
          icon: const Icon(Icons.notifications_rounded,
              color: Colors.white, size: 24),
          onPressed: () => Navigator.push(
            context,
            AppPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.quiz_rounded, color: AppColors.blue, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.homeChooseQuest,
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.05,
          ),
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  l10n.commonSeeAll,
                  style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.blue, size: 11),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quest card (category) ────────────────────────────────────────────────────

class _QuestCard extends StatefulWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final UserModel? user;
  final bool isGuest;
  final Future<int> Function(UserModel, String, List<TopicModel>)
      completedTopics;
  final VoidCallback onTap;

  const _QuestCard({
    required this.category,
    required this.topics,
    required this.user,
    required this.isGuest,
    required this.completedTopics,
    required this.onTap,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  Future<int>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(_QuestCard old) {
    super.didUpdateWidget(old);
    if (old.user?.id != widget.user?.id ||
        old.category.id != widget.category.id ||
        old.user?.answeredQuestions.length !=
            widget.user?.answeredQuestions.length) {
      _initFuture();
    }
  }

  void _initFuture() {
    _progressFuture =
        (!widget.isGuest && widget.user != null && widget.topics.isNotEmpty)
            ? widget.completedTopics(
                widget.user!, widget.category.id, widget.topics)
            : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = AppCategoryIcon.colorFor(widget.category.title);
    final darkColor = AppCategoryIcon.darkColorFor(widget.category.title);
    final icon = AppCategoryIcon.iconFor(widget.category.title);
    final total = widget.topics.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.06),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left gradient panel ────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: Container(
                    width: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, darkColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -14,
                          right: -14,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(icon, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Right content ─────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppCategoryIcon.localizedTitle(widget.category.title, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // CTA chip — shown after future resolves
                            if (_progressFuture != null)
                              FutureBuilder<int>(
                                future: _progressFuture,
                                builder: (_, snap) {
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }
                                  final done = snap.data ?? 0;
                                  final isComplete = total > 0 && done >= total;
                                  final hasStarted = done > 0;

                                  if (isComplete) {
                                    return _ActionChip(
                                      label: l10n.commonDone,
                                      icon: Icons.check_rounded,
                                      color: AppColors.green,
                                      isDone: true,
                                    );
                                  }
                                  return _ActionChip(
                                    label: hasStarted ? l10n.homeContinue : l10n.homeStart,
                                    icon: hasStarted
                                        ? Icons.play_arrow_rounded
                                        : Icons.rocket_launch_rounded,
                                    color: color,
                                  );
                                },
                              )
                            else
                              _ActionChip(
                                label: l10n.homeStart,
                                icon: Icons.rocket_launch_rounded,
                                color: color,
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Progress bar + label
                        if (_progressFuture != null)
                          FutureBuilder<int>(
                            future: _progressFuture,
                            builder: (_, snap) {
                              final done = snap.data ?? 0;
                              final progress =
                                  total == 0 ? 0.0 : done / total;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: TweenAnimationBuilder<double>(
                                      key: ValueKey(
                                          '${widget.category.id}_${widget.user?.answeredQuestions.length}'),
                                      tween: Tween(begin: 0, end: progress),
                                      duration:
                                          const Duration(milliseconds: 900),
                                      curve: Curves.easeOut,
                                      builder: (_, v, __) =>
                                          LinearProgressIndicator(
                                        value: v,
                                        minHeight: 7,
                                        backgroundColor: AppColors.background,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                color),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    snap.connectionState ==
                                            ConnectionState.waiting
                                        ? l10n.homeTopicsCount(total)
                                        : l10n.homeTopicsCompleted(snap.data ?? 0, total),
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          Text(
                            l10n.homeTopicsCount(total),
                            style: GoogleFonts.nunito(
                              color: AppColors.textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
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

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDone;
  const _ActionChip(
      {required this.label, required this.icon, required this.color, this.isDone = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.12 : 1.0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDone
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            color: isDone ? color : Colors.white,
            size: 12),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: isDone ? color : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ]),
    );
  }
}

// ─── Practice card ────────────────────────────────────────────────────────────

class _PracticeCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PracticeCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withValues(alpha: 0.12),
                AppColors.orange.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homePracticeWeakSpots,
                      style: GoogleFonts.nunito(
                        color: AppColors.orangeDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.homePracticeSubtitle(count),
                      style: GoogleFonts.nunito(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  l10n.homePracticeButton,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _QuestCardSkeleton extends StatelessWidget {
  const _QuestCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1000.ms);
  }
}
