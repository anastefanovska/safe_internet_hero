import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/learning_content_model.dart';

class LearningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LearningContentModel>> getAllContent() {
    return _db
        .collection('learning_content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => LearningContentModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  /// Total number of learning-content items. Uses the aggregate count query
  /// (cheaper than fetching docs) — used for moderator eligibility (% read).
  Future<int> getTotalContentCount() async {
    final snap = await _db.collection('learning_content').count().get();
    return snap.count ?? 0;
  }

  Stream<List<LearningContentModel>> getContentByCategory(String categoryId) {
    return _db
        .collection('learning_content')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => LearningContentModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  Stream<List<LearningContentModel>> getContentByTopic(String topicId) {
    return _db
        .collection('learning_content')
        .where('topicId', isEqualTo: topicId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => LearningContentModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  // Create new content
  Future<void> saveContent(LearningContentModel content) async {
    final doc = _db.collection('learning_content').doc();
    await doc.set(content.toMap()..['id'] = doc.id);
  }

  Future<void> seedContent(List<LearningContentModel> items) async {
    const chunkSize = 400;
    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.sublist(i, (i + chunkSize).clamp(0, items.length));
      final batch = _db.batch();
      for (final item in chunk) {
        final doc = _db.collection('learning_content').doc();
        batch.set(doc, item.toMap()..['id'] = doc.id);
      }
      await batch.commit();
    }
  }

  // Update existing content
  Future<void> updateContent(LearningContentModel content) async {
    await _db
        .collection('learning_content')
        .doc(content.id)
        .update(content.toMap());
  }

  // Delete content
  Future<void> deleteContent(String id) async {
    await _db.collection('learning_content').doc(id).delete();
  }

  /// Awards XP the first time a user reads/watches a content item.
  /// Returns the XP actually awarded — 0 if the item was already completed.
  Future<int> markContentRead({
    required String userId,
    required String contentId,
    required int xpToAward,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    final doc = await userRef.get();
    if (!doc.exists) return 0;
    final data = doc.data() as Map<String, dynamic>;
    final readIds = List<String>.from(data['readContentIds'] ?? []);
    if (readIds.contains(contentId)) return 0;
    await userRef.update({
      'readContentIds': FieldValue.arrayUnion([contentId]),
      'totalStars': FieldValue.increment(xpToAward),
    });
    return xpToAward;
  }
}