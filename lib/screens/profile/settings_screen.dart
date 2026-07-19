import 'package:flutter/material.dart';
import 'package:safe_internet_hero/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../core/app_locale.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../auth/splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: white bg, "Settings" centered, "DONE" blue right ─
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Left: back arrow on desktop (browser back is unreliable
                  // here); plain spacer on mobile so the title stays centred.
                  SizedBox(
                    width: 48,
                    child: isDesktop(context)
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      l10n.settingsTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // "DONE" in blue — pops the screen
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 48),
                      child: Text(
                        l10n.settingsDone,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game feel — real, working toggles for the app's sound &
                    // haptics (session-scoped, like the services they drive).
                    _SectionHeader(l10n.settingsSectionGame),
                    const SizedBox(height: 8),
                    _ToggleGroup(
                      items: [
                        _ToggleRow(
                          icon: Icons.volume_up_rounded,
                          label: l10n.settingsSoundEffects,
                          initialValue: !SoundService.instance.isMuted,
                          onChanged: (on) =>
                              SoundService.instance.muted = !on,
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          label: l10n.settingsVibration,
                          initialValue: HapticService.instance.isEnabled,
                          onChanged: (on) {
                            HapticService.instance.enabled = on;
                            // Let the user feel it switch on.
                            if (on) HapticService.instance.medium();
                          },
                        ),
                        const _LanguageRow(),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Account section
                    _SectionHeader(l10n.settingsSectionAccount),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      items: [
                        _SettingsItem(label: l10n.settingsPreferences, onTap: () {}),
                        _SettingsItem(label: l10n.settingsProfile, onTap: () {}),
                        _SettingsItem(label: l10n.settingsNotifications, onTap: () {}),
                        _SettingsItem(label: l10n.settingsPrivacy, onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Support section
                    _SectionHeader(l10n.settingsSectionSupport),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      items: [
                        _SettingsItem(label: l10n.settingsHelpCenter, onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // LOG OUT — white card with shadow, blue text (matches settings.png)
                    Builder(builder: (context) {
                      final auth = context.read<AuthProvider>();
                      return GestureDetector(
                        onTap: () => _confirmLogOut(context, auth),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            l10n.settingsLogOut,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context, AuthProvider auth) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                      color: AppColors.blueLight, shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.blue, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.settingsLogOutConfirmTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsLogOutConfirmBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: l10n.commonCancel,
                        onTap: () => Navigator.pop(context, false),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: l10n.settingsLogOut,
                        onTap: () => Navigator.pop(context, true),
                        primary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            AppPageRoute(builder: (_) => const AuthGate()),
            (r) => false);
      }
    }
  }
}

// ── Section header label ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Settings group card ────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 16),
                    color: AppColors.border,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Toggle group + row (functional Sound / Vibration switches) ─────────────────

class _ToggleGroup extends StatelessWidget {
  final List<Widget> items;
  const _ToggleGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(
              children: [
                e.value,
                if (!isLast)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 52),
                    color: AppColors.border,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool initialValue;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  late bool _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(widget.icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: _value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.green,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

// ── Language row + picker ──────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  /// Each language names itself in its own tongue, so someone stranded in a
  /// language they can't read still recognises the way out.
  static String _labelOf(AppLanguage language, AppLocalizations l10n) =>
      switch (language) {
        AppLanguage.en => l10n.languageEnglish,
        AppLanguage.mk => l10n.languageMacedonian,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<LocaleProvider>().language;

    return GestureDetector(
      onTap: () => _pick(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.language_rounded,
                color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.settingsLanguage,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _labelOf(current, l10n),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final provider = context.read<LocaleProvider>();
    final l10n = AppLocalizations.of(context);

    final chosen = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              l10n.languagePickerTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final language in AppLanguage.values)
              ListTile(
                title: Text(
                  _labelOf(language, l10n),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: language == provider.language
                    ? const Icon(Icons.check_rounded, color: AppColors.green)
                    : null,
                onTap: () => Navigator.pop(sheetContext, language),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (chosen != null) {
      HapticService.instance.medium();
      await provider.setLanguage(chosen);
    }
  }
}

// ── Single row ─────────────────────────────────────────────────────────────────

class _SettingsItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SettingsItem({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Dialog button ──────────────────────────────────────────────────────────────

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: primary ? null : Border.all(color: AppColors.borderDark),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primary ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
