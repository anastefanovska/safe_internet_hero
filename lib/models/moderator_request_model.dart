import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// A user's application to become a moderator. Document id == the user's uid, so
/// there is exactly one request per user and re-requesting overwrites it.
class ModeratorRequestModel {
  final String id; // == userId
  final String userId;
  final String username;
  final ModeratorStatus status;
  final String reviewedBy; // admin uid who approved/rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;

  ModeratorRequestModel({
    required this.id,
    required this.userId,
    required this.username,
    this.status = ModeratorStatus.pending,
    this.reviewedBy = '',
    required this.createdAt,
    this.reviewedAt,
  });

  factory ModeratorRequestModel.fromMap(Map<String, dynamic> map) {
    return ModeratorRequestModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      status:
          ModeratorStatusExtension.fromString(map['status'] ?? 'pending'),
      reviewedBy: map['reviewedBy'] ?? '',
      createdAt: _toDateTime(map['createdAt']),
      reviewedAt: _toDateTimeOrNull(map['reviewedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'status': status.name,
      'reviewedBy': reviewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
