import 'package:cloud_firestore/cloud_firestore.dart';

/// The kind of goal a daily challenge tracks. Not persisted directly — it lives
/// on the code-defined [DailyChallengeTemplate]; the stored progress doc only
/// keeps the template's stable [DailyChallengeTemplate.id].
enum DailyChallengeType {
  answerQuestions,
  threeStarQuiz,
  answerInCategory,
  practiceWeakSpots,
}

/// One challenge definition from the fixed pool. A single template is chosen
/// deterministically per calendar day by `DailyChallengeService`. `id` is stable
/// so persisted progress always maps back to the right template.
class DailyChallengeTemplate {
  final String id;
  final DailyChallengeType type;
  final String title;
  final int target;
  final int coinReward;

  /// Only set for [DailyChallengeType.answerInCategory] — the category slug the
  /// answered questions must belong to, plus its display name.
  final String? categoryId;
  final String? categoryName;

  const DailyChallengeTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.target,
    required this.coinReward,
    this.categoryId,
    this.categoryName,
  });
}

/// A user's progress on their challenge for a single calendar day.
/// Doc id = `${userId}_${date}` where date is `yyyy-MM-dd` in local time, so a
/// new day naturally starts a fresh doc at midnight.
class DailyChallengeModel {
  final String id;
  final String userId;
  final String challengeId;
  final String date; // yyyy-MM-dd (local)
  final int progress;
  final bool claimed;

  DailyChallengeModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.date,
    this.progress = 0,
    this.claimed = false,
  });

  factory DailyChallengeModel.fromMap(Map<String, dynamic> map) {
    return DailyChallengeModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      challengeId: map['challengeId'] ?? '',
      date: map['date'] ?? '',
      progress: map['progress'] ?? 0,
      claimed: map['claimed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'challengeId': challengeId,
      'date': date,
      'progress': progress,
      'claimed': claimed,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
