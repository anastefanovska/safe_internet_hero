/// One fake message in the "Tap the Red Flag" mini-game. The message body is
/// split into [parts]; the player taps the parts that are suspicious. A part
/// with [RedFlagPart.isFlag] true is a genuine red flag (with a [reason] shown
/// afterwards); the rest are ordinary text.
///
/// Seeded locally from `data/red_flag_messages.dart`; immutable with
/// `fromMap`/`toMap` (safe defaults, injected id) like every other model.
class RedFlagMessageModel {
  final String id;

  /// Who the message appears to be from.
  final String sender;

  /// A short framing line (e.g. "Text message", "Email").
  final String context;

  /// The message body, broken into tappable parts.
  final List<RedFlagPart> parts;

  const RedFlagMessageModel({
    required this.id,
    required this.sender,
    required this.context,
    required this.parts,
  });

  /// Number of genuine red flags in this message.
  int get flagCount => parts.where((p) => p.isFlag).length;

  factory RedFlagMessageModel.fromMap(Map<String, dynamic> map) {
    return RedFlagMessageModel(
      id: map['id'] ?? '',
      sender: map['sender'] ?? '',
      context: map['context'] ?? '',
      parts: (map['parts'] as List<dynamic>? ?? const [])
          .map((p) => RedFlagPart.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sender': sender,
        'context': context,
        'parts': parts.map((p) => p.toMap()).toList(),
      };
}

/// A single tappable fragment of a message.
class RedFlagPart {
  final String text;
  final bool isFlag;

  /// Why this fragment is a red flag (empty for ordinary text).
  final String reason;

  const RedFlagPart(this.text, {this.isFlag = false, this.reason = ''});

  factory RedFlagPart.fromMap(Map<String, dynamic> map) => RedFlagPart(
        map['text'] ?? '',
        isFlag: map['isFlag'] ?? false,
        reason: map['reason'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'isFlag': isFlag,
        'reason': reason,
      };
}
