import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/app_notification_model.dart';
import '../../models/moderator_request_model.dart';
import '../../models/question_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../services/moderator_service.dart';
import '../../services/notification_service.dart';
import '../../services/questions_service.dart';
import '../admin/manage_moderators_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Clear the unread badge as soon as the user opens the screen.
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      NotificationService().markAllRead(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      // The bell pushes this screen as a route on every layout,
                      // so always offer a way back when one exists.
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).settingsNotifications,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Balance the leading arrow so the title stays centered.
                      if (Navigator.of(context).canPop())
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: user == null
                    ? const _EmptyState()
                    : StreamBuilder<List<AppNotificationModel>>(
                        stream: NotificationService().watchForUser(user.id),
                        builder: (context, snap) {
                          final notifs = snap.data ?? const [];
                          final friendReqs = user.friendRequests;
                          final isAdmin = user.isAdmin == true;
                          // Admins are the deciders, so no notification doc ever
                          // targets them — their "feed" is the live review queue.
                          if (notifs.isEmpty && friendReqs.isEmpty && !isAdmin) {
                            return const _EmptyState();
                          }
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (isAdmin) const _AdminQueueSection(),
                              ...notifs.map((n) => _NotificationCard(
                                  notification: n)),
                              ...friendReqs.map((fromId) =>
                                  _FriendRequestTile(fromId: fromId)),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_rounded,
                color: AppColors.teal, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).notifNone,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).notifNoneBody,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Admin-only live "Review queue": tappable cards for pending moderator
/// requests and pending question submissions, each opening the moderators
/// screen on the right tab. Computed from streams admins can already read, so
/// no notification docs (or rule changes) are needed.
class _AdminQueueSection extends StatelessWidget {
  const _AdminQueueSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ModeratorRequestModel>>(
      stream: ModeratorService().watchPendingRequests(),
      builder: (context, reqSnap) {
        final reqCount = reqSnap.data?.length ?? 0;
        return StreamBuilder<List<QuestionModel>>(
          stream: QuestionService().watchPendingSubmissions(),
          builder: (context, subSnap) {
            final subCount = subSnap.data?.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 2),
                  child: Text(AppLocalizations.of(context).notifReviewQueue,
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8)),
                ),
                if (reqCount == 0 && subCount == 0)
                  _QueueCard(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.green,
                    title: AppLocalizations.of(context).notifAllCaughtUp,
                    subtitle: AppLocalizations.of(context).notifAllCaughtUpBody,
                    onTap: null,
                  )
                else ...[
                  if (reqCount > 0)
                    _QueueCard(
                      icon: Icons.how_to_reg_rounded,
                      color: AppColors.blue,
                      title: AppLocalizations.of(context).notifModeratorRequests(reqCount),
                      subtitle: AppLocalizations.of(context).notifTapRequestsTab,
                      onTap: () => _open(context, 0),
                    ),
                  if (subCount > 0)
                    _QueueCard(
                      icon: Icons.inbox_rounded,
                      color: AppColors.orange,
                      title: AppLocalizations.of(context).notifQuestionSubmissions(subCount),
                      subtitle: AppLocalizations.of(context).notifTapSubmissionsTab,
                      onTap: () => _open(context, 1),
                    ),
                ],
                const SizedBox(height: 6),
              ],
            );
          },
        );
      },
    );
  }

  void _open(BuildContext context, int tab) => Navigator.push(
        context,
        AppPageRoute(
            builder: (_) => ManageModeratorsScreen(initialTab: tab)),
      );
}

class _QueueCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _QueueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 22),
        ]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  const _NotificationCard({required this.notification});

  /// Picks an accent + icon from the notification type.
  (Color, IconData) get _accent {
    final t = notification.type;
    if (t.contains('approved')) return (AppColors.green, Icons.check_circle_rounded);
    if (t.contains('rejected') || t.contains('revoked')) {
      return (AppColors.orange, Icons.info_rounded);
    }
    return (AppColors.blue, Icons.notifications_rounded);
  }

  /// Localized title for a known notification type; the stored (English) title
  /// is a fallback for legacy/unknown types.
  String _title(AppLocalizations l10n) => switch (notification.type) {
        'mod_request_approved' => l10n.notifModApprovedTitle,
        'mod_request_rejected' => l10n.notifModRejectedTitle,
        'mod_revoked' => l10n.notifModRevokedTitle,
        'submission_approved' => l10n.notifSubApprovedTitle,
        'submission_changes' => l10n.notifSubChangesTitle,
        'submission_rejected' => l10n.notifSubRejectedTitle,
        _ => notification.title,
      };

  /// Localized body, weaving in the admin's [reason] (content) where the type
  /// has one. Falls back to the stored (English) body for unknown types.
  String _body(AppLocalizations l10n) {
    final reason = notification.reason.trim();
    final note = reason.isEmpty ? '' : l10n.notifReasonNote(reason);
    return switch (notification.type) {
      'mod_request_approved' => l10n.notifModApprovedBody,
      'mod_request_rejected' => l10n.notifModRejectedBody(note),
      'mod_revoked' => l10n.notifModRevokedBody,
      'submission_approved' => l10n.notifSubApprovedBody,
      'submission_changes' => l10n.notifSubChangesBody(reason),
      'submission_rejected' => l10n.notifSubRejectedBody(note),
      _ => notification.body,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, icon) = _accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(l10n),
                    style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(_body(l10n),
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35)),
                const SizedBox(height: 4),
                Text(timeAgo(notification.createdAt),
                    style: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textLight, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => NotificationService().dismiss(notification.id),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  final String fromId;
  const _FriendRequestTile({required this.fromId});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final friendService = FriendService();
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(fromId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final username = data?['username'] ?? AppLocalizations.of(context).leaderboardUnknown;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                child: Text(
                  username[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppLocalizations.of(context).notifSentRequest,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded,
                    color: AppColors.correct, size: 28),
                onPressed: () async {
                  if (user == null) return;
                  await friendService.acceptFriendRequest(user.id, fromId);
                  await auth.refreshUser();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AppLocalizations.of(context).notifNowFriends(username)),
                      backgroundColor: AppColors.correct,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded,
                    color: AppColors.wrong, size: 28),
                onPressed: () async {
                  if (user == null) return;
                  await friendService.declineFriendRequest(user.id, fromId);
                  await auth.refreshUser();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
