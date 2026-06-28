import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_service.dart';
import '../../widgets/app_avatar.dart';
import '../auth/splash_screen.dart';

class ArticleScreen extends StatefulWidget {
  final LearningContentModel content;
  const ArticleScreen({super.key, required this.content});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _scrollController = ScrollController();
  final _learningService = LearningService();

  double _readProgress = 0;
  bool _completionTriggered = false;
  bool _completionVisible = false;
  bool _completionLoading = false;
  bool _completionError = false;
  int? _xpEarned;

  int get _xpAmount =>
      (widget.content.readTimeMinutes * 2).clamp(4, 20).toInt() == 0
          ? 5
          : (widget.content.readTimeMinutes * 2).clamp(4, 20);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 20) {
        Future.delayed(const Duration(seconds: 3), _triggerCompletion);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.005) {
      setState(() => _readProgress = progress);
    }
    if (progress >= 0.85) _triggerCompletion();
  }

  void _triggerCompletion() {
    if (_completionTriggered) return;
    _completionTriggered = true;
    _handleCompletion();
  }

  Future<void> _handleCompletion() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    setState(() => _completionVisible = true);
    if (auth.isGuest) return;
    final user = auth.user;
    if (user == null) return;
    setState(() => _completionLoading = true);
    try {
      final earned = await _learningService.markContentRead(
        userId: user.id,
        contentId: widget.content.id,
        xpToAward: _xpAmount,
      );
      if (!mounted) return;
      setState(() {
        _xpEarned = earned;
        _completionLoading = false;
      });
      if (earned > 0) auth.refreshUser();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completionLoading = false;
        _completionError = true;
      });
    }
  }

  // ── Content parsing ──────────────────────────────────────────────────────

  List<String> get _paragraphs => widget.content.content
      .split(RegExp(r'\n\n+'))
      .expand((block) => block
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty))
      .toList();

  List<String> get _keyPoints {
    final desc = widget.content.description.trim();
    if (desc.isEmpty) return [];
    return desc
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) => l.startsWith('- ') ? l.substring(2) : l)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthProvider>().isGuest;
    final accent = AppCategoryIcon.colorFor(widget.content.categoryId);
    final paras = _paragraphs;
    final keyPoints = _keyPoints;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Fixed top bar ──────────────────────────────────────────────
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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _readProgress),
                  duration: const Duration(milliseconds: 150),
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero card ──────────────────────────────────────────
                  _HeroCard(
                    title: widget.content.title,
                    categoryId: widget.content.categoryId,
                    readTimeMinutes: widget.content.readTimeMinutes,
                    accent: accent,
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
                        // ── Key Takeaways ──────────────────────────────
                        if (keyPoints.isNotEmpty) ...[
                          _KeyTakeawaysCard(
                            points: keyPoints,
                            accent: accent,
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  duration: 300.ms),
                          const SizedBox(height: 20),
                        ],

                        // ── Body paragraphs ────────────────────────────
                        ...paras.asMap().entries.map((e) {
                          final i = e.key;
                          final para = e.value;
                          return _ParagraphWidget(
                            text: para,
                            isFirst: i == 0,
                            accent: accent,
                          )
                              .animate(
                                  delay: Duration(
                                      milliseconds: 100 + i * 50))
                              .fadeIn(duration: 250.ms);
                        }),

                        const SizedBox(height: 32),

                        // ── Completion card ────────────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: _completionVisible
                              ? _CompletionCard(
                                  isGuest: isGuest,
                                  isLoading: _completionLoading,
                                  hasError: _completionError,
                                  onRetry: () {
                                    setState(() {
                                      _completionError = false;
                                      _completionLoading = true;
                                    });
                                    _handleCompletion();
                                  },
                                  xpEarned: _xpEarned,
                                  xpAmount: _xpAmount,
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
                                    .scale(
                                      begin: const Offset(0.92, 0.92),
                                      end: const Offset(1, 1),
                                      curve: Curves.elasticOut,
                                      duration: 600.ms,
                                    )
                                    .fadeIn(duration: 300.ms)
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

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String title;
  final String categoryId;
  final int readTimeMinutes;
  final Color accent;

  const _HeroCard({
    required this.title,
    required this.categoryId,
    required this.readTimeMinutes,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppCategoryIcon.iconFor(categoryId);
    final darkAccent = AppCategoryIcon.darkColorFor(categoryId);

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
          // Icon in a white circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
              icon: Icons.menu_book_rounded,
              label: 'article',
            ),
            if (readTimeMinutes > 0) ...[
              const SizedBox(width: 8),
              _HeroBadge(
                icon: Icons.access_time_rounded,
                label: '$readTimeMinutes MIN READ',
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

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
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.4), width: 1),
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

// ─── Key Takeaways card ───────────────────────────────────────────────────────

class _KeyTakeawaysCard extends StatelessWidget {
  final List<String> points;
  final Color accent;

  const _KeyTakeawaysCard(
      {required this.points, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lightbulb_rounded,
                  color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Key Takeaways',
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...points.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}

// ─── Paragraph widget ─────────────────────────────────────────────────────────
// Decides how each paragraph is displayed based on its content.

class _ParagraphWidget extends StatelessWidget {
  final String text;
  final bool isFirst;
  final Color accent;

  const _ParagraphWidget({
    required this.text,
    required this.isFirst,
    required this.accent,
  });

  static bool _isEmoji(String char) {
    final r = char.runes.firstOrNull;
    return r != null && r > 0x1F300;
  }

  static bool _isTip(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('tip:') ||
        lower.startsWith('note:') ||
        lower.startsWith('remember:') ||
        lower.startsWith('important:') ||
        lower.startsWith('warning:') ||
        (text.isNotEmpty && _isEmoji(text[0]));
  }

  static bool _isShortFact(String text) =>
      text.length <= 90 && !text.endsWith(':');

  @override
  Widget build(BuildContext context) {
    if (_isTip(text)) {
      return _TipBox(text: text, accent: accent);
    }
    if (!isFirst && _isShortFact(text)) {
      return _CalloutBox(text: text, accent: accent);
    }
    return _BodyParagraph(text: text, isFirst: isFirst);
  }
}

// Regular paragraph
class _BodyParagraph extends StatelessWidget {
  final String text;
  final bool isFirst;
  const _BodyParagraph({required this.text, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: isFirst ? 16 : 15,
          color: AppColors.textPrimary,
          height: 1.75,
          fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

// Short impactful sentence — shown as a callout with colored left border
class _CalloutBox extends StatelessWidget {
  final String text;
  final Color accent;
  const _CalloutBox({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(
          left: BorderSide(color: accent, width: 4),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }
}

// Tip / emoji paragraph — shown as a fun card with icon
class _TipBox extends StatelessWidget {
  final String text;
  final Color accent;
  const _TipBox({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.tips_and_updates_rounded,
              color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Completion card ──────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final bool isGuest;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final int? xpEarned;
  final int xpAmount;
  final VoidCallback onCreateAccount;

  const _CompletionCard({
    required this.isGuest,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.xpEarned,
    required this.xpAmount,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) return _GuestCard(onCreateAccount: onCreateAccount);
    if (isLoading) return _LoadingCard();
    if (hasError) return _ErrorCard(onRetry: onRetry);
    if (xpEarned == null) return _LoadingCard();
    if (xpEarned! == 0) return const _AlreadyReadCard();
    return _EarnedCard(xp: xpEarned!);
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.red.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 32),
        const SizedBox(height: 10),
        Text("Couldn't save your progress",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: AppColors.red,
                fontWeight: FontWeight.w900,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text('Check your connection and try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: AppColors.red.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Try again',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _EarnedCard extends StatelessWidget {
  final int xp;
  const _EarnedCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF46A302)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        const Text('🎉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Text('Article Complete!',
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Great job! Keep exploring to level up.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('+$xp XP earned',
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

class _AlreadyReadCard extends StatelessWidget {
  const _AlreadyReadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(20),
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Already completed',
                style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
            Text('You already earned XP for this article.',
                style: GoogleFonts.nunito(
                    color: AppColors.blue.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: AppColors.green, strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestCard({required this.onCreateAccount});

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
        Text('Want to earn XP for reading?',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
            'Create a free account to save your progress\nand earn XP for every article you read.',
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
            child: Text('Create Free Account',
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
