import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../data/privacy_fields.dart';
import '../../models/privacy_field_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/mini_game_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_widgets.dart';
import 'mini_game_shared.dart';

/// "Privacy Setup" — you configure a mock profile, choosing who can see each
/// field: **Public**, **Friends**, or **Private**. Everything starts Public, and
/// the job is to lock down what shouldn't be. Unlike the swipe games this is a
/// 3-way settings simulation — the interaction mirrors the real privacy screens
/// kids actually face. Scored against the safe setting, with a reason for each.
class PrivacySetupScreen extends StatefulWidget {
  final String userId;
  const PrivacySetupScreen({super.key, required this.userId});

  @override
  State<PrivacySetupScreen> createState() => _PrivacySetupScreenState();
}

class _PrivacySetupScreenState extends State<PrivacySetupScreen> {
  static const _gameId = 'privacy_setup';
  static const _roundSize = 7;
  static const _accent = AppColors.categoryPrivacy;

  final _service = MiniGameService();

  late List<PrivacyFieldModel> _fields;
  final Map<String, FieldVisibility> _choice = {};
  bool _checked = false;

  bool _finished = false;
  bool _awarding = false;
  int _awardedCoins = 0;
  int _coinsPossible = 0;

  @override
  void initState() {
    super.initState();
    _fields = _newRound();
  }

  List<PrivacyFieldModel> _newRound() {
    final f =
        (List<PrivacyFieldModel>.of(privacyFields)..shuffle()).take(_roundSize).toList();
    _choice.clear();
    for (final field in f) {
      _choice[field.id] = FieldVisibility.public; // risky default, on purpose
    }
    return f;
  }

  int get _correct =>
      _fields.where((f) => _choice[f.id] == f.recommended).length;

  void _set(String id, FieldVisibility v) {
    if (_checked) return;
    HapticService.instance.selection();
    setState(() => _choice[id] = v);
  }

  void _check() {
    setState(() => _checked = true);
    final perfect = _correct == _fields.length;
    if (perfect) {
      SoundService.instance.playCorrect();
      HapticService.instance.success();
    } else {
      SoundService.instance.playWrong();
      HapticService.instance.error();
    }
  }

  Future<void> _finish() async {
    final coins = _correct + (_correct == _fields.length ? 5 : 0);
    setState(() {
      _finished = true;
      _awarding = true;
      _coinsPossible = coins;
    });
    SoundService.instance.playComplete(miniGameStars(_correct, _fields.length));

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
      _fields = _newRound();
      _checked = false;
      _finished = false;
      _awardedCoins = 0;
      _coinsPossible = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars = miniGameStars(_correct, _fields.length);
    return Scaffold(
      backgroundColor: miniGameBackdrop(context),
      body: SafeArea(
        child: MiniGameShell(
          child: Column(
          children: [
            MiniGameTopBar(
              onClose: () => Navigator.of(context).maybePop(),
              progress: _finished
                  ? 1
                  : _checked
                      ? 1
                      : 0,
              score: _checked ? _correct : 0,
              accent: _accent,
              scoreIcon: Icons.verified_user_rounded,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 740),
                  child: _finished
                      ? MiniGameResult(
                          stars: stars,
                          headline: switch (stars) {
                            3 => AppLocalizations.of(context).privacyHeadline3,
                            2 => AppLocalizations.of(context).privacyHeadline2,
                            1 => AppLocalizations.of(context).privacyHeadline1,
                            _ => AppLocalizations.of(context).privacyHeadline0,
                          },
                          subtitle:
                              AppLocalizations.of(context).privacyFieldsSafe(_correct, _fields.length),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: _accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _checked
                            ? AppLocalizations.of(context).privacyGreenSafe
                            : AppLocalizations.of(context).privacyWhoCanSee,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_checked) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context).privacyStartPublic,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ..._fields.map(_fieldCard),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _checked
              ? AppButton(
                  label: AppLocalizations.of(context).redFlagSeeResults,
                  variant: AppButtonVariant.success,
                  icon: Icons.arrow_forward_rounded,
                  onTap: _finish,
                )
              : AppButton(
                  label: AppLocalizations.of(context).privacyCheckProfile,
                  icon: Icons.shield_rounded,
                  onTap: _check,
                ),
        ),
      ],
    );
  }

  Widget _fieldCard(PrivacyFieldModel f) {
    final chosen = _choice[f.id]!;
    final right = chosen == f.recommended;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _checked
              ? (right ? AppColors.green : AppColors.red)
                  .withValues(alpha: 0.5)
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(f.icon, color: _accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  f.label,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_checked)
                Icon(
                  right ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: right ? AppColors.green : AppColors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: FieldVisibility.values.map((v) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: v == FieldVisibility.private ? 0 : 8),
                  child: _segment(f, v, chosen),
                ),
              );
            }).toList(),
          ),
          if (_checked) ...[
            const SizedBox(height: 10),
            Text(
              f.explanation,
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
    );
  }

  Widget _segment(PrivacyFieldModel f, FieldVisibility v, FieldVisibility chosen) {
    final selected = chosen == v;
    Color bg = Colors.white;
    Color fg = AppColors.textSecondary;
    Color border = AppColors.border;

    if (_checked) {
      if (v == f.recommended) {
        // The safe answer — always shown green after checking.
        bg = AppColors.green.withValues(alpha: 0.14);
        fg = AppColors.greenDark;
        border = AppColors.green;
      } else if (selected) {
        // What the player picked, and it was wrong.
        bg = AppColors.red.withValues(alpha: 0.12);
        fg = AppColors.red;
        border = AppColors.red;
      }
    } else if (selected) {
      bg = _accent.withValues(alpha: 0.14);
      fg = _accent;
      border = _accent;
    }

    return MouseRegion(
      cursor: _checked ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _set(f.id, v),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: border, width: selected || (_checked && v == f.recommended) ? 2 : 1.2),
          ),
          child: Column(
            children: [
              Icon(v.icon, color: fg, size: 18),
              const SizedBox(height: 3),
              Text(
                v.labelOf(AppLocalizations.of(context)),
                style: GoogleFonts.nunito(
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
