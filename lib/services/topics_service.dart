import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../models/category_model.dart';
import '../models/topic_model.dart';

class TopicsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Every topic, for the admin translation tool.
  Future<List<TopicModel>> getAllTopicsForTranslation() async {
    final snap = await _db.collection('topics').get();
    return snap.docs
        .map((d) => TopicModel.fromMap({'id': d.id, ...d.data()}))
        .toList();
  }

  /// Files a translation under [lang] on a topic's name/desc, keeping any
  /// language already present.
  Future<void> saveTopicTranslation(
    TopicModel topic, {
    required String lang,
    required String name,
    required String desc,
  }) async {
    await _db.collection('topics').doc(topic.id).update({
      'name': mergeLocalized(topic.nameRaw, name, lang),
      'desc': mergeLocalized(topic.descRaw, desc, lang),
    });
  }


  Stream<List<CategoryModel>> watchCategories() {
    return _db.collection('categories').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => CategoryModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<CategoryModel>> getCategories() async {
    final snap = await _db.collection('categories').get();
    final list = snap.docs
        .map((d) => CategoryModel.fromMap({'id': d.id, ...d.data()}))
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _db.collection('categories').doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Stream<List<TopicModel>> watchAllTopics() {
    return _db.collection('topics').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => TopicModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<TopicModel>> watchTopicsByCategory(String categoryId) {
    return _db
        .collection('topics')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TopicModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Future<List<TopicModel>> getTopicsByCategory(String categoryId) async {
    final snap = await _db
        .collection('topics')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final list = snap.docs
        .map((d) => TopicModel.fromMap({'id': d.id, ...d.data()}))
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<List<TopicModel>> getAllTopics() async {
    final snap = await _db.collection('topics').get();
    final list = snap.docs
        .map((d) => TopicModel.fromMap({'id': d.id, ...d.data()}))
        .toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<void> saveTopic(TopicModel topic) async {
    await _db.collection('topics').doc(topic.id).set(topic.toMap());
  }

  Future<void> deleteTopic(String id) async {
    await _db.collection('topics').doc(id).delete();
  }

  /// Returns a stream of the categoryId the user most recently completed a quiz in.
  /// Used to pick the "Continue Learning" featured card on the home screen.
  Stream<String?> watchMostRecentCategoryId(String userId) {
    return _db
        .collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final catId = doc.data()['categoryId'] as String?;
        if (catId != null && catId != 'practice') return catId;
      }
      return null;
    });
  }
}