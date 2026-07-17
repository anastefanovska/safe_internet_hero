import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/haptic_service.dart';
import '../../services/shop_service.dart';
import '../../services/sound_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Tracks which item is currently being purchased.
  // Other items stay fully interactive while one is loading.
  final Set<String> _loadingIds = {};

  Future<void> _buy(String itemId) async {
    if (_loadingIds.contains(itemId)) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() => _loadingIds.add(itemId));

    final shop = ShopService();
    bool success = false;

    switch (itemId) {
      case 'streak_freeze':
        success = await shop.buyStreakFreeze(user.id);
      case 'xp_boost':
        success = await shop.buyXpBoost(user.id);
      case 'gold_frame':
        success = await shop.buyGoldFrame(user.id);
    }

    await auth.refreshUser();
    if (!mounted) return;
    setState(() => _loadingIds.remove(itemId));

    if (success) {
      SoundService.instance.playPurchase();
      HapticService.instance.success();
    } else {
      HapticService.instance.error();
    }

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.shopPurchased : l10n.shopNotEnoughCoins,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        backgroundColor: success ? AppColors.green : AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final coins = user?.coins ?? 0;

    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header shown on mobile only (desktop uses the rail + side panel).
          if (!desktop)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  stars: user?.totalStars ?? 0,
                  streak: user?.currentStreak ?? 0,
                  coins: coins,
                ),
                if (!desktop) Container(height: 1, color: AppColors.border),
                TabHeader(
                  title: l10n.navShop,
                  subtitle: l10n.shopSubtitle,
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
              child: isGuest
                  ? _GuestPrompt()
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: kContentMaxWidth),
                              child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                      children: [
                        // Power-Ups section
                        _SectionLabel(l10n.shopPowerUps),
                        const SizedBox(height: 12),

                        _ShopItemCard(
                          icon: Icons.ac_unit_rounded,
                          iconColor: AppColors.blue,
                          name: l10n.shopStreakFreeze,
                          description: l10n.shopStreakFreezeDesc,
                          price: 10,
                          userCoins: coins,
                          tag: user != null && user.streakFreezeCount > 0
                              ? '${user.streakFreezeCount}/2'
                              : null,
                          tagColor: AppColors.blue,
                          canBuy: (user?.streakFreezeCount ?? 0) < 2,
                          loading: _loadingIds.contains('streak_freeze'),
                          onBuy: () => _buy('streak_freeze'),
                        ).animate(delay: 80.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),

                        const SizedBox(height: 12),

                        _ShopItemCard(
                          icon: Icons.electric_bolt_rounded,
                          iconColor: AppColors.gold,
                          name: l10n.shopXpBoost,
                          description: l10n.shopXpBoostDesc,
                          price: 25,
                          userCoins: coins,
                          tag: (user?.xpBoostActive ?? false) ? l10n.shopTagActive : null,
                          tagColor: AppColors.orange,
                          canBuy: !(user?.xpBoostActive ?? false),
                          loading: _loadingIds.contains('xp_boost'),
                          onBuy: () => _buy('xp_boost'),
                        ).animate(delay: 140.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),

                        const SizedBox(height: 28),

                        // Cosmetics section
                        _SectionLabel(l10n.shopCosmetics),
                        const SizedBox(height: 12),

                        _ShopItemCard(
                          icon: Icons.circle_rounded,
                          iconColor: AppColors.gold,
                          name: l10n.shopGoldFrame,
                          description: l10n.shopGoldFrameDesc,
                          price: 50,
                          userCoins: coins,
                          tag: (user?.hasGoldFrame ?? false) ? l10n.shopTagOwned : null,
                          tagColor: AppColors.green,
                          canBuy: !(user?.hasGoldFrame ?? false),
                          loading: _loadingIds.contains('gold_frame'),
                          onBuy: () => _buy('gold_frame'),
                          preview: (user?.hasGoldFrame ?? false)
                              ? null
                              : AppAvatar(
                                  name: user?.username ?? l10n.commonYou,
                                  size: 42,
                                  goldFrame: true,
                                ),
                        ).animate(delay: 200.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0),
                      ],
                    ),
                            ),
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

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

