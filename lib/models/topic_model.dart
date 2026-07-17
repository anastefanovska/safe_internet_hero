import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';

class TopicModel {
  final String id;
  final String categoryId;

  /// Raw name/desc as stored: either a plain string (English-only legacy doc)
  /// or a `{en, mk}` map. Exposed through the [name]/[desc] getters, which
  /// resolve to the live content language on each read (so they follow a
  /// language switch), and [nameEn]/[descEn] for editing the English source.
  final dynamic nameRaw;
  final dynamic descRaw;

  final bool isNew;
  final bool isUpdated;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TopicModel({
    required this.id,
    required this.categoryId,
    required Object name,
    required Object desc,
    required this.isNew,
    required this.isUpdated,
    required this.order,
    this.createdAt,
    this.updatedAt,
  })  : nameRaw = name,
        descRaw = desc;

  /// Display name in the current content language (falls back to English).
  String get name => resolveLocalized(nameRaw);

  /// Display description in the current content language (falls back to English).
  String get desc => resolveLocalized(descRaw);

  /// English source, for pre-filling the admin editor.
  String get nameEn => resolveLocalized(nameRaw, 'en');
  String get descEn => resolveLocalized(descRaw, 'en');

  /// Macedonian copy if present (empty when not yet translated).
  String get nameMk => nameRaw is Map ? (nameRaw['mk'] as String? ?? '') : '';
  String get descMk => descRaw is Map ? (descRaw['mk'] as String? ?? '') : '';

  /// Whether a non-empty [lang] name copy already exists.
  bool hasTranslation(String lang) {
    final v = nameRaw is Map ? nameRaw[lang] : null;
    return v is String && v.isNotEmpty;
  }

  factory TopicModel.fromMap(Map<String, dynamic> map) {
    return TopicModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      desc: map['desc'] ?? '',
      isNew: map['isNew'] ?? false,
      isUpdated: map['isUpdated'] ?? false,
      order: map['order'] ?? 0,
      createdAt: _toDateTimeOrNull(map['createdAt']),
      updatedAt: _toDateTimeOrNull(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': nameRaw,
      'desc': descRaw,
      'isNew': isNew,
      'isUpdated': isUpdated,
      'order': order,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
