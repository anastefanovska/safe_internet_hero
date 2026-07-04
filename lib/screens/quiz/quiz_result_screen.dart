import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/quiz_result_model.dart';
import '../../models/topic_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/questions_service.dart';
import '../../services/shop_service.dart';
import '../../services/sound_service.dart';
import '../../services/streak_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../../core/app_page_route.dart';
import '../auth/splash_screen.dart';
import 'quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultModel result;
  final VoidCallback? onPracticeAgain;

  const QuizResultScreen(
      {super.key, required this.result, this.onPracticeAgain});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _trophyCtrl;
  bool _showConfetti = false;
  int _newStreak = 0;
  int _boostedStars = 0;
  TopicModel? _nextTopic;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(vsync: this);
    _trophyCtrl = AnimationController(vsync: this);

    if (!widget.result.isPractice && !widget.result.isReplay) _loadNextTopic();

    _playResultSounds();

    if (widget.result.starsEarned >= 2 &&
        !widget.result.isPractice &&
        !widget.result.isReplay) {
      _showConfetti = true;
      _confettiCtrl.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showConfetti = false);
        }
      });
    }

    _saveResult();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _trophyCtrl.dispose();
    super.dispose();
  }

  void _playResultSounds() {
    final stars = widget.result.starsEarned;
    if (stars == 0) return;
    SoundService.instance.playComplete(stars);
    // Delay coin jingle to match the rewards text fade-in (~950ms).
    if (!widget.result.isReplay) {
      Future.delayed(const Duration(milliseconds: 950), () {
        if (mounted) SoundService.instance.playCoin();
      });
    }
  }

  Future<void> _loadNextTopic() async {
    if (widget.result.categoryId.isEmpty || widget.result.topicId.isEmpty) return;
    try {
      final topics =
          await TopicsService().getTopicsByCategory(widget.result.categoryId);
      final idx = topics.indexWhere((t) => t.id == widget.result.topicId);
      if (idx >= 0 && idx < topics.length - 1) {
        if (mounted) setState(() => _nextTopic = topics[idx + 1]);
      }
    } catch (_) {}
  }

  Future<void> _saveResult() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    try {
      final svc = QuestionService();
      final streakSvc = StreakService();

      await svc.saveResult(widget.result);

      // Replays earn no rewards and don't update answered question lists.
      if (widget.result.isReplay) {
        if (!mounted) return;
        await auth.refreshUser();
        return;
      }

      if (widget.result.correctlyAnsweredIds.isNotEmpty ||
          widget.result.incorrectlyAnsweredIds.isNotEmpty) {
        await svc.saveAnsweredQuestions(
          userId: user.id,
          correctIds: widget.result.correctlyAnsweredIds,
          incorrectIds: widget.result.incorrectlyAnsweredIds,
        );
      }

      if (widget.result.isPractice) {
        await svc.addRewards(userId: user.id, starsToAdd: 0, coinsToAdd: 3);
      } else {
        int starsToAdd = widget.result.starsEarned;
        if (user.xpBoostActive && starsToAdd > 0) {
          starsToAdd *= 2;
          if (mounted) setState(() => _boostedStars = starsToAdd);
          await ShopService().deactivateXpBoost(user.id);
        }
        await svc.addRewards(
          userId: user.id,
          starsToAdd: starsToAdd,
          coinsToAdd: widget.result.coinsEarned,
        );
        if (widget.result.starsEarned > 0) {
          _newStreak = await streakSvc.recordActivity(user.id);
          if (mounted) setState(() {});
        }
      }

      // Advance today's daily challenge (replays returned above, so they're
      // excluded; practice runs still count toward the practice challenge).
      try {
        await DailyChallengeService()
            .recordQuizCompletion(user.id, widget.result);
      } catch (_) {}

      if (!mounted) return;
      await auth.refreshUser();
    } catch (_) {}
  }

  void _goHome() {
    Navigator.of(context).pop();
  }

  void _practiceAgain() {
    if (widget.onPracticeAgain != null) {
      widget.onPracticeAgain!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final isPractice = result.isPractice;
    final isGuest = context.watch<AuthProvider>().isGuest;

    final isReplay = result.isReplay;

    final Color accent = isPractice
        ? AppColors.orange
        : result.starsEarned == 3
            ? AppColors.green
            : result.starsEarned >= 1
                ? AppColors.blue
                : const Color(0xFF9E9E9E);

    final String titleText = isReplay
        ? (result.starsEarned == 3
            ? 'Perfect Replay!'
            : result.starsEarned >= 1
                ? 'Good Replay!'
                : 'Keep Trying!')
        : isPractice
            ? (result.starsEarned == 3
                ? 'Perfect Practice!'
                : result.starsEarned >= 1
                    ? 'Good Practice!'
                    : 'Keep Practicing!')
            : result.starsEarned == 0
                ? 'Keep Trying!'
                : result.starsEarned == 1
                    ? 'Good Job!'
                    : result.starsEarned == 2
                        ? 'Great Work!'
                        : 'Perfect Score!';

    final String motivationText = isReplay
        ? 'Practice makes perfect!'
        : isPractice
            ? 'Reviewing weak spots makes you stronger.'
            : result.starsEarned >= 2
                ? "You're becoming a true internet safety hero!"
                : 'Every question makes you safer online!';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 52),

                  // ── Hero icon / trophy ──────────────────────────────────
                  if (result.starsEarned == 3 && !isPractice)
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Lottie.asset(
                        'assets/lottie/trophy.json',
                        controller: _trophyCtrl,
                        onLoaded: (comp) {
                          _trophyCtrl.duration = comp.duration;
                          _trophyCtrl.forward();
                        },
                      ),
                    )
                  else
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        isPractice
                            ? Icons.fitness_center_rounded
                            : result.starsEarned >= 2
                                ? Icons.emoji_events_rounded
                                : Icons.sentiment_neutral_rounded,
                        size: 52,
                        color: accent,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                          duration: 700.ms,
                        ),

                  const SizedBox(height: 22),

                  // ── Title ───────────────────────────────────────────────
                  Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 4),

                  Text(
                    isReplay
                        ? 'Replay · ${result.categoryName}'
                        : isPractice
                            ? 'Practice Session'
                            : result.categoryName,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate(delay: 270.ms).fadeIn(duration: 250.ms),

                  const SizedBox(height: 30),

                  // ── Stars ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final earned = i < result.starsEarned;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          Icons.star_rounded,
                          size: earned ? 48 : 40,
                          color: earned
                              ? AppColors.gold
                              : const Color(0xFFE0E0E0),
                        )
                            .animate(
                              delay: Duration(milliseconds: 400 + i * 180),
                            )
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                              duration: 600.ms,
                            ),
                      );
                    }),
                  ),

                  const SizedBox(height: 12),

                  // ── Rewards — single line ────────────────────────────────
                  Text(
                    isReplay
                        ? 'Replay mode · no rewards earned'
                        : isPractice
                            ? '+3 coins earned'
                            : _boostedStars > 0
                                ? '+$_boostedStars XP ⚡  ·  +${result.coinsEarned} coins'
                                : '+${result.starsEarned} XP  ·  +${result.coinsEarned} coins',
                    style: GoogleFonts.nunito(
                      color: isReplay
                          ? AppColors.textSecondary
                          : _boostedStars > 0
                              ? AppColors.gold
                              : accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate(delay: 950.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 32),

                  // ── Stats strip ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 22, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCell(
                          value:
                              '${result.score}/${result.totalQuestions}',
                          label: 'Correct',
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: AppColors.border),
                        _StatCell(
                          value: '${result.percentage}%',
                          label: 'Score',
                          valueColor: accent,
                        ),
                        Container(
                            width: 1,
                            height: 40,
                            color: AppColors.border),
                        _StatCell(
                          value: '${result.pointsEarned}',
                          label: 'Points',
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  // ── Streak pill ──────────────────────────────────────────
                  if (_newStreak > 1 && !isPractice) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                AppColors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            '$_newStreak day streak!',
                            style: GoogleFonts.nunito(
                              color: AppColors.orangeDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 1200.ms).fadeIn(duration: 300.ms),
                  ],

                  const SizedBox(height: 24),

                  // ── Motivational line ────────────────────────────────────
                  Text(
                    motivationText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 36),

                  // ── Actions ──────────────────────────────────────────────
                  if (isGuest)
                    _GuestSaveCTA(
                      starsEarned: result.starsEarned,
                      onCreateAccount: _navigateToSignUp,
                      onSkip: _goHome,
                    )
                        .animate(delay: 1000.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.15, end: 0)
                  else ...[
                    if (_nextTopic != null && !isPractice) ...[
                      _NextTopicCard(
                        topic: _nextTopic!,
                        categoryId: result.categoryId,
                        categoryName: result.categoryName,
                        color: AppCategoryIcon.colorFor(result.categoryName),
                        onStart: () => Navigator.pushReplacement(
                          context,
                          AppPageRoute(
                            builder: (_) => QuizScreen(
                              categoryId: result.categoryId,
                              categoryName: result.categoryName,
                              topicId: _nextTopic!.id,
                              topicName: _nextTopic!.name,
                              color: AppCategoryIcon.colorFor(
                                  result.categoryName),
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 1050.ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 12),
                    ],

                    AppButton(
                      label: isPractice ? 'Done' : 'Continue',
                      variant: AppButtonVariant.primary,
                      onTap: _goHome,
                    )
                        .animate(delay: 1000.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    if (widget.onPracticeAgain != null) ...[
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _practiceAgain,
                        child: Text(
                          'Play Again',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ).animate(delay: 1100.ms).fadeIn(duration: 300.ms),
                    ],
                  ],
                ],
              ),
                ),
              ),
            ),
          ),

          // ── Confetti overlay ──────────────────────────────────────────────
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/lottie/confetti.json',
                  controller: _confettiCtrl,
                  fit: BoxFit.cover,
                  onLoaded: (comp) {
                    _confettiCtrl.duration = comp.duration;
                    _confettiCtrl.forward();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatCell({
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Next topic card ───────────────────────────────────────────────────────────

class _NextTopicCard extends StatelessWidget {
  final TopicModel topic;
  final String categoryId;
  final String categoryName;
  final Color color;
  final VoidCallback onStart;

  const _NextTopicCard({
    required this.topic,
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.quiz_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  topic.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Start',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest save-progress CTA ───────────────────────────────────────────────────

class _GuestSaveCTA extends StatelessWidget {
  final int starsEarned;
  final VoidCallback onCreateAccount;
  final VoidCallback onSkip;

  const _GuestSaveCTA({
    required this.starsEarned,
    required this.onCreateAccount,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Save your progress!',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          starsEarned > 0
              ? 'You earned $starsEarned star${starsEarned > 1 ? 's' : ''} — create a free account to keep them!'
              : 'Create a free account to track your learning and climb the leaderboard.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Create Free Account',
          variant: AppButtonVariant.success,
          icon: Icons.person_add_rounded,
          onTap: onCreateAccount,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onSkip,
          child: Text(
            'Skip for now',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
