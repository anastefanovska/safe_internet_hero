import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/haptic_service.dart';
import 'app_avatar.dart';

// ─── AppButton ─────────────────────────────────────────────────────────────────
// Duolingo-style 3D press button.
// FIX: uses onTap (not onTapUp) so mouse-click on web always fires the callback.

enum AppButtonVariant { primary, secondary, danger, success }

class AppButton extends StatefulWidget {
  final String label;
  final AppButtonVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppButton({
    super.key,
    required this.label,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.onTap,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  static const _depth = 4.0;

  Color get _bg => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.blue,
        AppButtonVariant.secondary => Colors.white,
        AppButtonVariant.danger => AppColors.red,
        AppButtonVariant.success => AppColors.green,
      };

  Color get _shadow => switch (widget.variant) {
        AppButtonVariant.primary => AppColors.blueDark,
        AppButtonVariant.secondary => AppColors.borderDark,
        AppButtonVariant.danger => AppColors.redDark,
        AppButtonVariant.success => AppColors.greenDark,
      };

  Color get _fg => widget.variant == AppButtonVariant.secondary
      ? AppColors.blue
      : Colors.white;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: _fg, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: _fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        // onTap fires reliably on both web mouse-click and mobile touch.
        onTap: disabled ? null : widget.onTap,
        onTapDown: disabled
            ? null
            : (_) {
                setState(() => _pressed = true);
                HapticService.instance.light();
              },
        onTapUp:
            disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          // A tiny squish on press so the button feels physical on every
          // platform, not just where haptics fire.
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Opacity(
          opacity: disabled ? 0.55 : 1.0,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Shadow layer — always offset _depth below
              Padding(
                padding: const EdgeInsets.only(top: _depth),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 24),
                  decoration: BoxDecoration(
                    color: _shadow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Opacity(opacity: 0, child: content),
                ),
              ),
              // Button body — slides down on press, covering shadow
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: double.infinity,
                margin: EdgeInsets.only(top: _pressed ? _depth : 0),
                padding: const EdgeInsets.symmetric(
                    vertical: 15, horizontal: 24),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.variant == AppButtonVariant.secondary
                      ? Border.all(color: AppColors.borderDark, width: 2)
                      : null,
                ),
                child: content,
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ─── AppCard ───────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color ?? AppColors.card,
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── AppTopBar ─────────────────────────────────────────────────────────────────

class AppTopBar extends StatelessWidget {
  final int stars;
  final int streak;
  final int coins;
  final String? username;
  final VoidCallback? onAvatarTap;
  final bool goldFrame;

  const AppTopBar({
    super.key,
    required this.stars,
    required this.streak,
    this.coins = 0,
    this.username,
    this.onAvatarTap,
    this.goldFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Chip(
              icon: Icons.local_fire_department_rounded,
              value: streak,
              color: streak > 0 ? AppColors.orange : AppColors.textLight),
          const Spacer(),
          _Chip(
              icon: Icons.star_rounded,
              value: stars,
              color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          _Chip(
              icon: Icons.monetization_on_rounded,
              value: coins,
              color: AppColors.orangeDark),
          if (username != null) ...[
            const SizedBox(width: 12),
            MouseRegion(
              cursor: onAvatarTap != null
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                onTap: onAvatarTap,
                child: AppAvatar(name: username!, size: 34, goldFrame: goldFrame),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A currency/stat pill for [AppTopBar]. The number rolls up to its new value
/// and the whole pill gives a quick "pop" whenever it *increases*, so earning
/// coins or stars is felt in the corner of the eye even when the reward moment
/// happened on another screen. Purely visual, so it reinforces rewards on every
/// platform (web/desktop included, where haptics don't fire).
class _Chip extends StatefulWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _Chip(
      {required this.icon, required this.value, required this.color});

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final int _initial = widget.value;
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.22)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.22, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_Chip old) {
    super.didUpdateWidget(old);
    // Only celebrate gains — spending coins shouldn't bounce.
    if (widget.value > old.value) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 16),
            const SizedBox(width: 5),
            // Roll the digits from their previous value to the new one.
            TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: _initial.toDouble(), end: widget.value.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, v, __) => Text(
                '${v.round()}',
                style: GoogleFonts.nunito(
                  color: widget.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TabHeader ─────────────────────────────────────────────────────────────────
// Clean white header for the top of each main tab: a small colored icon tile +
// bold title (+ optional subtitle), with an optional trailing widget on the right.
// Replaces the old saturated blue gradient banners.

class TabHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final Widget? trailing;

  const TabHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.blue;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          // Optional colored icon tile
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tileColor, size: 26),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Shared guest CTA button ──────────────────────────────────────────────────

class GuestCTAButton extends StatefulWidget {
  final VoidCallback onTap;
  const GuestCTAButton({super.key, required this.onTap});

  @override
  State<GuestCTAButton> createState() => _GuestCTAButtonState();
}

class _GuestCTAButtonState extends State<GuestCTAButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.blueDark,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: double.infinity,
            margin: EdgeInsets.only(top: _pressed ? 4 : 0),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Create Free Account',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GuestLockedState ──────────────────────────────────────────────────────────

class GuestLockedState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String svgAsset;
  final VoidCallback onGetStarted;

  const GuestLockedState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.svgAsset,
    required this.onGetStarted,
    IconData? icon, // kept for call-site compatibility, ignored
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── SVG on top ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
          child: SvgPicture.asset(svgAsset, height: 110),
        ),

        // ── Ghost rows + fade + CTA ───────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    children: List.generate(5, (i) => _GhostLeaderboardRow(index: i)),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.3, 0.62, 1.0],
                      colors: [
                        AppColors.background.withValues(alpha: 0.0),
                        AppColors.background.withValues(alpha: 0.5),
                        AppColors.background.withValues(alpha: 0.92),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GuestCTAButton(onTap: onGetStarted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostLeaderboardRow extends StatelessWidget {
  final int index;
  const _GhostLeaderboardRow({required this.index});

  static const _names = ['HeroStar99', 'SafeKnight', 'CyberGuard', 'NetDefender', 'PrivacyPro'];
  static const _stars = [1840, 1620, 1430, 1290, 1100];

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (1.0 - index * 0.16).clamp(0.15, 0.75),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: Text('${index + 1}',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),
          AppAvatar(name: _names[index], size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_names[index],
                style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
          Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
            const SizedBox(width: 3),
            Text('${_stars[index]}',
                style: GoogleFonts.nunito(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Legacy widgets — kept for auth screens ────────────────────────────────────

class AppSolidButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppSolidButton({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: color,
        shape: shape,
        shadowColor: color,
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppOutlineButton({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      side: BorderSide(color: color, width: 2),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.white,
        shape: shape,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── AppTextField ──────────────────────────────────────────────────────────────
// Duolingo-style: visible gray border, blue on focus, radius 14.

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.blue, width: 2.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}
