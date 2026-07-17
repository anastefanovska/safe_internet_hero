import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import '../auth/splash_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<int>? _rankFuture;
  int? _lastStars;

  Future<int> _computeUserRank(int userStars) async {
    try {
      // Fetch users with more stars and filter admins client-side.
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('totalStars', isGreaterThan: userStars)
          .get();
      final nonAdminCount = snap.docs
          .where((d) => (d.data())['isAdmin'] != true)
          .length;
      return nonAdminCount + 1;
    } catch (_) {
      return 0;
    }
  }

  void _maybeRefreshRank(int stars) {
    if (stars != _lastStars) {
      _lastStars = stars;
      setState(() {
        _rankFuture = _computeUserRank(stars);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;
    final isGuest = auth.isGuest;
    final stars = currentUser?.totalStars ?? 0;
    final streak = currentUser?.currentStreak ?? 0;
    final coins = currentUser?.coins ?? 0;
    if (!isGuest && currentUser != null) {
      _maybeRefreshRank(stars);
    }

    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header (mobile only — desktop uses the rail + side panel) ─────
          if (!desktop)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(stars: stars, streak: streak, coins: coins),
                if (!desktop) Container(height: 1, color: AppColors.border),
                TabHeader(
                  title: AppLocalizations.of(context).navLeaderboard,
                  subtitle: AppLocalizations.of(context).leaderboardSubtitle,
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          if (isGuest)
            Expanded(
              child: GuestLockedState(
                svgAsset: 'assets/images/leaderboard.svg',
                title: AppLocalizations.of(context).leaderboardGuestTitle,
                subtitle: AppLocalizations.of(context).leaderboardGuestSubtitle,
                onGetStarted: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                ),
              ),
            ),

          if (!isGuest)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                          child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // ── League banner ──────────────────────────────────────
                    if (currentUser != null)
                      _LeagueBanner(stars: stars)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.08, end: 0, duration: 350.ms),
                    if (currentUser != null) const SizedBox(height: 16),

                    // ── Podium ─────────────────────────────────────────────
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('totalStars', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const LeaderboardPodiumSkeleton();
                        }
                        final docs = snap.data!.docs
                            .where((d) =>
                                (d.data() as Map<String, dynamic>)['isAdmin'] != true)
                            .take(3)
                            .toList();
                        return _Podium(docs: docs, currentUser: currentUser)
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 500))
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Your Rank card ─────────────────────────────────────
                    if (currentUser != null)
                      FutureBuilder<int>(
                        future: _rankFuture,
                        builder: (context, snap) {
                          return _YourRankCard(
                            user: currentUser,
                            rank: snap.data,
                            loading: snap.connectionState ==
                                ConnectionState.waiting,
                          )
                              .animate()
                              .fadeIn(
                                  delay: const Duration(milliseconds: 200),
                                  duration: const Duration(milliseconds: 400))
                              .slideY(
                                  begin: 0.08,
                                  end: 0,
                                  duration: const Duration(milliseconds: 350));
                        },
                      ),

                    const SizedBox(height: 20),

                    // ── Top 50 list ────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context).leaderboardTop50,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('totalStars', descending: true)
                          .limit(60)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Column(
                            children: List.generate(
                                8, (_) => const LeaderboardRowSkeleton()),
                          );
                        }
                        final users = snap.data!.docs
                            .where((d) =>
                                (d.data() as Map<String, dynamic>)['isAdmin'] != true)
                            .take(50)
                            .toList();
                        return Column(
                          children: users.asMap().entries.map((e) {
                            final index = e.key;
                            final data =
                                e.value.data() as Map<String, dynamic>;
                            final isMe = data['uid'] == currentUser?.id;

                            return _LeaderboardRow(
                              rank: index + 1,
                              username: data['username'] ?? AppLocalizations.of(context).leaderboardUnknown,
                              stars: data['totalStars'] ?? 0,
                              isMe: isMe,
                              hasGoldFrame: (data['hasGoldFrame'] as bool?) ?? false,
                            )
                                .animate(
                                    delay: Duration(
                                        milliseconds:
                                            (index * 40).clamp(0, 400)))
                                .fadeIn(
                                    duration:
                                        const Duration(milliseconds: 300))
                                .slideX(
                                    begin: 0.05,
                                    end: 0,
                                    duration:
                                        const Duration(milliseconds: 300));
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                    ),
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

// ─── Your Rank card ───────────────────────────────────────────────────────────

class _YourRankCard extends StatelessWidget {
  final UserModel user;
  final int? rank;
  final bool loading;

  const _YourRankCard({
    required this.user,
    required this.rank,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF5AB4F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(
            name: user.username,
            size: 44,
            goldFrame: user.hasGoldFrame,
            borderColor: user.hasGoldFrame ? null : Colors.white,
            borderWidth: 2.5,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${user.totalStars} stars',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Text(
                        rank != null && rank! > 0 ? '#$rank' : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).leaderboardYourRank,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
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

// ─── Podium ───────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<DocumentSnapshot> docs;
  final UserModel? currentUser;

  const _Podium({required this.docs, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.blueLight, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sparkly title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).leaderboardTopHeroes,
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.gold, size: 16),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (docs.length > 1)
                _PodiumSlot(
                  doc: docs[1],
                  rank: 2,
                  pillarHeight: 80,
                  color: const Color(0xFFB9C3CC),
                  shadowColor: const Color(0xFF8C99A6),
                  isMe: (docs[1].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 92),
              if (docs.isNotEmpty)
                _PodiumSlot(
                  doc: docs[0],
                  rank: 1,
                  pillarHeight: 118,
                  color: AppColors.gold,
                  shadowColor: AppColors.goldDark,
                  isMe: (docs[0].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 92),
              if (docs.length > 2)
                _PodiumSlot(
                  doc: docs[2],
                  rank: 3,
                  pillarHeight: 56,
                  color: const Color(0xFFD9925A),
                  shadowColor: const Color(0xFFA9663A),
                  isMe: (docs[2].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 92),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final DocumentSnapshot doc;
  final int rank;
  final double pillarHeight;
  final Color color;
  final Color shadowColor;
  final bool isMe;

  const _PodiumSlot({
    required this.doc,
    required this.rank,
    required this.pillarHeight,
    required this.color,
    required this.shadowColor,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final username = data['username'] ?? '?';
    final stars = data['totalStars'] ?? 0;
    final hasGoldFrame = (data['hasGoldFrame'] as bool?) ?? false;
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 58.0 : 46.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown floats above the champion
        if (isFirst)
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 30)
        else
          const SizedBox(height: 22),
        const SizedBox(height: 4),

        // Avatar with a glossy colored ring + rank medal badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, shadowColor],
                ),
                boxShadow: isFirst
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: AppAvatar(
                name: username,
                size: avatarSize,
                goldFrame: hasGoldFrame,
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: 88,
          child: Text(
            username,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: isMe ? AppColors.blue : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Glossy pillar with a shine highlight
        Container(
          width: 82,
          height: pillarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, shadowColor],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.55),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // shine strip
              Positioned(
                left: 12,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$rank',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: isFirst ? 28 : 22,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '$stars',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── List row ─────────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String username;
  final int stars;
  final bool isMe;
  final bool hasGoldFrame;

  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.stars,
    required this.isMe,
    this.hasGoldFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blueLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.blue : AppColors.border,
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Icon(
                    [
                      Icons.emoji_events_rounded,
                      Icons.military_tech_rounded,
                      Icons.workspace_premium_rounded,
                    ][rank - 1],
                    color: [
                      AppColors.gold,
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
                    ][rank - 1],
                    size: 22,
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          AppAvatar(name: username, size: 38, goldFrame: hasGoldFrame),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: isMe ? AppColors.blue : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.gold, size: 17),
              const SizedBox(width: 3),
              Text(
                '$stars',
                style: GoogleFonts.nunito(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─── League banner ────────────────────────────────────────────────────────────

typedef _League = ({
  String name,
  IconData icon,
  Color color,
  int floor,
  int? next,
});

_League _leagueFor(int stars) {
  if (stars >= 60) {
    return (
      name: 'Cyber Legend League',
      icon: Icons.emoji_events_rounded,
      color: AppColors.gold,
      floor: 60,
      next: null,
    );
  }
  if (stars >= 30) {
    return (
      name: 'Guardian League',
      icon: Icons.bolt_rounded,
      color: AppColors.orange,
      floor: 30,
      next: 60,
    );
  }
  if (stars >= 15) {
    return (
      name: 'Hero League',
      icon: Icons.shield_rounded,
      color: AppColors.blue,
      floor: 15,
      next: 30,
    );
  }
  if (stars >= 5) {
    return (
      name: 'Apprentice League',
      icon: Icons.school_rounded,
      color: AppColors.green,
      floor: 5,
      next: 15,
    );
  }
  return (
    name: 'Rookie League',
    icon: Icons.eco_rounded,
    color: AppColors.greenDark,
    floor: 0,
    next: 5,
  );
}

/// Localised league name for a star count (mirrors [_leagueFor]).
String _leagueName(int stars, AppLocalizations l10n) {
  if (stars >= 60) return l10n.leagueCyberLegend;
  if (stars >= 30) return l10n.leagueGuardian;
  if (stars >= 15) return l10n.leagueHero;
  if (stars >= 5) return l10n.leagueApprentice;
  return l10n.leagueRookie;
}

class _LeagueBanner extends StatelessWidget {
  final int stars;
  const _LeagueBanner({required this.stars});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final league = _leagueFor(stars);
    final color = league.color;
    final lighter = Color.lerp(color, Colors.white, 0.22)!;
    final hasNext = league.next != null;
    final span = hasNext ? (league.next! - league.floor) : 1;
    final progress =
        hasNext ? ((stars - league.floor) / span).clamp(0.0, 1.0) : 1.0;
    final remaining = hasNext ? (league.next! - stars) : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lighter, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Glowing league badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Icon(league.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _leagueName(stars, l10n),
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasNext
                          ? l10n.leagueStarsEarned(stars)
                          : l10n.leagueTopReached,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasNext) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                      height: 12, color: Colors.white.withValues(alpha: 0.3)),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(height: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.leagueLevelUp(remaining),
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
