import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_challenge_model.dart';
import '../models/quiz_result_model.dart';

/// Picks and tracks the one daily challenge per user per calendar day.
///
/// The challenge is chosen deterministically from a fixed [templates] pool by
/// seeding off the local date, so it's identical all day and across devices
/// without any server state. Progress lives in `daily_challenges/{userId}_{date}`
/// and resets automatically at local midnight (a new date → a new doc).
class DailyChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fixed challenge pool. Keep these `id`s stable — persisted progress
  /// references them. `answerInCategory` templates use real category slugs
  /// (`privacy`, `passwords`).
  static const List<DailyChallengeTemplate> templates = [
    DailyChallengeTemplate(
      id: 'answer_5',
      type: DailyChallengeType.answerQuestions,
      title: 'Answer 5 questions',
      target: 5,
      coinReward: 10,
    ),
    DailyChallengeTemplate(
      id: 'answer_10',
      type: DailyChallengeType.answerQuestions,
      title: 'Answer 10 questions',
      target: 10,
      coinReward: 15,
    ),
    DailyChallengeTemplate(
      id: 'three_star',
      type: DailyChallengeType.threeStarQuiz,
      title: 'Ace a quiz with 3 stars',
      target: 1,
      coinReward: 15,
    ),
    DailyChallengeTemplate(
      id: 'category_privacy',
      type: DailyChallengeType.answerInCategory,
      title: 'Answer 5 Privacy questions',
      target: 5,
      coinReward: 12,
      categoryId: 'privacy',
      categoryName: 'Privacy',
    ),
    DailyChallengeTemplate(
      id: 'category_passwords',
      type: DailyChallengeType.answerInCategory,
      title: 'Answer 5 Passwords questions',
      target: 5,
      coinReward: 12,
      categoryId: 'passwords',
      categoryName: 'Passwords',
    ),
    DailyChallengeTemplate(
      id: 'practice_weak',
      type: DailyChallengeType.practiceWeakSpots,
      title: 'Practice your weak spots once',
      target: 1,
      coinReward: 10,
    ),
  ];

  /// Deterministic per-calendar-day pick. Same challenge all day, stable across
  /// devices and restarts — seeded from the local Y/M/D only.
  DailyChallengeTemplate challengeForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    return templates[seed % templates.length];
  }

  DailyChallengeTemplate templateById(String id) =>
      templates.firstWhere((t) => t.id == id, orElse: () => templates.first);

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DocumentReference<Map<String, dynamic>> _todayRef(String userId) {
    final key = _dateKey(DateTime.now());
    return _db.collection('daily_challenges').doc('${userId}_$key');
  }

  /// Watches the user's progress on today's challenge. Emits a fresh, unclaimed
  /// default when no doc exists yet (or a stale doc from a different day/challenge
  /// somehow lingers), so the card always reflects today.
  Stream<DailyChallengeModel> watchToday(String userId) {
    final key = _dateKey(DateTime.now());
    final template = challengeForDate(DateTime.now());
    DailyChallengeModel fresh() => DailyChallengeModel(
          id: '${userId}_$key',
          userId: userId,
          challengeId: template.id,
          date: key,
        );
    return _todayRef(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null ||
          data['challengeId'] != template.id ||
          data['date'] != key) {
        return fresh();
      }
      return DailyChallengeModel.fromMap({'id': snap.id, ...data});
    });
  }

  /// How much a completed quiz advances a given challenge. Replays never count.
  int _incrementFor(DailyChallengeTemplate t, QuizResultModel r) {
    if (r.isReplay) return 0;
    switch (t.type) {
      case DailyChallengeType.answerQuestions:
        return r.totalQuestions;
      case DailyChallengeType.threeStarQuiz:
        // Counts a perfect score from any quiz — including the challenge's own
        // launched run (which is practice-tagged), so `isPractice` isn't gated.
        return r.starsEarned >= 3 ? 1 : 0;
      case DailyChallengeType.answerInCategory:
        return r.categoryId == t.categoryId ? r.totalQuestions : 0;
      case DailyChallengeType.practiceWeakSpots:
        return r.isPractice ? 1 : 0;
    }
  }

  /// Advances today's challenge from a completed quiz. Progress is capped at the
  /// target; an already-claimed challenge is left untouched. Runs in a
  /// transaction because the new value depends on the read one.
  Future<void> recordQuizCompletion(
      String userId, QuizResultModel result) async {
    final template = challengeForDate(DateTime.now());
    final inc = _incrementFor(template, result);
    if (inc <= 0) return;

    final key = _dateKey(DateTime.now());
    final ref = _todayRef(userId);
    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(ref);
        final data = snap.data();
        final sameChallenge = data != null &&
            data['challengeId'] == template.id &&
            data['date'] == key;
        if (sameChallenge && (data['claimed'] as bool? ?? false)) return;
        final current = sameChallenge ? (data['progress'] as int? ?? 0) : 0;
        final next = (current + inc).clamp(0, template.target);
        txn.set(ref, {
          'id': '${userId}_$key',
          'userId': userId,
          'challengeId': template.id,
          'date': key,
          'progress': next,
          'claimed': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {}
  }

  /// Claims the coin reward once the target is met. Awards coins on the user doc
  /// and flips `claimed` atomically; returns false if not eligible (already
  /// claimed or incomplete). Play the coin sound / burst in the UI on success.
  Future<bool> claim(String userId) async {
    final template = challengeForDate(DateTime.now());
    final ref = _todayRef(userId);
    final userRef = _db.collection('users').doc(userId);
    try {
      return await _db.runTransaction<bool>((txn) async {
        final snap = await txn.get(ref);
        final data = snap.data();
        if (data == null || data['challengeId'] != template.id) return false;
        final claimed = data['claimed'] as bool? ?? false;
        final progress = data['progress'] as int? ?? 0;
        if (claimed || progress < template.target) return false;
        txn.update(ref, {
          'claimed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        txn.update(userRef, {
          'coins': FieldValue.increment(template.coinReward),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }
}
