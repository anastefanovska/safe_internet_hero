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
import 'register_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.authFillAllFields),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        AppPageRoute(builder: (_) => const PostLoginSplash()),
        (r) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? l10n.loginFailed),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final desktop = isDesktop(context);

    Widget content = Column(
      children: [
          // ── Blue header ────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // On desktop the browser's back button handles this.
                      if (!desktop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.loginWelcomeBack,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 350))
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 4),
                        Text(
                          l10n.loginSubtitle,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: const Duration(milliseconds: 300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── White form body ────────────────────────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    AppTextField(
                      controller: _emailController,
                      hint: l10n.authEmailHint,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 14),

                    // Password
                    AppTextField(
                      controller: _passwordController,
                      hint: l10n.authPasswordHint,
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    )
                        .animate(delay: 220.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    AppButton(
                      label: auth.isLoading ? l10n.loginLoggingIn : l10n.loginButton,
                      variant: AppButtonVariant.primary,
                      onTap: auth.isLoading ? null : _login,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.border,
                                thickness: 1.5)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(l10n.commonOr,
                              style: GoogleFonts.nunito(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.border,
                                thickness: 1.5)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    AppButton(
                      label: l10n.loginContinueGuest,
                      variant: AppButtonVariant.secondary,
                      icon: Icons.person_outline_rounded,
                      onTap: () {
                        context.read<AuthProvider>().continueAsGuest();
                        Navigator.of(context).pushAndRemoveUntil(
                          AppPageRoute(builder: (_) => const MainScreen()),
                          (route) => false,
                        );
                      },
                    )
                        .animate(delay: 380.ms)
                        .fadeIn(duration: 350.ms),

                    const SizedBox(height: 28),

                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                              context,
                              AppPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                    text: l10n.loginNoAccount),
                                TextSpan(
                                  text: l10n.loginCreateOne,
                                  style: GoogleFonts.nunito(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
