import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Who can see a given profile field. The three real choices a privacy setting
/// offers, which is exactly the nuance "Privacy Setup" teaches (it's not just
/// public-vs-private).
enum FieldVisibility { public, friends, private }

extension FieldVisibilityX on FieldVisibility {
  static FieldVisibility fromString(String v) => FieldVisibility.values
      .firstWhere((e) => e.name == v, orElse: () => FieldVisibility.public);

  String labelOf(AppLocalizations l10n) => switch (this) {
        FieldVisibility.public => l10n.privacyPublic,
        FieldVisibility.friends => l10n.privacyFriends,
        FieldVisibility.private => l10n.privacyPrivate,
      };

  IconData get icon => switch (this) {
        FieldVisibility.public => Icons.public_rounded,
        FieldVisibility.friends => Icons.group_rounded,
        FieldVisibility.private => Icons.lock_rounded,
      };
}

/// One field on a mock profile the player configures in "Privacy Setup".
/// [recommended] is the safe visibility; [explanation] teaches why.
///
/// Seeded locally from `data/privacy_fields.dart`. [icon] is display-only
/// (bundled Material icon); the rest round-trips via `fromMap`/`toMap`.
class PrivacyFieldModel {
  final String id;
  final String label;
  final IconData icon;
  final FieldVisibility recommended;
  final String explanation;

  const PrivacyFieldModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.recommended,
    required this.explanation,
  });

  factory PrivacyFieldModel.fromMap(Map<String, dynamic> map) {
    return PrivacyFieldModel(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      icon: Icons.help_outline_rounded, // display-only; not stored
      recommended: FieldVisibilityX.fromString(map['recommended'] ?? 'public'),
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconCode': icon.codePoint,
        'recommended': recommended.name,
        'explanation': explanation,
      };
}