// ─── Shop item card ───────────────────────────────────────────────────────────

class _ShopItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;
  final int price;
  final int userCoins;
  final String? tag;
  final Color? tagColor;
  final bool canBuy;
  final bool loading;
  final VoidCallback onBuy;
  final Widget? preview;

  const _ShopItemCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.price,
    required this.userCoins,
    this.tag,
    this.tagColor,
    required this.canBuy,
    required this.loading,
    required this.onBuy,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = userCoins >= price;
    final actionable = canBuy && canAfford && !loading;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              (tagColor ?? AppColors.blue).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag!,
                          style: GoogleFonts.nunito(
                            color: tagColor ?? AppColors.blue,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Preview or buy button column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (preview != null) ...[
                preview!,
                const SizedBox(height: 6),
              ],
              _BuyButton(
                price: price,
                canBuy: canBuy,
                canAfford: canAfford,
                loading: loading,
                onTap: actionable ? onBuy : null,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Buy button ───────────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  final int price;
  final bool canBuy;
  final bool canAfford;
  final bool loading;
  final VoidCallback? onTap;

  const _BuyButton({
    required this.price,
    required this.canBuy,
    required this.canAfford,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owned = !canBuy;
    final disabled = owned || !canAfford;

    final Color bgColor = loading
        ? AppColors.blue.withValues(alpha: 0.6)
        : owned
            ? AppColors.green.withValues(alpha: 0.15)
            : disabled
                ? AppColors.border
                : AppColors.blue;

    final Color contentColor = owned
        ? AppColors.greenDark
        : disabled && !loading
            ? AppColors.textSecondary
            : Colors.white;

    Widget content;
    if (loading) {
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    } else if (owned) {
      content = Text(
        AppLocalizations.of(context).shopTagOwned,
        style: GoogleFonts.nunito(
          color: contentColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_rounded, color: contentColor, size: 13),
          const SizedBox(width: 3),
          Text(
            '$price',
            style: GoogleFonts.nunito(
              color: contentColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      cursor: (loading || onTap == null)
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: owned
              ? Border.all(
                  color: AppColors.green.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: content,
      ),
      ),
    );
  }
}

// ─── Guest prompt ─────────────────────────────────────────────────────────────

class _GuestPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ghostItems = [
      (Icons.ac_unit_rounded, AppColors.blue, l10n.shopStreakFreeze, 10),
      (Icons.electric_bolt_rounded, AppColors.gold, l10n.shopXpBoost, 25),
      (Icons.circle_rounded, AppColors.gold, l10n.shopGoldFrame, 50),
    ];
    return Column(
      children: [
        // ── SVG on top ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
          child: SvgPicture.asset('assets/images/store_guest.svg', height: 110),
        ),

        // ── Ghost cards + fade + CTA ──────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    children: ghostItems.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return Opacity(
                        opacity: (1.0 - i * 0.22).clamp(0.15, 0.75),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: AppColors.border, width: 1.5),
                          ),
                          child: Row(children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: item.$2.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(item.$1, color: item.$2, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.$3,
                                      style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: 9, width: 130,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.orangeDark
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monetization_on_rounded,
                                        color: AppColors.orangeDark, size: 13),
                                    const SizedBox(width: 3),
                                    Text('${item.$4}',
                                        style: GoogleFonts.nunito(
                                            color: AppColors.orangeDark,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13)),
                                  ]),
                            ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.28, 0.62, 1.0],
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
                      Text(l10n.shopGuestTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        l10n.shopGuestSubtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GuestCTAButton(
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          AppPageRoute(builder: (_) => const LandingScreen()),
                          (r) => false,
                        ),
                      ),
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
