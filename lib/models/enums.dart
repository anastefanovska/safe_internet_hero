enum QuestionType { multipleChoice, trueFalse }

enum DifficultyLevel { beginner, intermediate, advanced }

enum AgeGroup { kids, tweens, teens }

/// Tracks a user's moderator-application state. Mirrors the request doc in the
/// `moderator_requests` collection; `none` is the default for everyone.
enum ModeratorStatus { none, pending, approved, rejected }

extension ModeratorStatusExtension on ModeratorStatus {
  static ModeratorStatus fromString(String value) {
    return ModeratorStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ModeratorStatus.none,
    );
  }
}

/// Review state of a quiz question. Legacy questions have no `status` field, so
/// they default to [approved] and stay visible to learners.
enum QuestionStatus { pending, approved, rejected }

extension QuestionStatusExtension on QuestionStatus {
  static QuestionStatus fromString(String value) {
    return QuestionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionStatus.approved,
    );
  }
}

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.kids:
        return 'Kids (6–9)';
      case AgeGroup.tweens:
        return 'Tweens (10–13)';
      case AgeGroup.teens:
        return 'Teens (14+)';
    }
  }

  static AgeGroup fromString(String value) {
    return AgeGroup.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AgeGroup.kids,
    );
  }
}