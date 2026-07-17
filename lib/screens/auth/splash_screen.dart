import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../home/main_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ─── Initial splash (app loading) ─────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _minTimePassed = false;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    // Show splash for at least 1.5s for visual polish.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _minTimePassed = true;
      _tryNavigate();
    });
    _auth.addListener(_tryNavigate);
  }

  @override
  void dispose() {
    _auth.removeListener(_tryNavigate);
    super.dispose();
  }

  void _tryNavigate() {
    if (!mounted || !_minTimePassed || _auth.isLoading) return;
    _auth.removeListener(_tryNavigate);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _auth.isLoggedIn ? const MainScreen() : const LandingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const _LoadingBody();
}

// ─── Post-login transition ─────────────────────────────────────────────────────

class PostLoginSplash extends StatefulWidget {
  const PostLoginSplash({super.key});

  @override
  State<PostLoginSplash> createState() => _PostLoginSplashState();
}

class _PostLoginSplashState extends State<PostLoginSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const _LoadingBody();
}

// ─── Loading body shared by both splash widgets ────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 60),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 800),
                ),
            const SizedBox(height: 20),
            Text(
              'safe internet\nhero',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            )
                .animate(delay: const Duration(milliseconds: 200))
                .fadeIn(duration: const Duration(milliseconds: 400)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            )
                .animate(delay: const Duration(milliseconds: 400))
                .fadeIn(duration: const Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }
}

// ─── Auth gate ─────────────────────────────────────────────────────────────────

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.blue,
        body: Center(
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 3),
        ),
      );
    }
    if (auth.isLoggedIn) return const PostLoginSplash();
    return const LandingScreen();
  }
}

// ─── Landing screen ────────────────────────────────────────────────────────────

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final desktop = isDesktop(context);

    Widget content = Column(
      children: [
          // ── Hero section ───────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mascot
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.blueLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Icon(Icons.shield_rounded,
                            color: AppColors.blue, size: 60),
                      ],
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: const Duration(milliseconds: 900),
                      ),

                  const SizedBox(height: 28),

                  Text(
                    'SAFE INTERNET\nHERO',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.2,
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 200))
                      .fadeIn(duration: const Duration(milliseconds: 400))
                      .slideY(
                          begin: 0.15,
                          end: 0,
                          duration: const Duration(milliseconds: 400)),

                  const SizedBox(height: 12),

                  Text(
                    l10n.landingTagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 350))
                      .fadeIn(duration: const Duration(milliseconds: 350)),
                ],
              ),
            ),
          ),

          // ── CTA panel ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: l10n.landingGetStarted,
                    variant: AppButtonVariant.success,
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.push(
                        context,
                        AppPageRoute(
                            builder: (_) => const RegisterScreen())),
                  ),

                  const SizedBox(height: 14),

                  AppButton(
                    label: l10n.landingHaveAccount,
                    variant: AppButtonVariant.secondary,
                    onTap: () => Navigator.push(
                        context,
                        AppPageRoute(
                            builder: (_) => const LoginScreen())),
                  ),

                  const SizedBox(height: 22),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        context.read<AuthProvider>().continueAsGuest();
                        Navigator.of(context).pushAndRemoveUntil(
                          AppPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        l10n.landingContinueGuest,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          )
              .animate(delay: const Duration(milliseconds: 400))
              .fadeIn(duration: const Duration(milliseconds: 450))
              .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut),
      ],
    );

    if (desktop) {
      content = Center(child: SizedBox(width: 480, child: content));
    }

    return Scaffold(
      backgroundColor: AppColors.blue,
      body: content,
    );
  }
}
