part of 'spot_the_scam_screen.dart';

// Presentational pieces for [SpotTheScamScreen], split out to keep the screen
// file lean. Library-private via `part of` so nothing here leaks out.

// ─── Channel presentation helpers ─────────────────────────────────────────────

IconData _channelIcon(ScamChannel c) => switch (c) {
      ScamChannel.sms => Icons.sms_rounded,
      ScamChannel.email => Icons.alternate_email_rounded,
      ScamChannel.dm => Icons.chat_bubble_rounded,
    };

String _channelLabel(ScamChannel c) => switch (c) {
      ScamChannel.sms => 'Text message',
      ScamChannel.email => 'Email',
      ScamChannel.dm => 'Direct message',
    };

// ─── Top bar (close, progress, score) ─────────────────────────────────────────

class _GameHeader extends StatelessWidget {
  final int index;
  final int total;
  final int score;
  final bool finished;
  final VoidCallback onClose;
  const _GameHeader({
    required this.index,
    required this.total,
    required this.score,
    required this.finished,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (finished ? 1.0 : index / total);
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
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.categoryPrivacy),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.check_circle_rounded,
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

// ─── The message card (with drag tint + stamp) ────────────────────────────────

class _ScamCardView extends StatelessWidget {
  final ScamCardModel card;
  final double dragX;
  final bool dragging;
  final bool answered;
  final bool correct;
  final double threshold;
  const _ScamCardView({
    super.key,
    required this.card,
    required this.dragX,
    required this.dragging,
    required this.answered,
    required this.correct,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    // While dragging: tint toward the pending choice (left=scam=red,
    // right=safe=green). After answering: outline by correctness, stamp truth.
    final t = (dragX.abs() / threshold).clamp(0.0, 1.0);
    final draggingScam = dragX < 0;
    final tintColor = draggingScam ? AppColors.red : AppColors.green;

    Color border = AppColors.border;
    if (answered) {
      border = correct ? AppColors.green : AppColors.red;
    } else if (dragX.abs() > 4) {
      border = tintColor.withValues(alpha: 0.3 + 0.7 * t);
    }

    return AnimatedContainer(
      duration: dragging ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(dragX, 0, 0)
        ..rotateZ(dragX * 0.0009),
      transformAlignment: Alignment.center,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(card: card),
                const SizedBox(height: 14),
                if (card.channel == ScamChannel.email &&
                    (card.subject?.isNotEmpty ?? false)) ...[
                  Text(
                    card.subject!,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    card.content,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Drag / answered stamp.
          if (answered || dragX.abs() > threshold * 0.35)
            Positioned(
              top: 18,
              right: 18,
              child: _Stamp(
                scam: answered ? card.isScam : draggingScam,
                opacity: answered ? 1.0 : t,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final ScamCardModel card;
  const _CardHeader({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.categoryPrivacy.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_channelIcon(card.channel),
              color: AppColors.categoryPrivacy, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.sender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _channelLabel(card.channel),
                style: GoogleFonts.nunito(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  final bool scam;
  final double opacity;
  const _Stamp({required this.scam, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final color = scam ? AppColors.red : AppColors.green;
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: scam ? 0.25 : -0.25,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 3),
          ),
          child: Text(
            scam ? 'SCAM' : 'SAFE',
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Swipe hint (shown before answering) ──────────────────────────────────────

class _SwipeHint extends StatelessWidget {
  const _SwipeHint();

  @override
  Widget build(BuildContext context) {
    Widget side(IconData icon, String label, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        side(Icons.arrow_back_rounded, 'Swipe left · Scam', AppColors.red),
        side(Icons.arrow_forward_rounded, 'Safe · Swipe right', AppColors.green),
      ],
    );
  }
}

// ─── Reveal panel (after answering) ───────────────────────────────────────────

class _RevealPanel extends StatelessWidget {
  final ScamCardModel card;
  final bool correct;
  final bool lastCard;
  final VoidCallback onContinue;
  const _RevealPanel({
    required this.card,
    required this.correct,
    required this.lastCard,
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
              Text(
                card.isScam ? 'This was a scam' : 'This was safe',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.explanation,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: lastCard ? 'See results' : 'Continue',
            variant:
                correct ? AppButtonVariant.success : AppButtonVariant.primary,
            onTap: onContinue,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.12, end: 0);
  }
}

// ─── Scam / Safe buttons (accessible alternative to swiping) ───────────────────

class _ChoiceButtons extends StatelessWidget {
  final bool enabled;
  final VoidCallback onScam;
  final VoidCallback onSafe;
  const _ChoiceButtons({
    required this.enabled,
    required this.onScam,
    required this.onSafe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Scam',
            icon: Icons.report_rounded,
            variant: AppButtonVariant.danger,
            onTap: enabled ? onScam : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AppButton(
            label: 'Safe',
            icon: Icons.verified_user_rounded,
            variant: AppButtonVariant.success,
            onTap: enabled ? onSafe : null,
          ),
        ),
      ],
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  final int score;
  final int total;
  final int stars;
  final int awardedCoins;
  final int coinsPossible;
  final bool awarding;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  const _ResultView({
    required this.score,
    required this.total,
    required this.stars,
    required this.awardedCoins,
    required this.coinsPossible,
    required this.awarding,
    required this.onPlayAgain,
    required this.onDone,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView>
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

  String get _headline => switch (widget.stars) {
        3 => 'Scam-spotting hero!',
        2 => 'Great instincts!',
        1 => 'Nice try — keep practising',
        _ => 'Keep practising!',
      };

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
        : 'Answer more correctly to earn coins!';
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
                _headline,
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
                'You spotted ${widget.score} of ${widget.total} correctly',
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
                variant: AppButtonVariant.primary,
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
