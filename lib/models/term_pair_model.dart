/// One term↔definition pair for the "Match Madness" mini-game. Immutable with
/// `fromMap`/`toMap` and safe defaults (like every model) so it can move to
/// Firestore later without churn — for now it's seeded from `data/term_pairs.dart`.
class TermPairModel {
  final String id;
  final String term;
  final String definition;

  const TermPairModel({
    required this.id,
    required this.term,
    required this.definition,
  });

  factory TermPairModel.fromMap(Map<String, dynamic> map) {
    return TermPairModel(
      id: map['id'] ?? '',
      term: map['term'] ?? '',
      definition: map['definition'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'term': term,
        'definition': definition,
      };
}
