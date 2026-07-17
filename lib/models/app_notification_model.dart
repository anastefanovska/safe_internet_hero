import 'package:cloud_firestore/cloud_firestore.dart';

/// A lightweight in-app notification delivered to a single user. Created by
/// admins (e.g. on a moderator-request or submission decision) and read by the
/// owner. Stored in the `notifications` collection with an auto id.
class AppNotificationModel {
  final String id;
  final String userId;
  final String type; // e.g. mod_request_approved, submission_rejected
  final String title;
  final String body;

  /// The variable part of a notification (e.g. a reviewer's reason), stored
  /// separately so the UI can render a localized template around it at read
  /// time — the reader always sees their own language regardless of the
  /// admin's. Empty when the type has no variable content. [title]/[body] stay
  /// as an English fallback for legacy/unknown types.
  final String reason;

  final bool read;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.reason = '',
    this.read = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      reason: map['reason'] ?? '',
      read: map['read'] ?? false,
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'reason': reason,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
