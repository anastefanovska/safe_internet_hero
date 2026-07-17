import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../widgets/app_widgets.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _snack(l10n.authFillAllFields);
      return;
    }

    // Enforce unique usernames (case-insensitive)
    final taken = await FriendService().isUsernameTaken(username);
    if (!mounted) return;
    if (taken) {
      _snack(l10n.registerUsernameTaken);
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: email,
      password: password,
      username: username,
      ageGroup: AgeGroup.teens,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PostLoginSplash()));
    } else {
      _snack(auth.errorMessage ?? l10n.registerFailed);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final desktop = isDesktop(context);

    Widget content = Column(
      children: [
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
                          l10n.registerTitle,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.registerSubtitle,
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                    AppTextField(
                      controller: _usernameController,
                      hint: l10n.registerUsernameHint,
                      icon: Icons.person_outline_rounded,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 14),

                    AppTextField(
                      controller: _emailController,
                      hint: l10n.authEmailHint,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    )
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 14),

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
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    )
                        .animate(delay: 160.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 32),

                    AppButton(
                      label: auth.isLoading ? l10n.registerCreating : l10n.registerButton,
                      variant: AppButtonVariant.success,
                      icon: Icons.check_rounded,
                      onTap: auth.isLoading ? null : _register,
                    ).animate(delay: 240.ms).fadeIn(duration: 300.ms),

                    const SizedBox(height: 28),

                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen())),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(text: l10n.registerHaveAccount),
                                TextSpan(
                                  text: l10n.registerLogIn,
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
