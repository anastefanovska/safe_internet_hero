import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../core/app_locale.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/mini_game_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_widgets.dart';
import 'mini_game_shared.dart';

/// "Password Power" — take a weak password and pick the changes that would make
/// it stronger (some options are traps). A live strength meter fills as you make
/// good choices, so the payoff is visible and tactile. Coins once per day.
class PasswordPowerScreen extends StatefulWidget {
  final String userId;
  const PasswordPowerScreen({super.key, required this.userId});

  @override
  State<PasswordPowerScreen> createState() => _PasswordPowerScreenState();
}

class _PwOption {
  final String label;
  final bool good; // true = genuinely stronger
  final String note; // why (shown after checking)
  const _PwOption(this.label, this.good, this.note);
}

class _PwRound {
  final String password;
  final List<_PwOption> options;
  const _PwRound(this.password, this.options);

  int get goodCount => options.where((o) => o.good).length;
}

/// Rounds resolved to the app's content language ([AppLocale.code]). The weak
/// example passwords stay identical across languages; only the option labels and
/// their explanatory notes are translated. The `good`/trap flags and their order
/// match across languages so scoring is unchanged.
List<_PwRound> get _rounds => AppLocale.code == 'mk' ? _roundsMk : _roundsEn;

const List<_PwRound> _roundsEn = [
  _PwRound('kitten', [
    _PwOption('Make it 12+ characters long', true,
        'Longer passwords are dramatically harder to crack.'),
    _PwOption('Add numbers and symbols', true,
        'Mixing in numbers and symbols hugely increases the combinations.'),
    _PwOption('Mix UPPER and lower case', true,
        'Using both cases makes each letter harder to guess.'),
    _PwOption('Add your birth year at the end', false,
        'Your birth year is easy for others to find and guess.'),
    _PwOption('Change it to "password1"', false,
        '"password1" is one of the most common passwords in the world.'),
  ]),
  _PwRound('john2010', [
    _PwOption('Remove your name and birth year', true,
        'Names and years are easy to look up — leave them out.'),
    _PwOption('Use a few random words together', true,
        'Random word combos are long, memorable and hard to guess.'),
    _PwOption('Add symbols like ! and #', true,
        'Symbols add variety that guessing tools struggle with.'),
    _PwOption('Just add "123" at the end', false,
        'Adding "123" is the first thing an attacker tries.'),
    _PwOption('Make every letter a capital', false,
        'ALL CAPS alone is still easy — you need real variety.'),
  ]),
  _PwRound('qwerty', [
    _PwOption('Avoid keyboard patterns', true,
        '"qwerty" and "123456" are the first patterns attackers test.'),
    _PwOption('Make it much longer', true,
        'Every extra character multiplies how long cracking takes.'),
    _PwOption('Mix in symbols and numbers', true,
        'A good mix of character types is what makes a password strong.'),
    _PwOption('Just add "!" to make "qwerty!"', false,
        'It\'s still the "qwerty" pattern — one symbol doesn\'t fix it.'),
    _PwOption('Reuse your email password', false,
        'Reusing passwords means one breach unlocks everything.'),
  ]),
  _PwRound('sunshine', [
    _PwOption('Combine a few random words', true,
        'Random word combos are long and hard to guess but easy to remember.'),
    _PwOption('Add numbers and symbols', true,
        'A mix of character types massively increases the possibilities.'),
    _PwOption('Make it much longer', true,
        'Length is the single biggest thing that makes a password strong.'),
    _PwOption('Add "2024" on the end', false,
        'Years are one of the first things attackers try.'),
    _PwOption('Spell it backwards', false,
        '"enihsnus" is just as easy for a computer to guess.'),
  ]),
  _PwRound('iloveyou', [
    _PwOption('Use something that isn\'t a famous phrase', true,
        '"iloveyou" is one of the most-guessed passwords ever.'),
    _PwOption('Make it long and unpredictable', true,
        'Unpredictable and long is exactly what beats guessing tools.'),
    _PwOption('Mix in symbols and numbers', true,
        'Symbols and numbers add the variety a strong password needs.'),
    _PwOption('Change it to "iloveyou2"', false,
        'Adding a number to a common phrase is still easy to crack.'),
    _PwOption('Just make it ALL CAPS', false,
        'Capitalising a common phrase barely helps at all.'),
  ]),
  _PwRound('abc123', [
    _PwOption('Avoid simple sequences', true,
        '"abc" and "123" are the very first patterns attackers test.'),
    _PwOption('Use unrelated random words', true,
        'Unrelated words are far harder to guess than a sequence.'),
    _PwOption('Add length and symbols', true,
        'More length and symbols turn a weak base into a strong one.'),
    _PwOption('Add "!" to make "abc123!"', false,
        'One symbol on a famous pattern doesn\'t make it safe.'),
    _PwOption('Use your pet\'s name instead', false,
        'Pet names are easy to find on your profiles — avoid them.'),
  ]),
];

