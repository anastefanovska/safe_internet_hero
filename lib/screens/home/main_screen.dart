import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../auth/splash_screen.dart';
import '../profile/settings_screen.dart';
import 'home_screen.dart';
import '../learn/learn_screen.dart';
import '../games/games_screen.dart';
import '../shop/shop_screen.dart';
import '../social/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _screens = [
    HomeScreen(),
    LearnScreen(),
    GamesScreen(),
    ShopScreen(),
    LeaderboardScreen(),
    ProfileScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    if (desktop) {
      final isGuest = context.watch<AuthProvider>().isGuest;
      // Guests have no "More" menu, so it can never be the active panel.
      final showMore = _showMore && !isGuest;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DesktopRail(
              currentIndex: _currentIndex,
              showMore: showMore,
              showMoreButton: !isGuest,
              onTap: (i) => setState(() {
                _currentIndex = i;
                _showMore = false;
              }),
              onMore: () => setState(() => _showMore = !_showMore),
            ),
            Container(width: 1, color: AppColors.border),
            // Scrollable center content — takes the remaining width.
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            // Right sidebar — a solid panel mirroring the left rail.
            Container(width: 1, color: AppColors.border),
            Container(
              width: kDesktopPanelWidth,
              color: Colors.white,
              child: _DesktopSidePanel(currentIndex: _currentIndex),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _DuolingoBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Desktop navigation rail ──────────────────────────────────────────────────

class _DesktopRail extends StatelessWidget {
  final int currentIndex;
  final bool showMore;
  final bool showMoreButton;
  final ValueChanged<int> onTap;
  final VoidCallback onMore;
  const _DesktopRail({
    required this.currentIndex,
    required this.showMore,
    required this.showMoreButton,
    required this.onTap,
    required this.onMore,
  });

  static const _items = [
    (svg: 'assets/images/home.svg', label: 'Home'),
    (svg: 'assets/images/learn.svg', label: 'Learn'),
    (svg: 'assets/images/games.svg', label: 'Games'),
    (svg: 'assets/images/store.svg', label: 'Shop'),
    (svg: 'assets/images/leaderboard.svg', label: 'Leaderboard'),
    (svg: 'assets/images/profile.svg', label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 216,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/mascot.svg',
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Safe Internet\nHero',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...List.generate(_items.length, (i) => _RailItem(
                    svgPath: _items[i].svg,
                    label: _items[i].label,
                    // The active tab keeps its outline even while the More
                    // panel is open — More is just a toggle, not a tab.
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  )),
              // "More" sits directly under Profile; hidden for guests. It never
              // takes the active outline; tapping it just toggles its actions.
              if (showMoreButton)
                _RailItem(
                  svgPath: 'assets/images/more.svg',
                  label: 'More',
                  selected: false,
                  onTap: onMore,
                ),
              // Tapping More expands its actions inline in the rail.
              if (showMoreButton && showMore) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _MoreOption(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _MoreOption(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AuthProvider>().logout();
                      navigator.pushAndRemoveUntil(
                        AppPageRoute(builder: (_) => const AuthGate()),
                        (r) => false,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── "More" action (Settings / Log out shown inline in the rail) ──────────────

class _MoreOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MoreOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MoreOption> createState() => _MoreOptionState();
}

class _MoreOptionState extends State<_MoreOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        // Plain Container for instant hover (see _RailItem) — no fade trail.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final String svgPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({
    required this.svgPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // Crisp hover: a plain Container so the background tracks the cursor
        // instantly. An AnimatedContainer would leave the item you're leaving
        // mid-fade while the next one fades in, showing two greyed items at once.
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.blueLight
                : _hovered
                    ? AppColors.background
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: widget.selected
                ? Border.all(
                    color: AppColors.blue.withValues(alpha: 0.25), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.svgPath,
                width: 26,
                height: 26,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  color: widget.selected
                      ? AppColors.blue
                      : AppColors.textSecondary,
                  fontWeight: widget.selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile bottom navigation ─────────────────────────────────────────────────

class _DuolingoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DuolingoBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _svgPaths = [
    'assets/images/home.svg',
    'assets/images/learn.svg',
    'assets/images/games.svg',
    'assets/images/store.svg',
    'assets/images/leaderboard.svg',
    'assets/images/profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(_svgPaths.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        // Tighter horizontal padding so all six tabs fit without
                        // overflowing on narrow phones.
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(color: AppColors.blue, width: 2)
                              : null,
                        ),
                        child: SvgPicture.asset(
                          _svgPaths[i],
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop side panel ───────────────────────────────────────────────────────

class _DesktopSidePanel extends StatelessWidget {
  final int currentIndex;
  const _DesktopSidePanel({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    // Guests have no progress to show — invite them to create a profile
    // or sign in instead (Duolingo-style).
    if (isGuest || user == null) {
      return const _GuestSidePanel();
    }

    // The Profile tab already shows stats in the centre, so show friends
    // here instead — otherwise both sides repeat the same stats.
    if (currentIndex == 5) {
      return _ProfileSidePanel(user: user, auth: auth);
    }

    return _StatsSidePanel(user: user);
  }
}

// ─── Stats side panel ─────────────────────────────────────────────────────────

class _StatsSidePanel extends StatelessWidget {
  final UserModel user;
  const _StatsSidePanel({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SidePanelScroll(
      children: [
        // ── Stats box ─────────────────────────────────────────────
        _PanelBox(
          label: 'YOUR STATS',
          child: Column(
            children: [
              _StatRow(
                icon: Icons.local_fire_department_rounded,
                color: user.currentStreak > 0
                    ? AppColors.orange
                    : AppColors.textLight,
                label: 'Day Streak',
                value: '${user.currentStreak}',
              ),
              const SizedBox(height: 16),
              _StatRow(
                icon: Icons.star_rounded,
                color: AppColors.gold,
                label: 'Total Stars',
                value: '${user.totalStars}',
              ),
              const SizedBox(height: 16),
              _StatRow(
                icon: Icons.monetization_on_rounded,
                color: AppColors.orangeDark,
                label: 'Coins',
                value: '${user.coins}',
              ),
            ],
          ),
        ),

        // ── Active boosts box ─────────────────────────────────────
        if (user.xpBoostActive || user.streakFreezeCount > 0) ...[
          const SizedBox(height: 14),
          _PanelBox(
            label: 'ACTIVE BOOSTS',
            child: Column(
              children: [
                if (user.xpBoostActive) ...[
                  const _BoostBanner(),
                  if (user.streakFreezeCount > 0) const SizedBox(height: 10),
                ],
                if (user.streakFreezeCount > 0)
                  _FreezeBanner(count: user.streakFreezeCount),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Profile side panel (friends) ──────────────────────────────────────────────

class _ProfileSidePanel extends StatelessWidget {
  final UserModel user;
  final AuthProvider auth;
  const _ProfileSidePanel({required this.user, required this.auth});

  @override
  Widget build(BuildContext context) {
    return _SidePanelScroll(
      children: [ProfileFriendsSection(user: user, auth: auth)],
    );
  }
}

// ─── Side-panel scroll wrapper (centres content, scrolls when it overflows) ────

class _SidePanelScroll extends StatelessWidget {
  final List<Widget> children;
  const _SidePanelScroll({required this.children});

  static const _padding = EdgeInsets.fromLTRB(16, 24, 20, 24);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: SingleChildScrollView(
        padding: _padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

// ─── Panel section (label + content, no box — sits on the sidebar) ─────────────

class _PanelBox extends StatelessWidget {
  final String label;
  final Widget child;
  const _PanelBox({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ─── Guest side panel ─────────────────────────────────────────────────────────

class _GuestSidePanel extends StatelessWidget {
  const _GuestSidePanel();

  @override
  Widget build(BuildContext context) {
    return _SidePanelScroll(
      children: [
            // ── Create-profile CTA ────────────────────────────────────
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a profile to save your progress!',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'CREATE A PROFILE',
                    variant: AppButtonVariant.success,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'SIGN IN',
                    variant: AppButtonVariant.primary,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

// ─── Stat row (used inside the stats box) ──────────────────────────────────────

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
  }
}

// ─── Boost banners ────────────────────────────────────────────────────────────

class _BoostBanner extends StatelessWidget {
  const _BoostBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.15),
            AppColors.orange.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XP Boost Active',
                  style: GoogleFonts.nunito(
                    color: AppColors.orangeDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '2× stars on quizzes',
                  style: GoogleFonts.nunito(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _FreezeBanner extends StatelessWidget {
  final int count;
  const _FreezeBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.ac_unit_rounded,
                color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Streak Freeze${count > 1 ? 's' : ''}',
                  style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Your streak is protected',
                  style: GoogleFonts.nunito(
                    color: AppColors.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
