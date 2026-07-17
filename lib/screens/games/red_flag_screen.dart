import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../data/red_flag_messages.dart';
import '../../models/red_flag_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/mini_game_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_widgets.dart';
import 'mini_game_shared.dart';

/// "Tap the Red Flag" — a fake message is shown; tap the suspicious parts (the
/// dodgy link, the urgency, the request for a password) to find every red flag.
/// A search-and-spot verb rather than a binary choice, but the same light card
/// style. Coins awarded once per day via [MiniGameService].
class RedFlagScreen extends StatefulWidget {
  final String userId;
  const RedFlagScreen({super.key, required this.userId});

  @override
  State<RedFlagScreen> createState() => _RedFlagScreenState();
}

/// One rendered word carrying which part it belongs to (so any word of a flag
/// phrase counts the whole phrase) and whether that part is a red flag.
class _Token {
  final String text;
  final int partIndex;
  final bool isFlag;
  const _Token(this.text, this.partIndex, this.isFlag);
}

class _RedFlagScreenState extends State<RedFlagScreen> {
  static const _gameId = 'red_flag';
  static const _roundSize = 4;
  static const _accent = AppColors.orange;

  final _service = MiniGameService();

  late List<RedFlagMessageModel> _deck;
  int _index = 0;

  final Set<int> _found = {}; // flag partIndices found in the current message
  int _score = 0; // flags found in previous messages
  int _mistakes = 0; // wrong taps across the round
  int _flashPart = -1; // part briefly flashed after a wrong tap

  bool _finished = false;
  bool _awarding = false;
  int _awardedCoins = 0;
  int _coinsPossible = 0;

  @override
  void initState() {
    super.initState();
    _deck = _newDeck();
  }

  List<RedFlagMessageModel> _newDeck() =>
      (List<RedFlagMessageModel>.of(redFlagMessages)..shuffle())
          .take(_roundSize)
          .toList();

  RedFlagMessageModel get _msg => _deck[_index];
  bool get _lastMessage => _index >= _deck.length - 1;
  int get _totalFlags => _deck.fold(0, (s, m) => s + m.flagCount);
  bool get _allFound => _found.length >= _msg.flagCount;

  List<_Token> get _tokens {
    final tokens = <_Token>[];
    for (var i = 0; i < _msg.parts.length; i++) {
      final part = _msg.parts[i];
      for (final w in part.text.trim().split(RegExp(r'\s+'))) {
        if (w.isNotEmpty) tokens.add(_Token(w, i, part.isFlag));
      }
    }
    return tokens;
  }

  void _tapToken(_Token tok) {
    if (_found.contains(tok.partIndex)) return;
    if (tok.isFlag) {
      SoundService.instance.playCorrect();
      HapticService.instance.success();
      setState(() => _found.add(tok.partIndex));
    } else {
      SoundService.instance.playWrong();
      HapticService.instance.error();
      setState(() {
        _mistakes++;
        _flashPart = tok.partIndex;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _flashPart = -1);
      });
    }
  }

  void _next() {
    _score += _found.length;
    if (_lastMessage) {
      _finish();
    } else {
      setState(() {
        _index++;
        _found.clear();
        _flashPart = -1;
      });
    }
  }

  int get _effective => (_score - _mistakes).clamp(0, _totalFlags);

  Future<void> _finish() async {
    final perfect = _score >= _totalFlags && _mistakes == 0;
    final coins = _effective + (perfect ? 5 : 0);
    setState(() {
      _finished = true;
      _awarding = true;
      _coinsPossible = coins;
    });
    SoundService.instance.playComplete(miniGameStars(_effective, _totalFlags));

    final awarded = await _service.awardCoins(
      userId: widget.userId,
      gameId: _gameId,
      coins: coins,
    );
    if (!mounted) return;
    if (awarded > 0) {
      SoundService.instance.playCoin();
      HapticService.instance.reward();
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
    }
    setState(() {
      _awardedCoins = awarded;
      _awarding = false;
    });
  }

  void _playAgain() {
    setState(() {
      _deck = _newDeck();
      _index = 0;
      _found.clear();
      _score = 0;
      _mistakes = 0;
      _flashPart = -1;
      _finished = false;
      _awardedCoins = 0;
      _coinsPossible = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = miniGameStars(_effective, _totalFlags);
    return Scaffold(
      backgroundColor: miniGameBackdrop(context),
      body: SafeArea(
        child: MiniGameShell(
          child: Column(
          children: [
            MiniGameTopBar(
              onClose: () => Navigator.of(context).maybePop(),
              progress: _finished ? 1 : _index / _deck.length,
              score: _score + _found.length,
              accent: _accent,
              scoreIcon: Icons.flag_rounded,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 740),
                  child: _finished
                      ? MiniGameResult(
                          stars: stars,
                          headline: switch (stars) {
                            3 => AppLocalizations.of(context).redFlagHeadline3,
                            2 => AppLocalizations.of(context).redFlagHeadline2,
                            1 => AppLocalizations.of(context).redFlagHeadline1,
                            _ => AppLocalizations.of(context).redFlagHeadline0,
                          },
                          subtitle:
                              AppLocalizations.of(context).redFlagCaught(_score, _totalFlags),
                          awarding: _awarding,
                          awardedCoins: _awardedCoins,
                          coinsPossible: _coinsPossible,
                          onPlayAgain: _playAgain,
                          onDone: () => Navigator.of(context).maybePop(),
                        )
                      : _playArea(),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _playArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, color: _accent, size: 18),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).redFlagTapSuspicious,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${_found.length} / ${_msg.flagCount}',
                style: GoogleFonts.nunito(
                  color: _allFound ? AppColors.green : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _messageCard(),
          const SizedBox(height: 14),
          // Reasons appear as each flag is found — feedback that teaches.
          ..._found.map((i) => _ReasonRow(reason: _msg.parts[i].reason)),
          if (_found.isNotEmpty) const SizedBox(height: 6),
          AppButton(
            label: _lastMessage
                ? AppLocalizations.of(context).redFlagSeeResults
                : (_allFound ? AppLocalizations.of(context).scamNextMessage : AppLocalizations.of(context).redFlagSkip),
            variant:
                _allFound ? AppButtonVariant.success : AppButtonVariant.secondary,
            icon: _allFound ? Icons.arrow_forward_rounded : null,
            onTap: _next,
          ),
        ],
      ),
    );
  }

  Widget _messageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.textSecondary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _msg.sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _msg.context,
                      style: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Wrap(
              spacing: 5,
              runSpacing: 7,
              children: _tokens.map(_wordChip).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordChip(_Token tok) {
    final found = _found.contains(tok.partIndex);
    final flashing = _flashPart == tok.partIndex;
    Color bg = Colors.transparent;
    Color fg = AppColors.textPrimary;
    if (found) {
      bg = AppColors.red;
      fg = Colors.white;
    } else if (flashing) {
      bg = AppColors.red.withValues(alpha: 0.15);
      fg = AppColors.red;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _tapToken(tok),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            tok.text,
            style: GoogleFonts.nunito(
              color: fg,
              fontSize: 16,
              fontWeight: found ? FontWeight.w800 : FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final String reason;
  const _ReasonRow({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
