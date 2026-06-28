import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Blues — Macaw / Whale / Iguana ───────────────────────────────────────
  static const blue      = Color(0xFF1CB0F6); // Macaw
  static const blueDark  = Color(0xFF1899D6); // Whale
  static const blueLight = Color(0xFFDDF4FF); // Iguana

  // ── Greens — Owl / Tree Frog / Sea Sponge ───────────────────────────────
  static const green      = Color(0xFF58CC02); // Owl
  static const greenDark  = Color(0xFF58A700); // Tree Frog
  static const greenLight = Color(0xFFD7FFB8); // Sea Sponge

  // ── Reds — Cardinal / Fire Ant / Walking Fish ────────────────────────────
  static const red      = Color(0xFFFF4B4B); // Cardinal
  static const redDark  = Color(0xFFEA2B2B); // Fire Ant
  static const redLight = Color(0xFFFFDFE0); // Walking Fish

  // ── Oranges — Fox / Guinea Pig / Cheetah ────────────────────────────────
  static const orange      = Color(0xFFFF9600); // Fox
  static const orangeDark  = Color(0xFFCD7900); // Guinea Pig
  static const orangeLight = Color(0xFFFFCE8E); // Cheetah

  // ── Yellows — Bee / Lion ─────────────────────────────────────────────────
  static const gold     = Color(0xFFFFC800); // Bee
  static const goldDark = Color(0xFFFFB100); // Lion

  // ── Legacy aliases so existing screens compile unchanged ─────────────────
  static const teal     = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);
  static const tealLight = Color(0xFF4DD0C4);
  static const primary  = blue;
  static const secondary = Color(0xFFFF6B6B);
  static const accent   = Color(0xFF4ECDC4);
  static const hero     = Color(0xFFE8524A);
  static const amber    = Color(0xFFFFB300);
  static const pink     = Color(0xFFF45B8C);
  static const correct  = green;
  static const wrong    = red;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const background = Color(0xFFF7F7F7); // Polar
  static const surface    = Colors.white;
  static const cream      = Color(0xFFF5FAF7);
  static const card       = Colors.white;

  // ── Borders — Swan / Hare ────────────────────────────────────────────────
  static const border     = Color(0xFFE5E5E5); // Swan
  static const borderDark = Color(0xFFAFAFAF); // Hare

  // ── Text — Eel / Wolf / Hare ─────────────────────────────────────────────
  static const textPrimary   = Color(0xFF4B4B4B); // Eel
  static const textSecondary = Color(0xFF777777); // Wolf
  static const textLight     = Color(0xFFAFAFAF); // Hare

  // ── Category palette ─────────────────────────────────────────────────────
  static const categoryPrivacy       = Color(0xFF9069CD); // Betta       (purple)
  static const categoryPasswords     = Color(0xFF1CB0F6); // Macaw       (sky blue)
  static const categoryCyberbullying = Color(0xFFFF7878); // Crab        (soft red)
  static const categorySocialMedia   = Color(0xFFE5A259); // Monkey      (warm amber)
  static const categoryPhishing      = Color(0xFFFFB100); // Lion        (golden)
}

// ─── Typography ───────────────────────────────────────────────────────────────
// Substitute rules (Feather Bold → Nunito Black, DIN Next Rounded → Nunito):
//
//  Headline  — Nunito w900, letterSpacing: -0.5, height: 1.05, always lowercase
//  Body      — Nunito w500–w600, letterSpacing: 0,  height: 1.4,  min 14 px
//  Label     — Nunito w700–w800, letterSpacing: 0,  no ALL-CAPS
//
//  Headline px ≈ body px × 1.5   (150 % size ratio)
//  Never use positive letterSpacing on headline text.

class AppTypography {
  AppTypography._();

  // ── Headline styles (Feather Bold substitute) ──────────────────────────
  static TextStyle headline(double size) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.05,
      );

  // ── Body styles (DIN Next Rounded substitute) ──────────────────────────
  static TextStyle body(double size, {FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0,
        height: 1.4,
      );

  // ── Label/UI chip (small, never ALL-CAPS) ─────────────────────────────
  static TextStyle label(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0,
        height: 1.2,
      );
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

const double kDesktopBreakpoint = 900.0;
const double kContentMaxWidth = 860.0;
const double kDesktopPanelWidth = 324.0;
const double kDesktopPanelMargin = 12.0;

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

/// Compact relative time ("just now", "5m ago", "3d ago", "Jan 4") used by
/// notification cards and the moderator review queue. Falls back to a short
/// date for anything older than a week.
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[time.month - 1]} ${time.day}';
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.light,
        primary: AppColors.blue,
        secondary: AppColors.green,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final nunito = GoogleFonts.nunitoTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: nunito.copyWith(
        displayLarge: nunito.displayLarge?.copyWith(fontWeight: FontWeight.w900),
        displayMedium: nunito.displayMedium?.copyWith(fontWeight: FontWeight.w900),
        titleLarge: nunito.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: nunito.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: nunito.labelLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
        bodyLarge: nunito.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: nunito.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }
}
