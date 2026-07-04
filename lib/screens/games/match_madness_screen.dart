import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/term_pairs.dart';
import '../../models/term_pair_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/mini_game_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_widgets.dart';

part 'match_madness_widgets.dart';

/// "Match Madness" — a Duolingo-style matching mini-game. Two shuffled columns
/// (terms | definitions) of tappable tiles; tap one from each column to pair
/// them. Correct pairs pop out, wrong pairs shake red. Clear all pairs before
/// the round timer runs out. Finishing awards coins once per day via
/// [MiniGameService].
class MatchMadnessScreen extends StatefulWidget {
  final String userId;
  const MatchMadnessScreen({super.key, required this.userId});

  @override
  State<MatchMadnessScreen> createState() => _MatchMadnessScreenState();
}

/// A single tappable tile in one of the two columns.
class _Tile {
  final String pairId;
  final bool isTerm;
  final String text;
  const _Tile({required this.pairId, required this.isTerm, required this.text});

  /// Unique across both columns — keys the widget and the selection sets.
  String get key => '${isTerm ? 't' : 'd'}_$pairId';
}

class _MatchMadnessScreenState extends State<MatchMadnessScreen> {
  static const _gameId = 'match_madness';
  static const _setSize = 6;
  static const _roundSeconds = 75;
  static const _perfectBonus = 5;

  final _service = MiniGameService();

  late List<TermPairModel> _pool;
  int _cursor = 0;
  late List<_Tile> _terms;
  late List<_Tile> _defs;

  _Tile? _selected;
  final Set<String> _matched = {}; // keys mid pop-out
  final Set<String> _wrong = {}; // keys mid shake

  int _score = 0;
  int _secondsLeft = _roundSeconds;
  Timer? _timer;

  // End state.
  bool _finished = false;
  bool _cleared = false;
  bool _awarding = false;
  int _elapsed = 0;
  int _awardedCoins = 0;
  int _coinsPossible = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _pool = List<TermPairModel>.of(termPairs)..shuffle();
    _cursor = 0;
    _score = 0;
    _secondsLeft = _roundSeconds;
    _finished = false;
    _cleared = false;
    _awardedCoins = 0;
    _coinsPossible = 0;
    _selected = null;
    _matched.clear();
    _wrong.clear();
    _loadSet();
    _startTimer();
  }

  /// Loads the next [_setSize] pairs into two independently-shuffled columns.
  void _loadSet() {
    final end = (_cursor + _setSize).clamp(0, _pool.length);
    final slice = _pool.sublist(_cursor, end);
    _cursor = end;
    _terms = slice
        .map((p) => _Tile(pairId: p.id, isTerm: true, text: p.term))
        .toList()
      ..shuffle();
    _defs = slice
        .map((p) => _Tile(pairId: p.id, isTerm: false, text: p.definition))
        .toList()
      ..shuffle();
    _selected = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finish(cleared: false);
    });
  }

  int get _stars {
    if (_pool.isEmpty) return 0;
    final r = _score / _pool.length;
    if (r >= 1.0) return 3;
    if (r >= 0.75) return 2;
    if (r >= 0.5) return 1;
    return 0;
  }

  void _onTap(_Tile t) {
    if (_finished || _matched.contains(t.key)) return;
    final sel = _selected;
    if (sel == null) {
      setState(() => _selected = t);
      return;
    }
    if (sel.key == t.key) {
      setState(() => _selected = null); // deselect
      return;
    }
    if (sel.isTerm == t.isTerm) {
      setState(() => _selected = t); // same column → move selection
      return;
    }
    // One from each column — evaluate the pair.
    if (sel.pairId == t.pairId) {
      _onMatch(sel, t);
    } else {
      _onWrong(sel, t);
    }
  }

  void _onMatch(_Tile a, _Tile b) {
    SoundService.instance.playCorrect();
    setState(() {
      _matched.addAll({a.key, b.key});
      _selected = null;
      _score++;
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() {
        _terms.removeWhere((t) => _matched.contains(t.key));
        _defs.removeWhere((t) => _matched.contains(t.key));
        _matched.removeAll({a.key, b.key});
      });
      _maybeAdvance();
    });
  }

  void _onWrong(_Tile a, _Tile b) {
    SoundService.instance.playWrong();
    setState(() {
      _wrong.addAll({a.key, b.key});
      _selected = null;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _wrong.removeAll({a.key, b.key}));
    });
  }

  void _maybeAdvance() {
    if (_terms.isNotEmpty) return;
    if (_cursor < _pool.length) {
      setState(_loadSet);
    } else {
      _finish(cleared: true);
    }
  }

  Future<void> _finish({required bool cleared}) async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final coins = _score + (cleared ? _perfectBonus : 0);
    setState(() {
      _cleared = cleared;
      _elapsed = _roundSeconds - _secondsLeft;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MatchHeader(
              secondsLeft: _secondsLeft,
              totalSeconds: _roundSeconds,
              score: _score,
              finished: _finished,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _finished
                      ? _MatchResult(
                          score: _score,
                          total: _pool.length,
                          stars: _stars,
                          cleared: _cleared,
                          elapsed: _elapsed,
                          awardedCoins: _awardedCoins,
                          coinsPossible: _coinsPossible,
                          awarding: _awarding,
                          onPlayAgain: () => setState(_reset),
                          onDone: () => Navigator.of(context).maybePop(),
                        )
                      : _MatchBoard(
                          terms: _terms,
                          defs: _defs,
                          selectedKey: _selected?.key,
                          matched: _matched,
                          wrong: _wrong,
                          onTap: _onTap,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
