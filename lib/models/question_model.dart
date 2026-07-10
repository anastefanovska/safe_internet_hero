import '../core/app_locale.dart';
import 'enums.dart';

/// Fields that `tool/translate_questions.dart` rewrites into `{en, mk}` maps.
const _translatableFields = ['text', 'options', 'explanation'];

/// Reads a field that is either a plain string (un-migrated doc) or a
/// `{en: ..., mk: ...}` map, falling back to English when the requested
/// language is missing or empty.
String _resolveString(dynamic raw, String lang) {
  if (raw is Map) {
    final value = raw[lang];
    if (value is String && value.isNotEmpty) return value;
    final fallback = raw['en'];
    return fallback is String ? fallback : '';
  }
  return raw is String ? raw : '';
}

/// As [_resolveString], for the `options` array. An empty translated array
/// falls back to English rather than rendering a question with no answers.
List<String> _resolveList(dynamic raw, String lang) {
  if (raw is Map) {
    final value = raw[lang];
    if (value is List && value.isNotEmpty) return List<String>.from(value);
    final fallback = raw['en'];
    return fallback is List ? List<String>.from(fallback) : const [];
  }
  return raw is List ? List<String>.from(raw) : const [];
}

/// Writes [value] back under [lang], keeping every other language intact.
///
/// Without this, an admin editing a question in English would overwrite the
/// `{en, mk}` map with a bare string and destroy the Macedonian translation.
dynamic _mergeField(dynamic raw, Object value, String lang) =>
    raw is Map ? {...raw.cast<String, dynamic>(), lang: value} : value;

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

  /// Reviewer feedback shown to the author when a submission is rejected or
  /// marked [QuestionStatus.needsRevision]. Empty for approved/legacy questions.
  final String reviewNote;

  /// Raw `{lang: value}` maps for the translatable fields, exactly as they came
  /// out of Firestore. Empty for questions built in Dart (local game data, AI
  /// drafts) and for docs the translation script has not touched yet.
  ///
  /// Carried so [toMap] can merge an edit back into the map instead of
  /// flattening it. Not read anywhere else — use [text], [options] and
  /// [explanation], which are already resolved into [lang].
  final Map<String, dynamic> translations;

  /// Language that [text], [options] and [explanation] hold.
  final String lang;

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
    this.reviewNote = '',
    this.translations = const {},
    this.lang = 'en',
  });

  /// [lang] defaults to the app-wide [AppLocale.code]; pass it explicitly when
  /// you need a specific language regardless of what the user has selected.
  factory QuestionModel.fromMap(Map<String, dynamic> map, {String? lang}) {
    final language = lang ?? AppLocale.code;
    return QuestionModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      topicId: map['topicId'] ?? '',
      text: _resolveString(map['text'], language),
      type: QuestionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: _resolveList(map['options'], language),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: _resolveString(map['explanation'], language),
      difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      points: map['points'] ?? 10,
      status:
          QuestionStatusExtension.fromString(map['status'] ?? 'approved'),
      authorId: map['authorId'] ?? '',
      reviewedBy: map['reviewedBy'] ?? '',
      reviewNote: map['reviewNote'] ?? '',
      translations: {
        for (final field in _translatableFields)
          if (map[field] is Map) field: map[field],
      },
      lang: language,
    );
  }

  /// Reads a question's text straight from a raw Firestore map, without
  /// building a model. Used where only the string is needed.
  static String textOf(Map<String, dynamic> map, {String lang = 'en'}) =>
      _resolveString(map['text'], lang);

  /// Whether this question already carries a non-empty [lang] copy. Lets the
  /// translation tool skip work it has already done.
  bool hasTranslation(String lang) {
    final field = translations['text'];
    final value = field is Map ? field[lang] : null;
    return value is String && value.isNotEmpty;
  }

  /// The Firestore value for [field] with [value] filed under [lang], keeping
  /// every language already on the document.
  ///
  /// For a document the translation tool has not touched, `translations` is
  /// empty and the current resolved value becomes the [lang] entry — which is
  /// how a plain string is promoted into an `{en, mk}` map the first time.
  Map<String, dynamic> fieldWithTranslation(
    String field,
    Object value,
    String lang,
  ) {
    assert(_translatableFields.contains(field), 'not a translatable field');
    final existing = translations[field];
    final base = existing is Map
        ? existing.cast<String, dynamic>()
        : <String, dynamic>{this.lang: _resolvedField(field)};
    return {...base, lang: value};
  }

  Object _resolvedField(String field) => switch (field) {
        'text' => text,
        'options' => options,
        'explanation' => explanation,
        _ => throw ArgumentError.value(field, 'field', 'not translatable'),
      };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'topicId': topicId,
      'text': _mergeField(translations['text'], text, lang),
      'type': type.name,
      'options': _mergeField(translations['options'], options, lang),
      'correctIndex': correctIndex,
      'explanation':
          _mergeField(translations['explanation'], explanation, lang),
      'difficulty': difficulty.name,
      'points': points,
      'status': status.name,
      'authorId': authorId,
      'reviewedBy': reviewedBy,
      'reviewNote': reviewNote,
    };
  }

  /// Preserves [translations] and [lang] so an edit made through a form does
  /// not drop the other language's copy.
  QuestionModel copyWith({
    String? id,
    String? categoryId,
    String? topicId,
    String? text,
    QuestionType? type,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    DifficultyLevel? difficulty,
    int? points,
    QuestionStatus? status,
    String? authorId,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      topicId: topicId ?? this.topicId,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      translations: translations,
      lang: lang,
    );
  }
}