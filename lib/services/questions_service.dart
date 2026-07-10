import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Loads questions for a topic.
  /// [forReplay] — when true, `excludeIds` is ignored so users can redo a topic.
  /// [specificIds] — when provided, loads those exact question IDs (practice mode).
  Future<List<QuestionModel>> getQuestions({
    required String categoryId,
    required String topicId,
    List<String> excludeIds = const [],
    int limit = 10,
    bool forReplay = false,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);

    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    final snap = await query.get();
    // Only approved questions reach learners. Legacy docs without a `status`
    // field default to approved in fromMap, so they stay visible.
    final allQuestions = snap.docs
        .map((doc) => QuestionModel.fromMap(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .where((q) => q.status == QuestionStatus.approved)
        .toList();

    final filtered = forReplay
        ? allQuestions
        : allQuestions.where((q) => !excludeIds.contains(q.id)).toList();

    return _sortedByDifficulty(filtered).take(limit).toList();
  }

  /// Loads specific questions by their document IDs (used for practice mode).
  Future<List<QuestionModel>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn supports up to 30 items; chunk just in case.
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10).clamp(0, ids.length)));
    }
    final futures = chunks.map((chunk) => _db
        .collection('questions')
        .where(FieldPath.documentId, whereIn: chunk)
        .get());
    final snaps = await Future.wait(futures);
    final questions = snaps
        .expand((s) => s.docs)
        .map((doc) => QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
        .where((q) => q.status == QuestionStatus.approved)
        .toList();
    return _sortedByDifficulty(questions);
  }

  /// Returns up to [limit] random approved questions, optionally restricted to
  /// [categoryId]. Used by the daily challenge to launch a quiz on the spot
  /// without the learner picking a topic. Fetches then filters/shuffles in Dart
  /// (legacy no-status docs count as approved).
  Future<List<QuestionModel>> getRandomApprovedQuestions({
    String? categoryId,
    int limit = 5,
  }) async {
    Query query = _db.collection('questions');
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    final snap = await query.get();
    final approved = snap.docs
        .map((doc) => QuestionModel.fromMap(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .where((q) => q.status == QuestionStatus.approved)
        .toList()
      ..shuffle();
    return approved.take(limit).toList();
  }

  /// Shuffles within each difficulty tier, then concatenates beginner → intermediate → advanced.
  List<QuestionModel> _sortedByDifficulty(List<QuestionModel> questions) {
    return DifficultyLevel.values
        .expand((d) => questions.where((q) => q.difficulty == d).toList()..shuffle())
        .toList();
  }

  Future<List<String>> getExistingQuestionTexts({
    required String categoryId,
    required String topicId,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);
    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) => QuestionModel.textOf(doc.data() as Map<String, dynamic>,
            lang: 'en').trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Every question in the collection, resolved in English, for the admin
  /// translation tool. English because it is the source language the AI
  /// translates *from* — not whatever language the admin has the app set to.
  Future<List<QuestionModel>> getAllQuestionsForTranslation() async {
    final snap = await _db.collection('questions').get();
    return snap.docs
        .map((doc) =>
            QuestionModel.fromMap({'id': doc.id, ...doc.data()}, lang: 'en'))
        .toList();
  }

  /// Files a translation under [lang] on the three translatable fields,
  /// preserving the languages already on the document.
  ///
  /// [question] must have been loaded with `lang: 'en'` (see
  /// [getAllQuestionsForTranslation]) — its resolved values are the English
  /// copy that gets carried across. Only these three fields are written, so a
  /// question edited elsewhere in the meantime keeps its other changes.
  Future<void> saveTranslation(
    QuestionModel question, {
    required String lang,
    required String text,
    required List<String> options,
    required String explanation,
  }) async {
    await _db.collection('questions').doc(question.id).update({
      'text': question.fieldWithTranslation('text', text, lang),
      'options': question.fieldWithTranslation('options', options, lang),
      'explanation':
          question.fieldWithTranslation('explanation', explanation, lang),
    });
  }

  Future<void> seedQuestions(List<QuestionModel> questions) async {
    const chunkSize = 400;
    for (var i = 0; i < questions.length; i += chunkSize) {
      final chunk = questions.sublist(i, (i + chunkSize).clamp(0, questions.length));
      final batch = _db.batch();
      for (final q in chunk) {
        final doc = q.id.isNotEmpty
            ? _db.collection('questions').doc(q.id)
            : _db.collection('questions').doc();
        batch.set(doc, q.toMap()..['id'] = doc.id);
      }
      await batch.commit();
    }
  }

  Future<void> saveResult(QuizResultModel result) async {
    final doc = _db.collection('quiz_results').doc();
    await doc.set(result.toMap()..['id'] = doc.id);
  }

  /// Awards stars and coins to a user atomically.
  Future<void> addRewards({
    required String userId,
    required int starsToAdd,
    required int coinsToAdd,
  }) async {
    final updates = <String, dynamic>{};
    if (starsToAdd > 0) updates['totalStars'] = FieldValue.increment(starsToAdd);
    if (coinsToAdd > 0) updates['coins'] = FieldValue.increment(coinsToAdd);
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
  }

  /// Updates the user's answered/incorrect question lists.
  /// Correctly answered questions are added to [answeredQuestions] and
  /// removed from [incorrectlyAnsweredIds]. Incorrectly answered questions
  /// are added to [incorrectlyAnsweredIds].
  Future<void> saveAnsweredQuestions({
    required String userId,
    required List<String> correctIds,
    required List<String> incorrectIds,
  }) async {
    final updates = <String, dynamic>{};

    if (correctIds.isNotEmpty) {
      updates['answeredQuestions'] = FieldValue.arrayUnion(correctIds);
      // Remove from weak list when answered correctly
      updates['incorrectlyAnsweredIds'] = FieldValue.arrayRemove(correctIds);
    }

    if (incorrectIds.isNotEmpty) {
      updates['incorrectlyAnsweredIds'] = FieldValue.arrayUnion(incorrectIds);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
  }

  /// Counts only approved questions for a topic. We fetch and count in Dart
  /// rather than using the aggregate `.count()` because a learner-facing total
  /// must exclude pending/rejected moderator submissions, and legacy docs with
  /// no `status` field (treated as approved) can't be matched by a count query.
  Future<int> getTotalQuestionsCount({
    required String categoryId,
    required String topicId,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);

    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    final snap = await query.get();
    return snap.docs
        .map((doc) => QuestionModel.fromMap(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .where((q) => q.status == QuestionStatus.approved)
        .length;
  }

  /// All live questions for the admin manager. In-flight moderator submissions
  /// (pending / needs-revision) are excluded here — they live in the moderation
  /// queue ([watchAllSubmissions] / [watchPendingSubmissions]).
  Stream<List<QuestionModel>> watchAllQuestions() {
    return _db.collection('questions').snapshots().map((snap) => snap.docs
        .map((doc) =>
            QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
        .where((q) =>
            q.status != QuestionStatus.pending &&
            q.status != QuestionStatus.needsRevision)
        .toList());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  /// Updates an existing question doc in place. Used by admin edits and by a
  /// moderator revising their own submission. When [resetForReview] is true the
  /// question is forced back to `pending` and its prior review feedback cleared
  /// so a revised submission re-enters the queue with a clean slate.
  Future<void> updateQuestion(QuestionModel question,
      {bool resetForReview = false}) async {
    final data = question.toMap();
    if (resetForReview) {
      data['status'] = QuestionStatus.pending.name;
      data['reviewNote'] = '';
      data['reviewedBy'] = '';
    }
    await _db.collection('questions').doc(question.id).update(data);
  }

  /// Creates a moderator submission: forced to `pending`, stamped with the
  /// author's uid. Auto id, back-filled into the `id` field.
  Future<void> submitPendingQuestion(QuestionModel question) async {
    final doc = _db.collection('questions').doc();
    await doc.set(question.toMap()
      ..['id'] = doc.id
      ..['status'] = QuestionStatus.pending.name);
  }

  /// Pending moderator submissions awaiting admin review, newest first.
  Stream<List<QuestionModel>> watchPendingSubmissions() {
    return _db
        .collection('questions')
        .where('status', isEqualTo: QuestionStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  /// A moderator's own submissions (any status), for their "My submissions"
  /// list. Sorted in Dart to avoid a composite index.
  Stream<List<QuestionModel>> watchSubmissionsByAuthor(String authorId) {
    return _db
        .collection('questions')
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
            .toList());
  }

  /// Every moderator submission (any status), for the admin review queue with
  /// its status filter. A submission is any question stamped with an author —
  /// admin-authored content has an empty `authorId`. Sorted newest-first in
  /// Dart (auto-ids are roughly time-ordered) to avoid a composite index.
  Stream<List<QuestionModel>> watchAllSubmissions() {
    return _db.collection('questions').snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
          .where((q) => q.authorId.isNotEmpty)
          .toList();
      list.sort((a, b) => b.id.compareTo(a.id));
      return list;
    });
  }
}