const List<_PwRound> _roundsMk = [
  _PwRound('kitten', [
    _PwOption('Направи ја долга 12+ знаци', true,
        'Подолгите лозинки се драматично потешки за пробивање.'),
    _PwOption('Додади бројки и симболи', true,
        'Мешањето бројки и симболи огромно ги зголемува комбинациите.'),
    _PwOption('Мешај ГОЛЕМИ и мали букви', true,
        'Користењето на двата случаи прави секоја буква потешка за погодување.'),
    _PwOption('Додади ја годината на раѓање на крајот', false,
        'Годината на раѓање е лесна за другите да ја најдат и погодат.'),
    _PwOption('Смени ја во „password1“', false,
        '„password1“ е една од најчестите лозинки во светот.'),
  ]),
  _PwRound('john2010', [
    _PwOption('Отстрани ги името и годината на раѓање', true,
        'Имињата и годините се лесни за пронаоѓање — изостави ги.'),
    _PwOption('Користи неколку случајни зборови заедно', true,
        'Комбинациите од случајни зборови се долги, лесни за помнење и тешки за погодување.'),
    _PwOption('Додади симболи како ! и #', true,
        'Симболите додаваат разновидност со која алатките за погодување тешко се справуваат.'),
    _PwOption('Само додади „123“ на крајот', false,
        'Додавањето „123“ е првото нешто што напаѓачот го проба.'),
    _PwOption('Направи ја секоја буква голема', false,
        'САМО ГОЛЕМИ БУКВИ сепак е лесно — потребна ти е вистинска разновидност.'),
  ]),
  _PwRound('qwerty', [
    _PwOption('Избегнувај шаблони од тастатура', true,
        '„qwerty“ и „123456“ се првите шаблони што ги тестираат напаѓачите.'),
    _PwOption('Направи ја многу подолга', true,
        'Секој дополнителен знак го умножува времето потребно за пробивање.'),
    _PwOption('Вметни симболи и бројки', true,
        'Добра мешавина од типови знаци е тоа што ја прави лозинката силна.'),
    _PwOption('Само додади „!“ за да стане „qwerty!“', false,
        'Сепак е шаблонот „qwerty“ — еден симбол не го поправа тоа.'),
    _PwOption('Искористи ја лозинката од е-поштата', false,
        'Повторното користење лозинки значи дека еден пробив отклучува сѐ.'),
  ]),
  _PwRound('sunshine', [
    _PwOption('Комбинирај неколку случајни зборови', true,
        'Комбинациите од случајни зборови се долги и тешки за погодување, но лесни за помнење.'),
    _PwOption('Додади бројки и симболи', true,
        'Мешавина од типови знаци огромно ги зголемува можностите.'),
    _PwOption('Направи ја многу подолга', true,
        'Должината е најголемото нешто што ја прави лозинката силна.'),
    _PwOption('Додади „2024“ на крајот', false,
        'Годините се едни од првите нешта што напаѓачите ги пробуваат.'),
    _PwOption('Напиши ја наопаку', false,
        '„enihsnus“ е исто толку лесно за компјутер да го погоди.'),
  ]),
  _PwRound('iloveyou', [
    _PwOption('Користи нешто што не е позната фраза', true,
        '„iloveyou“ е една од најпогодуваните лозинки некогаш.'),
    _PwOption('Направи ја долга и непредвидлива', true,
        'Непредвидлива и долга е токму она што ги победува алатките за погодување.'),
    _PwOption('Вметни симболи и бројки', true,
        'Симболите и бројките ја додаваат разновидноста што ѝ треба на силна лозинка.'),
    _PwOption('Смени ја во „iloveyou2“', false,
        'Додавањето бројка на честа фраза сепак е лесно за пробивање.'),
    _PwOption('Само направи ја со САМО ГОЛЕМИ БУКВИ', false,
        'Пишувањето честа фраза со големи букви речиси воопшто не помага.'),
  ]),
  _PwRound('abc123', [
    _PwOption('Избегнувај едноставни низи', true,
        '„abc“ и „123“ се првите шаблони што ги тестираат напаѓачите.'),
    _PwOption('Користи неповрзани случајни зборови', true,
        'Неповрзаните зборови се многу потешки за погодување од низа.'),
    _PwOption('Додади должина и симболи', true,
        'Повеќе должина и симболи претвораат слаба основа во силна.'),
    _PwOption('Додади „!“ за да стане „abc123!“', false,
        'Еден симбол на познат шаблон не го прави безбеден.'),
    _PwOption('Наместо тоа користи го името на миленикот', false,
        'Имињата на миленици се лесни за пронаоѓање на твоите профили — избегнувај ги.'),
  ]),
];

