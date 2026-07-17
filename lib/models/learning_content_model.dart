import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';

enum ContentType { article, video, infographic }

class LearningContentModel {
  final String id;
  final String categoryId;
  final String topicId;

  /// Raw title/description/content as stored: a plain string (English-only
  /// legacy doc) or a `{en, mk}` map. Exposed through the resolving getters
  /// below, and [titleEn]/[descriptionEn]/[contentEn] for the English source.
  final dynamic titleRaw;
  final dynamic descriptionRaw;
  final dynamic contentRaw;

  final ContentType type;
  final String thumbnailUrl;
  final int readTimeMinutes;
  final DateTime createdAt;

  LearningContentModel({
    required this.id,
    required this.categoryId,
    required this.topicId,
    required Object title,
    required Object description,
    required this.type,
    required Object content,
    this.thumbnailUrl = '',
    this.readTimeMinutes = 0,
    required this.createdAt,
  })  : titleRaw = title,
        descriptionRaw = description,
        contentRaw = content;

  /// Display values in the current content language (fall back to English).
  String get title => resolveLocalized(titleRaw);
  String get description => resolveLocalized(descriptionRaw);
  String get content => resolveLocalized(contentRaw);

  /// English source, for the admin editor and as the AI translation input.
  String get titleEn => resolveLocalized(titleRaw, 'en');
  String get descriptionEn => resolveLocalized(descriptionRaw, 'en');
  String get contentEn => resolveLocalized(contentRaw, 'en');

  /// Macedonian copies if present (empty when not yet translated).
  String get titleMk => titleRaw is Map ? (titleRaw['mk'] as String? ?? '') : '';
  String get descriptionMk =>
      descriptionRaw is Map ? (descriptionRaw['mk'] as String? ?? '') : '';
  String get contentMk =>
      contentRaw is Map ? (contentRaw['mk'] as String? ?? '') : '';

  /// Whether a non-empty [lang] copy already exists (lets the translate tool
  /// skip work it has done).
  bool hasTranslation(String lang) {
    final v = titleRaw is Map ? titleRaw[lang] : null;
    return v is String && v.isNotEmpty;
  }

  factory LearningContentModel.fromMap(Map<String, dynamic> map) {
    return LearningContentModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      topicId: map['topicId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: ContentType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ContentType.article,
      ),
      content: map['content'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      readTimeMinutes: map['readTimeMinutes'] ?? 0,
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'topicId': topicId,
      'title': titleRaw,
      'description': descriptionRaw,
      'type': type.name,
      'content': contentRaw,
      'thumbnailUrl': thumbnailUrl,
      'readTimeMinutes': readTimeMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
