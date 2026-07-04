import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/scam_cards.dart';
import '../../models/scam_card_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/mini_game_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_widgets.dart';

part 'spot_the_scam_widgets.dart';

/// "Spot the Scam" — a swipe deck mini-game. One message at a time: swipe LEFT
/// (or tap the red button) to call it a **Scam**, swipe RIGHT (or tap green) to
/// call it **Safe**. Each answer reveals a short explanation; finishing a round
/// awards coins once per day via [MiniGameService].
class SpotTheScamScreen extends StatefulWidget {
  final String userId;
  const SpotTheScamScreen({super.key, required this.userId});

  @override
  State<SpotTheScamScreen> createState() => _SpotTheScamScreenState();
}

class _SpotTheScamScreenState extends State<SpotTheScamScreen> {
  static const _gameId = 'spot_the_scam';
  static const _roundSize = 8;
  static const _perfectBonus = 5;
  static const _swipeThreshold = 90.0;

  final _service = MiniGameService();

  late List<ScamCardModel> _deck;
  int _index = 0;
  int _score = 0;

  // Per-card reveal state.
  bool _answered = false;
  bool _choseScam = false;
  bool _dragging = false;
  double _dragX = 0;

  // End state.
  bool _finished = false;
  bool _awarding = false;
  int _awardedCoins = 0;
  int _coinsPossible = 0;

  @override
  void initState() {
    super.initState();
    _deck = _newDeck();
  }

  List<ScamCardModel> _newDeck() =>
      (List<ScamCardModel>.of(scamCards)..shuffle()).take(_roundSize).toList();

  ScamCardModel get _card => _deck[_index];
  bool get _lastCard => _index >= _deck.length - 1;

  int get _stars {
    if (_deck.isEmpty) return 0;
    final r = _score / _deck.length;
    if (r >= 1.0) return 3;
    if (r >= 0.75) return 2;
    if (r >= 0.5) return 1;
    return 0;
  }

  void _answer(bool choseScam) {
    if (_answered) return;
    final correct = choseScam == _card.isScam;
    if (correct) {
      _score++;
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }
    setState(() {
      _answered = true;
      _choseScam = choseScam;
      _dragging = false;
      _dragX = 0;
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (_dragX <= -_swipeThreshold) {
      _answer(true); // left → scam
    } else if (_dragX >= _swipeThreshold) {
      _answer(false); // right → safe
    } else {
      setState(() {
        _dragging = false;
        _dragX = 0;
      });
    }
  }

  void _next() {
    if (_lastCard) {
      _finish();
    } else {
      setState(() {
        _index++;
        _answered = false;
        _dragX = 0;
      });
    }
  }

  Future<void> _finish() async {
    final perfect = _score == _deck.length;
    final coins = _score + (perfect ? _perfectBonus : 0);
    setState(() {
      _finished = true;
      _awarding = true;
      _coinsPossible = coins;
    });
    SoundService.instance.playComplete(_stars);

    final awarded = await _service.awardCoins(
      userId: widget.userId,
      gameId: _gameId,
      coins: coins,
    );
    if (!mounted) return;
    if (awarded > 0) {
      SoundService.instance.playCoin();
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
      _score = 0;
      _answered = false;
      _dragX = 0;
      _finished = false;
      _awardedCoins = 0;
      _coinsPossible = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _GameHeader(
              index: _index,
              total: _deck.length,
              score: _score,
              finished: _finished,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _finished
                      ? _ResultView(
                          score: _score,
                          total: _deck.length,
                          stars: _stars,
                          awardedCoins: _awardedCoins,
                          coinsPossible: _coinsPossible,
                          awarding: _awarding,
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
    );
  }

  Widget _playArea() {
    final correct = _choseScam == _card.isScam;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onPanStart:
                    _answered ? null : (_) => setState(() => _dragging = true),
                onPanUpdate: _answered
                    ? null
                    : (d) => setState(() => _dragX += d.delta.dx),
                onPanEnd: _answered ? null : _onPanEnd,
                child: _ScamCardView(
                  key: ValueKey(_card.id),
                  card: _card,
                  dragX: _dragX,
                  dragging: _dragging,
                  answered: _answered,
                  correct: correct,
                  threshold: _swipeThreshold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _answered
              ? _RevealPanel(
                  card: _card,
                  correct: correct,
                  lastCard: _lastCard,
                  onContinue: _next,
                )
              : const _SwipeHint(),
          const SizedBox(height: 12),
          _ChoiceButtons(
            enabled: !_answered,
            onScam: () => _answer(true),
            onSafe: () => _answer(false),
          ),
        ],
      ),
    );
  }
}
