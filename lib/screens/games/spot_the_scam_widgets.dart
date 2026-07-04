part of 'spot_the_scam_screen.dart';

// Presentational pieces for the scam-detective "Spot the Scam". Library-private
// via `part of`.

// ─── Detective ranks (the persistent mastery track) ───────────────────────────

const _rankNames = [
  'Rookie',
  'Junior Detective',
  'Detective',
  'Senior Detective',
  'Master Detective',
];
const _rankThresholds = [0, 15, 40, 80, 150];

/// Resolves a total-solved count to (rankIndex, thisRankFloor, nextRankGoal).
/// [nextGoal] is null at the top rank.
({int index, int floor, int? nextGoal}) _rankFor(int total) {
  var i = 0;
  for (var t = 0; t < _rankThresholds.length; t++) {
    if (total >= _rankThresholds[t]) i = t;
  }
  final nextGoal =
      i + 1 < _rankThresholds.length ? _rankThresholds[i + 1] : null;
  return (index: i, floor: _rankThresholds[i], nextGoal: nextGoal);
}

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

// ─── Swipe hint ───────────────────────────────────────────────────────────────

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

// ─── Scam / Safe buttons ──────────────────────────────────────────────────────

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

// ─── Results (case accuracy + detective rank progress) ────────────────────────

class _DetectiveResult extends StatefulWidget {
  final int score;
  final int total;
  final int solvedBefore;
  final bool awarding;
  final int awardedCoins;
  final int coinsPossible;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  const _DetectiveResult({
    required this.score,
    required this.total,
    required this.solvedBefore,
    required this.awarding,
    required this.awardedCoins,
    required this.coinsPossible,
    required this.onPlayAgain,
    required this.onDone,
  });

  @override
  State<_DetectiveResult> createState() => _DetectiveResultState();
}

class _DetectiveResultState extends State<_DetectiveResult>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti;

  int get _stars => miniGameStars(widget.score, widget.total);
  int get _newTotal => widget.solvedBefore + widget.score;
  bool get _rankedUp =>
      _rankFor(_newTotal).index > _rankFor(widget.solvedBefore).index;
  bool get _celebrate => _rankedUp || _stars >= 3;

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
        ? 'Coins already earned today — keep sleuthing for fun!'
        : 'Spot more scams to earn coins!';
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
    final rank = _rankFor(_newTotal);
    final rankName = _rankNames[rank.index];
    final headline = switch (_stars) {
      3 => 'Case cracked!',
      2 => 'Sharp work, detective',
      1 => 'Case closed',
      _ => 'Keep investigating',
    };

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final on = i < _stars;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.star_rounded,
                        size: i == 1 ? 54 : 44,
                        color: on ? AppColors.gold : AppColors.border),
                  ).animate(delay: (150 * i).ms).scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 600.ms,
                      );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                headline,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'You judged ${widget.score} of ${widget.total} correctly',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _RankCard(
                rankName: rankName,
                rankIndex: rank.index,
                total: _newTotal,
                floor: rank.floor,
                nextGoal: rank.nextGoal,
                gained: widget.score,
                rankedUp: _rankedUp,
              ),
              const SizedBox(height: 18),
              _coinLine(),
              const SizedBox(height: 22),
              AppButton(
                label: 'New case',
                icon: Icons.refresh_rounded,
                onTap: widget.onPlayAgain,
              ),
              const SizedBox(height: 10),
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

/// The persistent "Detective rank" panel with an animated progress bar toward
/// the next rank — the reason to keep coming back.
class _RankCard extends StatelessWidget {
  final String rankName;
  final int rankIndex;
  final int total;
  final int floor;
  final int? nextGoal;
  final int gained;
  final bool rankedUp;
  const _RankCard({
    required this.rankName,
    required this.rankIndex,
    required this.total,
    required this.floor,
    required this.nextGoal,
    required this.gained,
    required this.rankedUp,
  });

  @override
  Widget build(BuildContext context) {
    final atMax = nextGoal == null;
    final span = atMax ? 1 : (nextGoal! - floor);
    final into = (total - floor).clamp(0, span);
    final ratio = atMax ? 1.0 : into / span;
    final remaining = atMax ? 0 : (nextGoal! - total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withValues(alpha: 0.10),
            AppColors.categoryPrivacy.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_police_rounded,
                    color: AppColors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rankedUp ? 'Ranked up!' : 'Detective rank',
                      style: GoogleFonts.nunito(
                        color: rankedUp ? AppColors.green : AppColors.textLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      rankName,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (gained > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$gained solved',
                    style: GoogleFonts.nunito(
                      color: AppColors.blueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            atMax
                ? 'Top rank reached — $total scams busted!'
                : '$remaining more to reach ${_rankNames[rankIndex + 1]}',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
