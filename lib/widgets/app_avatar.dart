import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/theme.dart';

// ─── AppAvatar ─────────────────────────────────────────────────────────────────
// Generates a deterministic gradient circle with the user's initial.
// Used everywhere instead of raw emoji letters.

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool goldFrame;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.borderColor,
    this.borderWidth = 2.5,
    this.goldFrame = false,
  });

  static const _gradients = [
    [Color(0xFF1CB0F6), Color(0xFF5AB4F7)], // blue
    [Color(0xFF58CC02), Color(0xFF8BD449)], // green
    [Color(0xFFFF9600), Color(0xFFFFB84D)], // orange
    [Color(0xFF7C4DFF), Color(0xFFAD8FFF)], // purple
    [Color(0xFFFF4B4B), Color(0xFFFF8080)], // red
    [Color(0xFF00BCD4), Color(0xFF4DD0E1)], // cyan
    [Color(0xFFFF6D00), Color(0xFFFF9D4D)], // deep orange
    [Color(0xFF2BBFAA), Color(0xFF4DD0C4)], // teal
  ];

  static List<Color> colorsFor(String name) {
    if (name.isEmpty) return _gradients[0];
    final hash = name.codeUnits.reduce((a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = colorsFor(name);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );

    if (goldFrame) {
      // White inner gap
      avatar = Container(
        width: size + 4,
        height: size + 4,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: avatar,
        ),
      );
      // Gold gradient outer ring with glow
      avatar = Container(
        width: size + 12,
        height: size + 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFE566),
              Color(0xFFFFB300),
              Color(0xFFCC7800),
              Color(0xFFFFB300),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: avatar,
        ),
      );
    } else if (borderColor != null) {
      avatar = Container(
        width: size + borderWidth * 2,
        height: size + borderWidth * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: borderColor,
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: avatar,
        ),
      );
    }

    return avatar;
  }
}

// ─── AppCategoryIcon ───────────────────────────────────────────────────────────
// Vector icon in a rounded square, colored by category.
// Static helpers give you color + IconData without building a widget.

class AppCategoryIcon extends StatelessWidget {
  final String title;
  final double size;
  final Color? overrideColor;

  const AppCategoryIcon({
    super.key,
    required this.title,
    this.size = 44,
    this.overrideColor,
  });

  static Color colorFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('privacy')) return AppColors.categoryPrivacy;
    if (t.contains('password')) return AppColors.categoryPasswords;
    if (t.contains('bully') || t.contains('cyber')) return AppColors.categoryCyberbullying;
    if (t.contains('social')) return AppColors.categorySocialMedia;
    if (t.contains('phish')) return AppColors.categoryPhishing;
    return AppColors.blue;
  }

  static Color darkColorFor(String title) {
    final base = colorFor(title);
    final hsl = HSLColor.fromColor(base);
    // Gradient end: lighter + more pastel (desaturated) version of the base
    return hsl
        .withSaturation((hsl.saturation - 0.18).clamp(0, 1))
        .withLightness((hsl.lightness + 0.22).clamp(0, 0.92))
        .toColor();
  }

  static IconData iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('privacy')) return Icons.lock_rounded;
    if (t.contains('password')) return Icons.vpn_key_rounded;
    if (t.contains('bully') || t.contains('cyber')) return Icons.shield_rounded;
    if (t.contains('social')) return Icons.smartphone_rounded;
    if (t.contains('phish')) return Icons.phishing_rounded;
    return Icons.school_rounded;
  }

  /// Localized display name for the fixed safety-curriculum categories, matched
  /// on the same stable keywords as [colorFor] (works for a category id slug or
  /// its English title). Unknown/custom categories keep their stored title.
  ///
  /// Resolved at display time from [l10n] (context), so it updates the moment
  /// the language is switched — and it never touches the stored value, so the
  /// admin editor and Firestore keep the original English source.
  static String localizedTitle(String idOrTitle, AppLocalizations l10n) {
    final t = idOrTitle.toLowerCase();
    if (t.contains('privacy')) return l10n.categoryPrivacyName;
    if (t.contains('password')) return l10n.categoryPasswordsName;
    if (t.contains('bully') || t.contains('cyber')) {
      return l10n.categoryCyberbullyingName;
    }
    if (t.contains('social')) return l10n.categorySocialMediaName;
    if (t.contains('phish')) return l10n.categoryPhishingName;
    return idOrTitle;
  }

  static bool isLightColor(Color c) => c.computeLuminance() > 0.45;

  @override
  Widget build(BuildContext context) {
    final color = overrideColor ?? colorFor(title);
    final icon = iconFor(title);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Icon(icon, color: color, size: size * 0.52),
      ),
    );
  }
}
