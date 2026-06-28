import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification_model.dart';

/// Reads and dismisses in-app notifications for the current user. Notifications
/// are *created* by admins inside [ModeratorService] batches — never here.
class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// A user's notifications, newest first (sorted in Dart to avoid an index).
  Stream<List<AppNotificationModel>> watchForUser(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => AppNotificationModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Live count of the user's unread notifications, for the bell badge.
  /// Filtered in Dart so no `userId + read` composite index is needed.
  Stream<int> watchUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.where((d) => d.data()['read'] != true).length);
  }

  Future<void> markRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  /// Marks every unread notification for [userId] as read — called when the
  /// notifications screen is opened so the badge clears. One batch, owner-write.
  Future<void> markAllRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    final unread = snap.docs.where((d) => d.data()['read'] != true).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> dismiss(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }
}
