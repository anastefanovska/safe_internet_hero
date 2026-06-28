import 'enums.dart';

class QuestionModel {
  final String id;
  final String categoryId;
  final String topicId;
  final String text;
  final QuestionType type;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final DifficultyLevel difficulty;
  final int points;

  /// Review state. Legacy questions have no `status` field and default to
  /// [QuestionStatus.approved] so they remain visible to learners.
  final QuestionStatus status;

  /// uid of whoever authored the question (admin or moderator submission).
  final String authorId;

  /// uid of the admin who approved/rejected a moderator submission.
  final String reviewedBy;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.topicId,
    required this.text,
    required this.type,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.points,
    this.status = QuestionStatus.approved,
    this.authorId = '',
    this.reviewedBy = '',
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      topicId: map['topicId'] ?? '',
      text: map['text'] ?? '',
      type: QuestionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      points: map['points'] ?? 10,
      status:
          QuestionStatusExtension.fromString(map['status'] ?? 'approved'),
      authorId: map['authorId'] ?? '',
      reviewedBy: map['reviewedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'topicId': topicId,
      'text': text,
      'type': type.name,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'points': points,
      'status': status.name,
      'authorId': authorId,
      'reviewedBy': reviewedBy,
    };
  }
}