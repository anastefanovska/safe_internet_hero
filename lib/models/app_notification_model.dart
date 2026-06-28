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
  final bool read;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
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