class _PasswordPowerScreenState extends State<PasswordPowerScreen> {
  static const _gameId = 'password_power';
  static const _accent = AppColors.categoryPasswords;
  static const _roundCount = 4;

  final _service = MiniGameService();

  late List<_PwRound> _deck;
  int _index = 0;
  final Set<int> _selected = {};
  bool _checked = false;
  int _score = 0; // correct decisions across rounds

  bool _finished = false;
  bool _awarding = false;
  int _awardedCoins = 0;
  int _coinsPossible = 0;

  @override
  void initState() {
    super.initState();
    _deck = _newDeck();
  }

  /// A fresh, shuffled set of rounds each play — and the options within each
  /// round are shuffled too, so the good/trap answers never sit in the same spot.
  List<_PwRound> _newDeck() {
    final rounds = _rounds
        .map((r) => _PwRound(r.password, List.of(r.options)..shuffle()))
        .toList()
      ..shuffle();
    return rounds.take(_roundCount).toList();
  }

  _PwRound get _r => _deck[_index];
  bool get _lastRound => _index >= _deck.length - 1;
  int get _totalDecisions =>
      _deck.fold(0, (s, r) => s + r.options.length);

  /// Live strength 0..1 — good picks raise it, trap picks drag it down.
  double get _strength {
    var good = 0, bad = 0;
    for (final i in _selected) {
      _r.options[i].good ? good++ : bad++;
    }
    return ((good - bad) / _r.goodCount).clamp(0.0, 1.0);
  }

  int get _roundCorrect {
    var correct = 0;
    for (var i = 0; i < _r.options.length; i++) {
      if (_selected.contains(i) == _r.options[i].good) correct++;
    }
    return correct;
  }

  void _toggle(int i) {
    if (_checked) return;
    HapticService.instance.selection();
    setState(() {
      _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
    });
  }

  void _check() {
    setState(() => _checked = true);
    final strong = _strength >= 0.99;
    if (strong) {
      SoundService.instance.playCorrect();
      HapticService.instance.success();
    } else {
      SoundService.instance.playWrong();
      HapticService.instance.error();
    }
  }

  void _next() {
    _score += _roundCorrect;
    if (_lastRound) {
      _finish();
    } else {
      setState(() {
        _index++;
        _selected.clear();
        _checked = false;
      });
    }
  }

