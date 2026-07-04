import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final AgeGroup ageGroup;
  final int totalStars;
  final int coins;
  final int currentStreak;
  final DateTime? lastActiveDate;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> friendRequests;
  final bool isAdmin;
  final bool isModerator;
  final ModeratorStatus moderatorStatus;
  final List<String> answeredQuestions;
  final List<String> incorrectlyAnsweredIds;
  final List<String> readContentIds;
  final int streakFreezeCount;
  final bool xpBoostActive;
  final bool hasGoldFrame;

  /// Best score per arcade mini-game, keyed by gameId (e.g. `spot_the_scam`).
  /// Drives the "high score to beat" in the arcade games. Owner-writable.
  final Map<String, int> miniGameHighScores;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.ageGroup,
    this.totalStars = 0,
    this.coins = 0,
    this.currentStreak = 0,
    this.lastActiveDate,
    required this.createdAt,
    this.friends = const [],
    this.friendRequests = const [],
    this.isAdmin = false,
    this.isModerator = false,
    this.moderatorStatus = ModeratorStatus.none,
    this.answeredQuestions = const [],
    this.incorrectlyAnsweredIds = const [],
    this.readContentIds = const [],
    this.streakFreezeCount = 0,
    this.xpBoostActive = false,
    this.hasGoldFrame = false,
    this.miniGameHighScores = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      ageGroup: AgeGroupExtension.fromString(map['ageGroup'] ?? 'kids'),
      totalStars: map['totalStars'] ?? 0,
      coins: map['coins'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      lastActiveDate: _toDateTimeNullable(map['lastActiveDate']),
      createdAt: _toDateTime(map['createdAt']),
      friends: List<String>.from(map['friends'] ?? []),
      friendRequests: List<String>.from(map['friendRequests'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      isModerator: map['isModerator'] ?? false,
      moderatorStatus:
          ModeratorStatusExtension.fromString(map['moderatorStatus'] ?? 'none'),
      answeredQuestions: List<String>.from(map['answeredQuestions'] ?? []),
      incorrectlyAnsweredIds:
          List<String>.from(map['incorrectlyAnsweredIds'] ?? []),
      readContentIds: List<String>.from(map['readContentIds'] ?? []),
      streakFreezeCount: map['streakFreezeCount'] ?? 0,
      xpBoostActive: map['xpBoostActive'] ?? false,
      hasGoldFrame: map['hasGoldFrame'] ?? false,
      miniGameHighScores: (map['miniGameHighScores'] as Map<dynamic, dynamic>?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
          const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'username': username,
      'ageGroup': ageGroup.name,
      'totalStars': totalStars,
      'coins': coins,
      'currentStreak': currentStreak,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'friends': friends,
      'friendRequests': friendRequests,
      'isAdmin': isAdmin,
      'isModerator': isModerator,
      'moderatorStatus': moderatorStatus.name,
      'answeredQuestions': answeredQuestions,
      'incorrectlyAnsweredIds': incorrectlyAnsweredIds,
      'readContentIds': readContentIds,
      'streakFreezeCount': streakFreezeCount,
      'xpBoostActive': xpBoostActive,
      'hasGoldFrame': hasGoldFrame,
      'miniGameHighScores': miniGameHighScores,
      'usernameLower': username.toLowerCase(),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _toDateTimeNullable(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
