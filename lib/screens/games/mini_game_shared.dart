import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

// Shared building blocks for the light, card-based mini-games (Safe to Share?,
// Safety Sort, Tap the Red Flag, Password Power). Extracted so every game gets
// the same header and results screen and each game file stays small — the
// long-standing "duplicated result card" debt, paid once here.

/// 1–3 stars from a correct/total ratio (the scale all the judgement games use).
int miniGameStars(int correct, int total) {
  if (total == 0) return 0;
  final r = correct / total;
  if (r >= 1.0) return 3;
  if (r >= 0.75) return 2;
  if (r >= 0.5) return 1;
  return 0;
}

/// Scaffold background for a mini-game — the normal app surface on every size
/// (kept as a helper so the games read consistently and it's easy to tweak).
Color miniGameBackdrop(BuildContext context) => AppColors.background;

/// Keeps a mini-game from sprawling across a wide desktop window. On desktop the
/// whole game (top bar + content) is pinned top-centre in a fixed-width column
/// that fills the full height — exactly how the quiz screen behaves — so it reads
/// as one clean page, not a floating box. On mobile it's returned untouched.
/// [maxWidth] matches the quiz screen's roomy centred column (740).
class MiniGameShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const MiniGameShell({super.key, required this.child, this.maxWidth = 740});

  @override
  Widget build(BuildContext context) {
    if (!isDesktop(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: maxWidth, child: child),
    );
  }
}

// ─── Top bar (close · progress · score) ───────────────────────────────────────

class MiniGameTopBar extends StatelessWidget {
  final VoidCallback onClose;
  final double progress; // 0..1
  final int score;
  final Color accent;
  final IconData scoreIcon;
  const MiniGameTopBar({
    super.key,
    required this.onClose,
    required this.progress,
    required this.score,
    this.accent = AppColors.categoryPrivacy,
    this.scoreIcon = Icons.check_circle_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded,
                    color: AppColors.textLight, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(scoreIcon,
              color: score > 0 ? AppColors.green : AppColors.textLight,
              size: 20),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Results (stars · headline · coins · confetti · actions) ───────────────────

class MiniGameResult extends StatefulWidget {
  final int stars;
  final String headline;
  final String subtitle;
  final bool awarding;
  final int awardedCoins;
  final int coinsPossible;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  const MiniGameResult({
    super.key,
    required this.stars,
    required this.headline,
    required this.subtitle,
    required this.awarding,
    required this.awardedCoins,
    required this.coinsPossible,
    required this.onPlayAgain,
    required this.onDone,
  });

  @override
  State<MiniGameResult> createState() => _MiniGameResultState();
}

class _MiniGameResultState extends State<MiniGameResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti;

  bool get _celebrate => widget.stars >= 2;

  @override
  void initState() {
    super.initState();
    _confetti = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Widget _coinLine() {
    if (widget.awarding) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (widget.awardedCoins > 0) {
      return _CoinChip(text: '+${widget.awardedCoins} coins earned');
    }
    final msg = widget.coinsPossible > 0
        ? 'Coins already earned today — play on for fun!'
        : 'Do better to earn coins!';
    return Text(
      msg,
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final on = i < widget.stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.star_rounded,
                      size: i == 1 ? 56 : 46,
                      color: on ? AppColors.gold : AppColors.border,
                    ),
                  ).animate(delay: (150 * i).ms).scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 600.ms,
                      );
                }),
              ),
              const SizedBox(height: 18),
              Text(
                widget.headline,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _coinLine(),
              const SizedBox(height: 28),
              AppButton(
                label: 'Play again',
                icon: Icons.refresh_rounded,
                onTap: widget.onPlayAgain,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Done',
                variant: AppButtonVariant.secondary,
                onTap: widget.onDone,
              ),
            ],
          ),
        ),
        if (_celebrate)
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                fit: BoxFit.cover,
                controller: _confetti,
                onLoaded: (comp) {
                  _confetti
                    ..duration = comp.duration
                    ..forward(from: 0);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _CoinChip extends StatelessWidget {
  final String text;
  const _CoinChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              color: AppColors.goldDark, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: AppColors.goldDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}

/// A small reveal panel used by the deck-style games (Safe to Share?) after a
/// choice — mirrors Spot the Scam's explanation card.
class MiniGameReveal extends StatelessWidget {
  final bool correct;
  final String truthLabel;
  final String explanation;
  final String buttonLabel;
  final VoidCallback onContinue;
  const MiniGameReveal({
    super.key,
    required this.correct,
    required this.truthLabel,
    required this.explanation,
    required this.buttonLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.green : AppColors.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct!' : 'Not quite',
                style: GoogleFonts.nunito(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  truthLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: buttonLabel,
            variant: correct ? AppButtonVariant.success : AppButtonVariant.primary,
            onTap: onContinue,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.12, end: 0);
  }
}
