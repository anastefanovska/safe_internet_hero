import 'package:flutter/services.dart';

/// Tactile feedback for the app — the "feel" half of game juice (the audible
/// half lives in [SoundService]). Every meaningful action (a button press, a
/// correct answer, a swipe committing, a coin landing) should have a physical
/// response, which is what separates a game from a form.
///
/// Kept deliberately tiny and dependency-free: it wraps Flutter's built-in
/// [HapticFeedback]. On web and desktop the platform channel is a no-op, and any
/// failure is swallowed, so callers never need to guard by platform. Mirrors
/// [SoundService]: a process-lifetime singleton with an [enabled] flag that the
/// settings screen drives.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  bool _enabled = true;
  bool get isEnabled => _enabled;
  set enabled(bool value) => _enabled = value;

  Future<void> _fire(Future<void> Function() action) async {
    if (!_enabled) return;
    try {
      await action();
    } catch (_) {
      // Unsupported platform (web/desktop) or channel error — ignore.
    }
  }

  /// A crisp, low-cost tick for discrete UI changes: selecting a tab, flipping a
  /// choice, moving through a picker. Use liberally — it should feel like the UI
  /// is clicking under the finger.
  Future<void> selection() => _fire(HapticFeedback.selectionClick);

  /// A light tap — the default for tapping a button or card.
  Future<void> light() => _fire(HapticFeedback.lightImpact);

  /// A medium thud — for a gesture committing (a swipe leaving the deck) or a
  /// meaningful state change.
  Future<void> medium() => _fire(HapticFeedback.mediumImpact);

  /// A heavy hit — reserved for big moments (a combo milestone, a level-up).
  Future<void> heavy() => _fire(HapticFeedback.heavyImpact);

  /// A satisfying two-beat pulse for a *correct* answer or a match landing —
  /// distinctly "yes!" versus a single tap.
  Future<void> success() async {
    if (!_enabled) return;
    await _fire(HapticFeedback.mediumImpact);
    await Future.delayed(const Duration(milliseconds: 70));
    await _fire(HapticFeedback.lightImpact);
  }

  /// A blunt double-thud for a *wrong* answer or an invalid action — reads as a
  /// gentle "nope" without being punishing.
  Future<void> error() async {
    if (!_enabled) return;
    await _fire(HapticFeedback.heavyImpact);
    await Future.delayed(const Duration(milliseconds: 90));
    await _fire(HapticFeedback.mediumImpact);
  }

  /// Escalating buzz for a rising combo — grows from a tap to a hit as the
  /// streak climbs, so momentum is felt, not just seen.
  Future<void> combo(int streak) {
    if (streak >= 5) return heavy();
    if (streak >= 3) return medium();
    return light();
  }

  /// A bright triple-tick for coins/stars landing — the reward "ka-ching".
  Future<void> reward() async {
    if (!_enabled) return;
    await _fire(HapticFeedback.lightImpact);
    await Future.delayed(const Duration(milliseconds: 60));
    await _fire(HapticFeedback.mediumImpact);
    await Future.delayed(const Duration(milliseconds: 60));
    await _fire(HapticFeedback.lightImpact);
  }
}
