import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../widgets/app_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_service.dart';
import '../auth/splash_screen.dart';

class VideoScreen extends StatefulWidget {
  final LearningContentModel content;
  const VideoScreen({super.key, required this.content});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  static const _xp = 5;

  final _learningService = LearningService();

  bool _watchTriggered = false;
  bool _xpLoading = false;
  int? _xpEarned;

  String get _videoId => _extractVideoId(widget.content.content);

  static String _extractVideoId(String input) {
    final s = input.trim();
    if (!s.contains('/') && !s.contains('?')) return s;
    try {
      final uri = Uri.parse(s);
      if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first;
      }
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v']!;
      }
      final embedIdx = uri.pathSegments.indexOf('embed');
      if (embedIdx >= 0 && embedIdx + 1 < uri.pathSegments.length) {
        return uri.pathSegments[embedIdx + 1];
      }
    } catch (_) {}
    return s;
  }

  Future<void> _onWatch() async {
    await _launchVideo();
    if (!_watchTriggered) {
      _watchTriggered = true;
      await _awardXp();
    }
  }

  Future<void> _launchVideo() async {
    final youtubeApp = Uri.parse('vnd.youtube:$_videoId');
    final youtubeWeb =
        Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    if (await canLaunchUrl(youtubeApp)) {
      await launchUrl(youtubeApp);
    } else if (await canLaunchUrl(youtubeWeb)) {
      await launchUrl(youtubeWeb, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(youtubeWeb, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _awardXp() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (auth.isGuest) {
      setState(() => _xpEarned = -1);
      return;
    }

    final user = auth.user;
    if (user == null) return;

    setState(() => _xpLoading = true);
    try {
      final earned = await _learningService.markContentRead(
        userId: user.id,
        contentId: widget.content.id,
        xpToAward: _xp,
      );
      if (!mounted) return;
      setState(() {
        _xpEarned = earned;
        _xpLoading = false;
      });
      if (earned > 0) auth.refreshUser();
    } catch (_) {
      if (!mounted) return;
      setState(() => _xpLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthProvider>().isGuest;
    final accent = AppCategoryIcon.colorFor(widget.content.categoryId);
    final darkAccent = AppCategoryIcon.darkColorFor(widget.content.categoryId);
    final catIcon = AppCategoryIcon.iconFor(widget.content.categoryId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.content.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner
                  _VideoHero(
                    title: widget.content.title,
                    categoryId: widget.content.categoryId,
                    accent: accent,
                    darkAccent: darkAccent,
                    catIcon: catIcon,
                  ),

                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail card
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                          onTap: _onWatch,
                          child: _ThumbnailCard(videoId: _videoId),
                        ))
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 300.ms,
                                curve: Curves.easeOut),

                        const SizedBox(height: 20),

                        // Description
                        if (widget.content.description.isNotEmpty) ...[
                          Text(
                            widget.content.description,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // XP result
                        AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          child: _watchTriggered
                              ? _XpResultCard(
                                  isGuest: isGuest,
                                  isLoading: _xpLoading,
                                  xpEarned: _xpEarned,
                                  onCreateAccount: () {
                                    context
                                        .read<AuthProvider>()
                                        .exitGuestMode();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      AppPageRoute(
                                          builder: (_) =>
                                              const LandingScreen()),
                                      (r) => false,
                                    );
                                  },
                                )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideY(
                                        begin: 0.1,
                                        end: 0,
                                        duration: 300.ms)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero banner ─────────────────────────────────────────────────────────────

class _VideoHero extends StatelessWidget {
  final String title;
  final String categoryId;
  final Color accent;
  final Color darkAccent;
  final IconData catIcon;

  const _VideoHero({
    required this.title,
    required this.categoryId,
    required this.accent,
    required this.darkAccent,
    required this.catIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, darkAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(catIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _HeroBadge(
                icon: Icons.play_circle_rounded, label: AppLocalizations.of(context).videoTypeBadge),
            const SizedBox(width: 8),
            _HeroBadge(
                icon: Icons.star_rounded, label: AppLocalizations.of(context).contentXpBadge(_kXp)),
          ]),
        ],
      ),
    );
  }
}

const _kXp = 5;

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 11),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0,
          ),
        ),
      ]),
    );
  }
}

// ─── Thumbnail card ───────────────────────────────────────────────────────────

class _ThumbnailCard extends StatelessWidget {
  final String videoId;
  const _ThumbnailCard({required this.videoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _VideoPlaceholder(),
              ),
              Container(color: Colors.black.withValues(alpha: 0.25)),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 44),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          AppLocalizations.of(context).videoTapToWatch,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── XP result card ───────────────────────────────────────────────────────────

class _XpResultCard extends StatelessWidget {
  final bool isGuest;
  final bool isLoading;
  final int? xpEarned;
  final VoidCallback onCreateAccount;

  const _XpResultCard({
    required this.isGuest,
    required this.isLoading,
    required this.xpEarned,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) return _GuestXpCard(onCreateAccount: onCreateAccount);
    if (isLoading || xpEarned == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: AppColors.green, strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (xpEarned! == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blueLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.blue.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.blue, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(AppLocalizations.of(context).videoAlreadyWatched,
                  style: GoogleFonts.nunito(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
              Text(AppLocalizations.of(context).videoAlreadyEarned,
                  style: GoogleFonts.nunito(
                      color: AppColors.blue.withValues(alpha: 0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF46A302)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        const Text('🎉', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).videoComplete,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context).contentCompleteBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).contentXpEarned(xpEarned!),
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ]),
        ),
      ]),
    );
  }
}

class _GuestXpCard extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestXpCard({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF5AB4F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: [
        const Icon(Icons.lock_open_rounded, color: Colors.white, size: 32),
        const SizedBox(height: 10),
        Text(AppLocalizations.of(context).videoGuestTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
            AppLocalizations.of(context).videoGuestBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onCreateAccount,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueDark.withValues(alpha: 0.4),
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(AppLocalizations.of(context).quizResultCreateAccount,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─── Video placeholder ────────────────────────────────────────────────────────

class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.play_circle_outline_rounded,
            color: Colors.white.withValues(alpha: 0.5), size: 72),
      ),
    );
  }
}
