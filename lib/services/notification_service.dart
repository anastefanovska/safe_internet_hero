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

  Future<void> markRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  Future<void> dismiss(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }
}
