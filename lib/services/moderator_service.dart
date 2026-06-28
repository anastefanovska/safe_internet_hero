import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification_model.dart';
import '../models/enums.dart';
import '../models/moderator_request_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import 'learning_service.dart';

/// Result of an eligibility check, with the individual signals so the UI can
/// render a checklist.
class ModeratorEligibility {
  final int answeredCount;
  final int readCount;
  final int totalContent;
  final int rank;

  const ModeratorEligibility({
    required this.answeredCount,
    required this.readCount,
    required this.totalContent,
    required this.rank,
  });

  // Balanced thresholds.
  static const int minAnswered = 40;
  static const double minReadFraction = 0.70;
  static const int maxRank = 25;

  double get readFraction =>
      totalContent == 0 ? 0 : readCount / totalContent;

  bool get meetsAnswered => answeredCount >= minAnswered;
  bool get meetsRead => readFraction >= minReadFraction;
  bool get meetsRank => rank <= maxRank;
  bool get isEligible => meetsAnswered && meetsRead && meetsRank;
}

class ModeratorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LearningService _learningService = LearningService();

  // ─── Eligibility ──────────────────────────────────────────────────────────

  /// Computes the three trust signals for [user]. Admins are already above the
  /// role, so they're reported as ineligible (rank 0 sentinel via short-circuit
  /// is unnecessary — callers gate on isAdmin before showing the entry point).
  Future<ModeratorEligibility> checkEligibility(UserModel user) async {
    final totalContent = await _learningService.getTotalContentCount();
    final rank = await _computeRank(user.totalStars);
    return ModeratorEligibility(
      answeredCount: user.answeredQuestions.length,
      readCount: user.readContentIds.length,
      totalContent: totalContent,
      rank: rank,
    );
  }

  /// Leaderboard rank by stars, excluding admins — same approach as
  /// `leaderboard_screen.getUserRank`.
  Future<int> _computeRank(int userStars) async {
    final snap = await _db
        .collection('users')
        .where('totalStars', isGreaterThan: userStars)
        .get();
    final ahead =
        snap.docs.where((d) => d.data()['isAdmin'] != true).length;
    return ahead + 1;
  }

  // ─── Requests ───────────────────────────────────────────────────────────────

  /// Stream of the current user's request (null if they've never applied).
  Stream<ModeratorRequestModel?> watchMyRequest(String userId) {
    return _db
        .collection('moderator_requests')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists
            ? ModeratorRequestModel.fromMap({'id': doc.id, ...doc.data()!})
            : null);
  }

  /// Files (or re-files) a moderator request. Writes the request doc and
  /// mirrors `moderatorStatus: pending` on the user doc in one batch. Both
  /// writes are permitted to the owner by the security rules.
  Future<void> requestModerator(UserModel user) async {
    final batch = _db.batch();
    final reqRef = _db.collection('moderator_requests').doc(user.id);
    batch.set(
      reqRef,
      ModeratorRequestModel(
        id: user.id,
        userId: user.id,
        username: user.username,
        status: ModeratorStatus.pending,
        createdAt: DateTime.now(),
      ).toMap(),
    );
    batch.update(_db.collection('users').doc(user.id),
        {'moderatorStatus': ModeratorStatus.pending.name});
    await batch.commit();
  }

  /// Pending applications for the admin review queue, newest first.
  Stream<List<ModeratorRequestModel>> watchPendingRequests() {
    return _db
        .collection('moderator_requests')
        .where('status', isEqualTo: ModeratorStatus.pending.name)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ModeratorRequestModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Current moderators, for the revoke list. Sorted by username in Dart.
  Stream<List<UserModel>> watchModerators() {
    return _db
        .collection('users')
        .where('isModerator', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
      list.sort((a, b) =>
          a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      return list;
    });
  }

  /// Approves an application: flips the role on the user doc, stamps the
  /// request, and notifies the applicant — atomically.
  Future<void> approveRequest(
      ModeratorRequestModel request, String adminUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('moderator_requests').doc(request.userId), {
      'status': ModeratorStatus.approved.name,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('users').doc(request.userId), {
      'isModerator': true,
      'moderatorStatus': ModeratorStatus.approved.name,
    });
    _addNotification(batch,
        userId: request.userId,
        type: 'mod_request_approved',
        title: 'You\'re now a moderator! 🎉',
        body: 'Your moderator request was approved. You can now submit quiz '
            'questions for review.');
    await batch.commit();
  }

  /// Rejects an application: marks the request rejected and notifies the user.
  /// The role bool stays false.
  Future<void> rejectRequest(
      ModeratorRequestModel request, String adminUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('moderator_requests').doc(request.userId), {
      'status': ModeratorStatus.rejected.name,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
    batch.update(_db.collection('users').doc(request.userId),
        {'moderatorStatus': ModeratorStatus.rejected.name});
    _addNotification(batch,
        userId: request.userId,
        type: 'mod_request_rejected',
        title: 'Moderator request update',
        body: 'Your moderator request wasn\'t approved this time. Keep '
            'learning and you can apply again later.');
    await batch.commit();
  }

  /// Revokes moderator status. Clears the role + status and removes the request
  /// doc so the user returns to a clean state and can re-apply.
  Future<void> revokeModerator(String userId, String adminUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(userId), {
      'isModerator': false,
      'moderatorStatus': ModeratorStatus.none.name,
    });
    batch.delete(_db.collection('moderator_requests').doc(userId));
    _addNotification(batch,
        userId: userId,
        type: 'mod_revoked',
        title: 'Moderator access changed',
        body: 'Your moderator access has been removed by an admin.');
    await batch.commit();
  }

  // ─── Submission review ──────────────────────────────────────────────────────

  Future<void> approveSubmission(
      QuestionModel question, String adminUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('questions').doc(question.id), {
      'status': QuestionStatus.approved.name,
      'reviewedBy': adminUid,
    });
    if (question.authorId.isNotEmpty) {
      _addNotification(batch,
          userId: question.authorId,
          type: 'submission_approved',
          title: 'Your question went live! ✅',
          body: 'A question you submitted was approved and is now in the quiz.');
    }
    await batch.commit();
  }

  Future<void> rejectSubmission(
      QuestionModel question, String adminUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('questions').doc(question.id), {
      'status': QuestionStatus.rejected.name,
      'reviewedBy': adminUid,
    });
    if (question.authorId.isNotEmpty) {
      _addNotification(batch,
          userId: question.authorId,
          type: 'submission_rejected',
          title: 'Question submission update',
          body: 'A question you submitted wasn\'t approved. Thanks for helping '
              'keep the quiz great!');
    }
    await batch.commit();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _addNotification(
    WriteBatch batch, {
    required String userId,
    required String type,
    required String title,
    required String body,
  }) {
    final ref = _db.collection('notifications').doc();
    batch.set(
      ref,
      AppNotificationModel(
        id: ref.id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }
}
