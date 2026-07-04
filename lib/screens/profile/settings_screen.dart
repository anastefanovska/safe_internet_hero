import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../auth/splash_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                    child: const SizedBox(
                      width: 48,
                      child: Text(
                        'DONE',
                        textAlign: TextAlign.right,
                        style: TextStyle(
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
                    _SectionHeader('Game'),
                    const SizedBox(height: 8),
                    _ToggleGroup(
                      items: [
                        _ToggleRow(
                          icon: Icons.volume_up_rounded,
                          label: 'Sound effects',
                          initialValue: !SoundService.instance.isMuted,
                          onChanged: (on) =>
                              SoundService.instance.muted = !on,
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_rounded,
                          label: 'Vibration',
                          initialValue: HapticService.instance.isEnabled,
                          onChanged: (on) {
                            HapticService.instance.enabled = on;
                            // Let the user feel it switch on.
                            if (on) HapticService.instance.medium();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Account section
                    _SectionHeader('Account'),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      items: [
                        _SettingsItem(label: 'Preferences', onTap: () {}),
                        _SettingsItem(label: 'Profile', onTap: () {}),
                        _SettingsItem(label: 'Notifications', onTap: () {}),
                        _SettingsItem(label: 'Privacy settings', onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Support section
                    _SectionHeader('Support'),
                    const SizedBox(height: 8),
                    _SettingsGroup(
                      items: [
                        _SettingsItem(label: 'Help Center', onTap: () {}),
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
                          child: const Text(
                            'LOG OUT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                const Text(
                  'Log Out?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context, false),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: 'Log Out',
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
