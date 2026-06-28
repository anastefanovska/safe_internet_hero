import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/app_notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final desktop = isDesktop(context);

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
                      if (!desktop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!desktop) const SizedBox(width: 48),
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
                          if (notifs.isEmpty && friendReqs.isEmpty) {
                            return const _EmptyState();
                          }
                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
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
          const Text(
            'No notifications',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Updates and friend requests will appear here',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
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
                Text(notification.title,
                    style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(notification.body,
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35)),
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
        final username = data?['username'] ?? 'Unknown';

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
                    const Text(
                      'Sent you a friend request',
                      style: TextStyle(
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
                          Text('You and $username are now friends!'),
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
