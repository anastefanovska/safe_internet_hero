import 'package:cloud_firestore/cloud_firestore.dart';

/// Rewards for the mini-games. Coins are granted at most **once per game per
/// calendar day** (anti-farming), mirroring the daily-challenge pattern — a
/// marker doc lives in `mini_game_plays/{userId}_{gameId}_{yyyy-MM-dd}` and the
/// coins are incremented on the user's own doc in the same transaction.
class MiniGameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _docId(String userId, String gameId) =>
      '${userId}_${gameId}_${_dateKey(DateTime.now())}';

  /// Grants [coins] for finishing [gameId] — but only the first completion
  /// today. Runs in a transaction because the coin write depends on whether
  /// today's marker already exists. Returns the coins actually awarded (0 when
  /// already claimed today or [coins] <= 0). Replays are still playable, just
  /// unpaid — call the coin sound / refresh the user only when the result > 0.
  Future<int> awardCoins({
    required String userId,
    required String gameId,
    required int coins,
  }) async {
    if (coins <= 0) return 0;
    final key = _docId(userId, gameId);
    final ref = _db.collection('mini_game_plays').doc(key);
    final userRef = _db.collection('users').doc(userId);
    try {
      return await _db.runTransaction<int>((txn) async {
        final snap = await txn.get(ref);
        if (snap.exists) return 0; // already rewarded today
        txn.set(ref, {
          'id': key,
          'userId': userId,
          'gameId': gameId,
          'date': _dateKey(DateTime.now()),
          'coins': coins,
          'createdAt': FieldValue.serverTimestamp(),
        });
        txn.update(userRef, {'coins': FieldValue.increment(coins)});
        return coins;
      });
    } catch (_) {
      return 0;
    }
  }

  /// Records an arcade high score for [gameId] on the user's own doc. Returns the
  /// **previous** best (so the UI can tell whether this run set a new record).
  /// Only writes when [score] beats the stored best. Runs in a transaction so a
  /// concurrent play can't clobber a higher score.
  Future<int> submitHighScore({
    required String userId,
    required String gameId,
    required int score,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    try {
      return await _db.runTransaction<int>((txn) async {
        final snap = await txn.get(userRef);
        final scores = (snap.data()?['miniGameHighScores']
                as Map<dynamic, dynamic>?) ??
            const {};
        final prev = (scores[gameId] as num?)?.toInt() ?? 0;
        if (score > prev) {
          txn.update(userRef, {'miniGameHighScores.$gameId': score});
        }
        return prev;
      });
    } catch (_) {
      return 0;
    }
  }

  /// Adds [amount] to a cumulative progress stat on the user's own doc (used for
  /// mastery/rank systems, e.g. total scams correctly identified). Stored in the
  /// same `miniGameHighScores` map under [statKey]. Best-effort.
  Future<void> addProgress({
    required String userId,
    required String statKey,
    required int amount,
  }) async {
    if (amount <= 0) return;
    try {
      await _db.collection('users').doc(userId).update(
        {'miniGameHighScores.$statKey': FieldValue.increment(amount)},
      );
    } catch (_) {}
  }
}
