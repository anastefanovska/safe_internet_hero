/// The channel a "Spot the Scam" message arrives on — drives the bubble's icon
/// and header framing (a text, an email, or a social DM).
enum ScamChannel { sms, email, dm }

extension ScamChannelExtension on ScamChannel {
  static ScamChannel fromString(String value) => ScamChannel.values.firstWhere(
        (c) => c.name == value,
        orElse: () => ScamChannel.sms,
      );
}

/// One message shown in the "Spot the Scam" mini-game. The player decides
/// whether it's a scam (unsafe) or a genuine, safe message; [explanation] is
/// revealed afterwards to teach the tell-tale signs.
///
/// Seeded locally from `data/scam_cards.dart`, but kept immutable with
/// `fromMap`/`toMap` (safe defaults, injected id) like every other model so it
/// can move to Firestore later without churn.
class ScamCardModel {
  final String id;
  final ScamChannel channel;

  /// Who the message appears to be from (a name, a number, a handle).
  final String sender;

  /// Optional subject line, shown for [ScamChannel.email].
  final String? subject;

  /// The message body shown as a chat bubble.
  final String content;

  /// True when the message is a scam / unsafe; false when it's genuine & safe.
  final bool isScam;

  /// Why it is (or isn't) a scam — shown after the player answers.
  final String explanation;

  const ScamCardModel({
    required this.id,
    required this.channel,
    required this.sender,
    this.subject,
    required this.content,
    required this.isScam,
    required this.explanation,
  });

  factory ScamCardModel.fromMap(Map<String, dynamic> map) {
    return ScamCardModel(
      id: map['id'] ?? '',
      channel: ScamChannelExtension.fromString(map['channel'] ?? ''),
      sender: map['sender'] ?? '',
      subject: map['subject'],
      content: map['content'] ?? '',
      isScam: map['isScam'] ?? false,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'channel': channel.name,
        'sender': sender,
        'subject': subject,
        'content': content,
        'isScam': isScam,
        'explanation': explanation,
      };
}
