import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/daily_challenge_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/questions_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';
import '../quiz/quiz_screen.dart';
import 'match_madness_screen.dart';
import 'spot_the_scam_screen.dart';

/// The "Games" tab: two sub-sections — Daily Challenges and Mini Games —
/// under a shared Duolingo-style header (mirrors the Quests screen design).
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _tab = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the reset countdown once a minute.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _resetsIn() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final d = midnight.difference(now);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m left' : '${m}m left';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final guest = auth.isGuest || user == null;
    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Mobile streak/stats bar — shown for everyone (guests see zeros),
          // matching Shop/Learn. Desktop reads stats from the side panel and
          // AppTopBar self-hides there anyway.
          if (!desktop)
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: AppTopBar(
                  stars: user?.totalStars ?? 0,
                  streak: user?.currentStreak ?? 0,
                  coins: user?.coins ?? 0,
                ),
              ),
            ),
          if (!desktop) Container(height: 1, color: AppColors.border),
          // White header — shown for everyone, matching the other tabs. Guests
          // get the same framing without the segmented tabs (like other tabs
          // keep their header for guests), above the blurred preview + CTA.
          _GamesHeader(
            activeTab: _tab,
            showTabs: !guest,
            onTab: (i) => setState(() => _tab = i),
            // The top bar already consumed the status-bar inset on mobile;
            // don't let the header's SafeArea add it a second time.
            applyTopInset: desktop,
          ),
          Expanded(
            // Guests see a blurred preview + sign-up CTA (like the other tabs).
            child: guest
                // The mobile top bar already consumed the status-bar inset;
                // only re-apply it on desktop (no top bar there).
                ? SafeArea(
                    top: desktop,
                    bottom: false,
                    child: const _GamesGuestState(),
                  )
                : SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: kContentMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: _tab == 0
                              ? _DailyChallengesTab(
                                  user: user,
                                  resetsIn: _resetsIn(),
                                )
                              : _MiniGamesTab(user: user),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Header (gradient + segmented tabs + welcome banner) ──────────────────────

class _GamesHeader extends StatelessWidget {
  final int activeTab;
  final bool showTabs;
  final ValueChanged<int> onTab;
  // Whether this header should pad for the status-bar inset. False when a
  // streak bar above it already consumed that inset (mobile).
  final bool applyTopInset;
  const _GamesHeader({
    required this.activeTab,
    required this.showTabs,
    required this.onTab,
    this.applyTopInset = true,
  });

  @override
  Widget build(BuildContext context) {
    // Guests (no tabs) always see the challenges framing.
    final onChallenges = !showTabs || activeTab == 0;
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        top: applyTopInset,
        bottom: false,
        child: Column(
          // Stretch so the title/subtitle block fills the width and left-aligns
          // (otherwise it sizes to the text and gets centered).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title + subtitle block, matching TabHeader on the other tabs.
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, showTabs ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    onChallenges ? 'Daily Challenges' : 'Mini Games',
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    onChallenges
                        ? 'Complete challenges to earn coins'
                        : 'Quick games to sharpen your safety skills',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Segmented tabs (logged-in only)
            if (showTabs)
              Row(
                children: [
                  _HeaderTab(
                    label: 'Challenges',
                    selected: activeTab == 0,
                    onTap: () => onTab(0),
                  ),
                  _HeaderTab(
                    label: 'Mini Games',
                    selected: activeTab == 1,
                    onTap: () => onTab(1),
                  ),
                ],
              ),
            Container(height: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _HeaderTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      selected ? AppColors.categoryPrivacy : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: selected
                    ? AppColors.categoryPrivacy
                    : AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Daily challenges tab ─────────────────────────────────────────────────────

class _DailyChallengesTab extends StatelessWidget {
  final UserModel user;
  final String resetsIn;
  const _DailyChallengesTab({
    required this.user,
    required this.resetsIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with reset countdown.
        Row(
          children: [
            Text(
              'Today\'s Challenge',
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            const Icon(Icons.schedule_rounded,
                color: AppColors.gold, size: 16),
            const SizedBox(width: 4),
            Text(
              resetsIn,
              style: GoogleFonts.nunito(
                color: AppColors.goldDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        DailyChallengePanel(userId: user.id)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.06, end: 0),

        const SizedBox(height: 14),

        // Locked "more coming" card, mirroring the reference design.
        const _LockedCard(
          title: 'More challenges unlock soon',
          subtitle: 'Keep playing to reveal weekly goals.',
        ),
      ],
    );
  }
}

// ─── Mini games tab ───────────────────────────────────────────────────────────

class _MiniGamesTab extends StatelessWidget {
  final UserModel user;
  const _MiniGamesTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mini Games',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        _PlayableGameCard(
          title: 'Spot the Scam',
          subtitle: 'Swipe real vs. fake messages to earn coins.',
          icon: Icons.swipe_rounded,
          accent: AppColors.blue,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => SpotTheScamScreen(userId: user.id),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
        const SizedBox(height: 12),
        _PlayableGameCard(
          title: 'Match Madness',
          subtitle: 'Match safety terms to their meaning against the clock.',
          icon: Icons.extension_rounded,
          accent: AppColors.green,
          onTap: () => Navigator.push(
            context,
            AppPageRoute(
              builder: (_) => MatchMadnessScreen(userId: user.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _LockedCard(
          title: 'Password Builder',
          subtitle: 'Build strong passwords against the clock.',
          icon: Icons.lock_rounded,
          accent: AppColors.green,
        ),
        const SizedBox(height: 12),
        const _LockedCard(
          title: 'More games on the way',
          subtitle: 'New tactile challenges are in the works.',
        ),
      ],
    );
  }
}

// ─── Playable mini-game card ──────────────────────────────────────────────────

/// A launchable mini-game entry: same footprint as [_LockedCard] but tappable,
/// with a "Play" chip instead of the SOON badge.
class _PlayableGameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _PlayableGameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 16),
                    Text(
                      'Play',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Locked / coming-soon card ────────────────────────────────────────────────

class _LockedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Color? accent;
  const _LockedCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final muted = accent == null;
    final c = accent ?? AppColors.textLight;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: muted ? AppColors.background : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon ?? Icons.lock_rounded, color: c, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'SOON',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest state (blurred preview + sign-up CTA) ──────────────────────────────

class _GamesGuestState extends StatelessWidget {
  const _GamesGuestState();

  @override
  Widget build(BuildContext context) {
    const preview = [
      _PreviewChallengeCard(),
      SizedBox(height: 14),
      _LockedCard(
        title: 'More challenges unlock soon',
        subtitle: 'Keep playing to reveal weekly goals.',
      ),
    ];

    const title = 'Unlock daily challenges';
    const subtitle =
        'Create a free account to earn coins\nfrom daily challenges and mini games.';

    // Same structure as the Shop / Leaderboard guest states: an illustration on
    // top, a faded + blurred preview of the real content, then the CTA.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
          child: SvgPicture.asset('assets/images/games_guest.svg', height: 110),
        ),
        Expanded(
          child: Stack(
            children: [
              // Blurred, non-interactive preview of the real content.
              Positioned.fill(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter:
                        ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: preview,
                      ),
                    ),
                  ),
                ),
              ),

              // Fade to background so the CTA reads clearly.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.28, 0.62, 1.0],
                      colors: [
                        AppColors.background.withValues(alpha: 0.0),
                        AppColors.background.withValues(alpha: 0.5),
                        AppColors.background.withValues(alpha: 0.92),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),

              // CTA overlay.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GuestCTAButton(
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          AppPageRoute(builder: (_) => const LandingScreen()),
                          (route) => false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Static, non-interactive mock of the daily-challenge card, used behind the
/// guest blur so the preview looks like the real thing.
class _PreviewChallengeCard extends StatelessWidget {
  const _PreviewChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.goldDark, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer 5 questions',
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const LinearProgressIndicator(
                              value: 0.4,
                              minHeight: 8,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.gold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2 / 5',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _RewardChip(coins: 10),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Start challenge',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interactive daily-challenge panel ────────────────────────────────────────

/// The embeddable card for today's challenge: goal, progress, reward, and the
/// action to start it (launches a quiz of random questions) or claim it.
class DailyChallengePanel extends StatefulWidget {
  final String userId;
  const DailyChallengePanel({super.key, required this.userId});

  @override
  State<DailyChallengePanel> createState() => _DailyChallengePanelState();
}

class _DailyChallengePanelState extends State<DailyChallengePanel>
    with SingleTickerProviderStateMixin {
  final _service = DailyChallengeService();
  final _questionService = QuestionService();
  late final AnimationController _burstCtrl;
  bool _showBurst = false;
  bool _claiming = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showBurst = false);
        }
      });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  int _questionCount(DailyChallengeTemplate t) {
    switch (t.type) {
      case DailyChallengeType.answerQuestions:
      case DailyChallengeType.answerInCategory:
        return t.target;
      case DailyChallengeType.threeStarQuiz:
        return 5;
      case DailyChallengeType.practiceWeakSpots:
        return 10;
    }
  }

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final ok = await _service.claim(widget.userId);
    if (!mounted) return;
    if (ok) {
      SoundService.instance.playCoin();
      setState(() => _showBurst = true);
      await context.read<AuthProvider>().refreshUser();
    }
    if (mounted) setState(() => _claiming = false);
  }

  /// Builds the question set and drops the user straight into a quiz — no topic
  /// picking. Challenge quizzes are practice-tagged (no farmable stars) but
  /// carry the real category so category challenges still count.
  Future<void> _start(DailyChallengeTemplate template, UserModel? user) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final count = _questionCount(template);
      List<String> ids;
      String categoryId = 'practice';
      String categoryName = 'Daily Challenge';
      Color color = AppColors.gold;

      switch (template.type) {
        case DailyChallengeType.practiceWeakSpots:
          final weak = user?.incorrectlyAnsweredIds ?? const [];
          if (weak.isEmpty) {
            _snack('Play a few quizzes first to build weak spots!');
            return;
          }
          ids = weak.take(count).toList();
          categoryName = 'Weak Spots';
          color = AppColors.orange;
          break;
        case DailyChallengeType.answerInCategory:
          final qs = await _questionService.getRandomApprovedQuestions(
              categoryId: template.categoryId, limit: count);
          ids = qs.map((q) => q.id).toList();
          categoryId = template.categoryId!;
          categoryName = template.categoryName ?? 'Daily Challenge';
          color = AppCategoryIcon.colorFor(categoryName);
          break;
        case DailyChallengeType.answerQuestions:
        case DailyChallengeType.threeStarQuiz:
          final qs =
              await _questionService.getRandomApprovedQuestions(limit: count);
          ids = qs.map((q) => q.id).toList();
          break;
      }

      if (!mounted) return;
      if (ids.isEmpty) {
        _snack('No questions available yet — check back soon!');
        return;
      }

      await Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => QuizScreen(
            categoryId: categoryId,
            categoryName: categoryName,
            topicId: '',
            topicName: template.title,
            color: color,
            specificIds: ids,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return StreamBuilder<DailyChallengeModel>(
      stream: _service.watchToday(widget.userId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final model = snap.data!;
        final template = _service.templateById(model.challengeId);
        final target = template.target;
        final progress = model.progress.clamp(0, target);
        final complete = progress >= target;
        final claimed = model.claimed;
        final ratio = target == 0 ? 0.0 : progress / target;

        // The whole card is the tap target: it starts the challenge, or claims
        // it once complete. Nothing to tap once claimed.
        final busy = _starting || _claiming;
        final VoidCallback? onTap = (claimed || busy)
            ? null
            : complete
                ? _claim
                : () => _start(template, user);

        Widget trailing;
        if (busy) {
          trailing = const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );
        } else if (claimed) {
          trailing = const Icon(Icons.check_circle_rounded,
              color: AppColors.green, size: 28);
        } else if (complete) {
          trailing = const _ClaimPill();
        } else {
          trailing = _RewardChip(coins: template.coinReward);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            MouseRegion(
              cursor: onTap == null
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: (claimed ? AppColors.green : AppColors.gold)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          claimed
                              ? Icons.verified_rounded
                              : Icons.bolt_rounded,
                          color:
                              claimed ? AppColors.green : AppColors.goldDark,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: GoogleFonts.nunito(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: ratio),
                                      duration:
                                          const Duration(milliseconds: 700),
                                      curve: Curves.easeOut,
                                      builder: (_, v, __) =>
                                          LinearProgressIndicator(
                                        value: v,
                                        minHeight: 8,
                                        backgroundColor: AppColors.background,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                AppColors.gold),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$progress / $target',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      trailing,
                    ],
                  ),
                ),
              ),
            ),

            if (_showBurst)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    'assets/lottie/stars.json',
                    fit: BoxFit.cover,
                    controller: _burstCtrl,
                    onLoaded: (comp) {
                      _burstCtrl
                        ..duration = comp.duration
                        ..forward(from: 0);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RewardChip extends StatelessWidget {
  final int coins;
  const _RewardChip({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppColors.goldDark, size: 14),
          const SizedBox(width: 4),
          Text(
            '+$coins',
            style: GoogleFonts.nunito(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Green "Claim" pill shown on the card once the challenge is complete; tapping
/// the card claims the reward.
class _ClaimPill extends StatelessWidget {
  const _ClaimPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            'Claim',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