  Future<void> _finish() async {
    final stars = miniGameStars(_score, _totalDecisions);
    final coins = _score + (_score == _totalDecisions ? 5 : 0);
    setState(() {
      _finished = true;
      _awarding = true;
      _coinsPossible = coins;
    });
    SoundService.instance.playComplete(stars);

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
      _selected.clear();
      _checked = false;
      _score = 0;
      _finished = false;
      _awardedCoins = 0;
      _coinsPossible = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = miniGameStars(_score, _totalDecisions);
    return Scaffold(
      backgroundColor: miniGameBackdrop(context),
      body: SafeArea(
        child: MiniGameShell(
          child: Column(
          children: [
            MiniGameTopBar(
              onClose: () => Navigator.of(context).maybePop(),
              progress: _finished ? 1 : _index / _deck.length,
              score: _score,
              accent: _accent,
              scoreIcon: Icons.lock_rounded,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 740),
                  child: _finished
                      ? MiniGameResult(
                          stars: stars,
                          headline: switch (stars) {
                            3 => AppLocalizations.of(context).pwHeadline3,
                            2 => AppLocalizations.of(context).pwHeadline2,
                            1 => AppLocalizations.of(context).pwHeadline1,
                            _ => AppLocalizations.of(context).pwHeadline0,
                          },
                          subtitle:
                              AppLocalizations.of(context).pwSmartChoices(_score, _totalDecisions),
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
          Text(
            AppLocalizations.of(context).pwMakeStronger,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _PasswordMeter(password: _r.password, strength: _strength),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).pwPickChanges,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_r.options.length, (i) => _optionRow(i)),
          const SizedBox(height: 8),
          AppButton(
            label: _checked
                ? (_lastRound ? AppLocalizations.of(context).redFlagSeeResults : AppLocalizations.of(context).pwNextPassword)
                : AppLocalizations.of(context).pwCheck,
            variant: AppButtonVariant.primary,
            icon: _checked ? Icons.arrow_forward_rounded : Icons.check_rounded,
            onTap: _checked ? _next : (_selected.isEmpty ? null : _check),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(int i) {
    final opt = _r.options[i];
    final selected = _selected.contains(i);
    // After checking, colour by whether the decision was right.
    Color border = selected ? _accent : AppColors.border;
    Color bg = selected ? _accent.withValues(alpha: 0.08) : Colors.white;
    if (_checked) {
      final decidedRight = selected == opt.good;
      final c = decidedRight ? AppColors.green : AppColors.red;
      border = c.withValues(alpha: 0.6);
      bg = c.withValues(alpha: 0.08);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.6),
      ),
      child: MouseRegion(
        cursor: _checked ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _toggle(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _checkbox(selected, opt),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_checked)
                      Icon(
                        opt.good
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_down_rounded,
                        color: opt.good ? AppColors.green : AppColors.red,
                        size: 18,
                      ),
                  ],
                ),
                if (_checked) ...[
                  const SizedBox(height: 8),
                  Text(
                    opt.note,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkbox(bool selected, _PwOption opt) {
    final showState = _checked;
    final color = showState
        ? (opt.good ? AppColors.green : AppColors.red)
        : _accent;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
            color: selected ? color : AppColors.borderDark, width: 2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
          : null,
    );
  }
}

// ─── Password + strength meter ────────────────────────────────────────────────

class _PasswordMeter extends StatelessWidget {
  final String password;
  final double strength; // 0..1
  const _PasswordMeter({required this.password, required this.strength});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (strength) {
      >= 0.99 => (l10n.pwStrong, AppColors.green),
      >= 0.5 => (l10n.pwGettingThere, AppColors.orange),
      > 0.0 => (l10n.pwWeak, AppColors.orangeDark),
      _ => (l10n.pwVeryWeak, AppColors.red),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.password_rounded,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                password,
                style: GoogleFonts.robotoMono(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: strength),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v.clamp(0.06, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
