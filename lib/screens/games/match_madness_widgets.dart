part of 'match_madness_screen.dart';

// Presentational pieces for [MatchMadnessScreen], split out to keep the screen
// file lean. Library-private via `part of`.

String _fmtTime(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

// ─── Top bar (close, countdown, score) ────────────────────────────────────────

class _MatchHeader extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final int score;
  final bool finished;
  final VoidCallback onClose;
  const _MatchHeader({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.score,
    required this.finished,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ratio =
        totalSeconds == 0 ? 0.0 : (secondsLeft / totalSeconds).clamp(0.0, 1.0);
    // Bar drains and turns red under 10s to add urgency.
    final low = secondsLeft <= 10 && !finished;
    final barColor = low ? AppColors.red : AppColors.categoryPrivacy;
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
          Icon(Icons.timer_rounded, color: barColor, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: ratio, end: ratio),
                duration: const Duration(milliseconds: 300),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: finished ? 0 : v,
                  minHeight: 12,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              _fmtTime(secondsLeft < 0 ? 0 : secondsLeft),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: low ? AppColors.red : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── The two-column board ─────────────────────────────────────────────────────

class _MatchBoard extends StatelessWidget {
  final List<_Tile> terms;
  final List<_Tile> defs;
  final String? selectedKey;
  final Set<String> matched;
  final Set<String> wrong;
  final ValueChanged<_Tile> onTap;
  const _MatchBoard({
    required this.terms,
    required this.defs,
    required this.selectedKey,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  List<Widget> _column(List<_Tile> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 12));
      final t = tiles[i];
      out.add(
        _MatchTile(
          key: ValueKey(t.key),
          text: t.text,
          isTerm: t.isTerm,
          selected: selectedKey == t.key,
          matched: matched.contains(t.key),
          wrong: wrong.contains(t.key),
          onTap: () => onTap(t),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: _column(terms))),
          const SizedBox(width: 12),
          Expanded(child: Column(children: _column(defs))),
        ],
      ),
    );
  }
}

// ─── A single tile (selected highlight, pop-out, shake) ────────────────────────

class _MatchTile extends StatefulWidget {
  final String text;
  final bool isTerm;
  final bool selected;
  final bool matched;
  final bool wrong;
  final VoidCallback onTap;
  const _MatchTile({
    super.key,
    required this.text,
    required this.isTerm,
    required this.selected,
    required this.matched,
    required this.wrong,
    required this.onTap,
  });

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant _MatchTile old) {
    super.didUpdateWidget(old);
    if (widget.wrong && !old.wrong) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    if (widget.matched) {
      bg = AppColors.green.withValues(alpha: 0.15);
      border = AppColors.green;
      fg = AppColors.greenDark;
    } else if (widget.wrong) {
      bg = AppColors.red.withValues(alpha: 0.12);
      border = AppColors.red;
      fg = AppColors.redDark;
    } else if (widget.selected) {
      bg = AppColors.categoryPrivacy;
      border = AppColors.categoryPrivacy;
      fg = Colors.white;
    } else {
      bg = Colors.white;
      border = AppColors.border;
      fg = AppColors.textPrimary;
    }

    final tile = AnimatedScale(
      scale: widget.matched ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: widget.matched ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: fg,
              fontSize: widget.isTerm ? 15 : 13.5,
              fontWeight: widget.isTerm ? FontWeight.w800 : FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ),
    );

    return MouseRegion(
      cursor:
          widget.matched ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.matched ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (_, child) {
            final dx = sin(_shake.value * pi * 4) * 8 * (1 - _shake.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: tile,
        ),
      ),
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _MatchResult extends StatefulWidget {
  final int score;
  final int total;
  final int stars;
  final bool cleared;
  final int elapsed;
  final int awardedCoins;
  final int coinsPossible;
  final bool awarding;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  const _MatchResult({
    required this.score,
    required this.total,
    required this.stars,
    required this.cleared,
    required this.elapsed,
    required this.awardedCoins,
    required this.coinsPossible,
    required this.awarding,
    required this.onPlayAgain,
    required this.onDone,
  });

  @override
  State<_MatchResult> createState() => _MatchResultState();
}

class _MatchResultState extends State<_MatchResult>
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

  String _headline(AppLocalizations l10n) => switch (widget.stars) {
        3 => l10n.matchHeadline3,
        2 => l10n.matchHeadline2,
        1 => l10n.matchHeadline1,
        _ => l10n.matchHeadline0,
      };

  Widget _coinLine() {
    final l10n = AppLocalizations.of(context);
    if (widget.awarding) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (widget.awardedCoins > 0) {
      return _MatchCoinChip(text: l10n.miniGameCoinsEarned(widget.awardedCoins));
    }
    final msg = widget.coinsPossible > 0
        ? l10n.miniGameCoinsAlready
        : l10n.matchCoinsMore;
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
    final l10n = AppLocalizations.of(context);
    final subtitle = widget.cleared
        ? l10n.matchAllPairs(widget.total, _fmtTime(widget.elapsed))
        : l10n.matchSomePairs(widget.score, widget.total);
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
                _headline(l10n),
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
                subtitle,
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
                label: l10n.miniGamePlayAgain,
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.primary,
                onTap: widget.onPlayAgain,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: l10n.commonDone,
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

class _MatchCoinChip extends StatelessWidget {
  final String text;
  const _MatchCoinChip({required this.text});

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
