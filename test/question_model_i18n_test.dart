import 'package:flutter_test/flutter_test.dart';
import 'package:safe_internet_hero/models/question_model.dart';

/// A document the translation script has already migrated.
Map<String, dynamic> migratedDoc() => {
      'id': 'q1',
      'categoryId': 'c',
      'topicId': 't',
      'text': {'en': 'What is phishing?', 'mk': 'Што е фишинг?'},
      'type': 'multipleChoice',
      'options': {
        'en': ['A scam', 'A fish'],
        'mk': ['Измама', 'Риба'],
      },
      'correctIndex': 0,
      'explanation': {'en': 'It is a scam.', 'mk': 'Тоа е измама.'},
      'difficulty': 'beginner',
      'points': 10,
    };

/// A document written before the migration ran.
Map<String, dynamic> legacyDoc() => {
      'id': 'q2',
      'text': 'What is spam?',
      'type': 'multipleChoice',
      'options': ['Junk mail', 'Meat'],
      'correctIndex': 0,
      'explanation': 'Unwanted mail.',
      'difficulty': 'beginner',
      'points': 10,
    };

void main() {
  group('resolving', () {
    test('reads the requested language', () {
      final q = QuestionModel.fromMap(migratedDoc(), lang: 'mk');
      expect(q.text, 'Што е фишинг?');
      expect(q.options, ['Измама', 'Риба']);
      expect(q.explanation, 'Тоа е измама.');
    });

    test('legacy scalar fields still work', () {
      final q = QuestionModel.fromMap(legacyDoc(), lang: 'mk');
      expect(q.text, 'What is spam?');
      expect(q.options, ['Junk mail', 'Meat']);
      expect(q.translations, isEmpty);
    });

    test('falls back to English when the translation is missing', () {
      final doc = migratedDoc()..['text'] = {'en': 'Only English'};
      expect(QuestionModel.fromMap(doc, lang: 'mk').text, 'Only English');
    });

    test('falls back to English options rather than rendering none', () {
      final doc = migratedDoc()
        ..['options'] = {
          'en': ['A scam', 'A fish'],
          'mk': <String>[],
        };
      expect(QuestionModel.fromMap(doc, lang: 'mk').options,
          ['A scam', 'A fish']);
    });

    test('correctIndex still points at the right option after translating', () {
      final en = QuestionModel.fromMap(migratedDoc(), lang: 'en');
      final mk = QuestionModel.fromMap(migratedDoc(), lang: 'mk');
      expect(en.options[en.correctIndex], 'A scam');
      expect(mk.options[mk.correctIndex], 'Измама');
    });
  });

  group('writing back', () {
    test('editing in English keeps the Macedonian copy', () {
      final q = QuestionModel.fromMap(migratedDoc(), lang: 'en');
      final edited = q.copyWith(text: 'What is phishing, really?');
      final out = edited.toMap();

      expect(out['text'], {
        'en': 'What is phishing, really?',
        'mk': 'Што е фишинг?',
      });
      expect((out['explanation'] as Map)['mk'], 'Тоа е измама.');
    });

    test('editing in Macedonian keeps the English copy', () {
      final q = QuestionModel.fromMap(migratedDoc(), lang: 'mk');
      final out = q.copyWith(options: ['Измама!', 'Риба!']).toMap();

      expect(out['options'], {
        'en': ['A scam', 'A fish'],
        'mk': ['Измама!', 'Риба!'],
      });
    });

    test('a legacy question round-trips as a plain string', () {
      final out = QuestionModel.fromMap(legacyDoc(), lang: 'en').toMap();
      expect(out['text'], 'What is spam?');
      expect(out['options'], ['Junk mail', 'Meat']);
    });

    test('a brand-new question writes plain strings', () {
      final q = QuestionModel.fromMap({
        'id': 'new',
        'text': 'Fresh',
        'options': ['a', 'b'],
        'explanation': 'e',
      });
      expect(q.toMap()['text'], 'Fresh');
    });
  });

  group('fieldWithTranslation', () {
    test('promotes a legacy plain string into an {en, mk} map', () {
      final q = QuestionModel.fromMap(legacyDoc(), lang: 'en');
      expect(q.fieldWithTranslation('text', 'Што е спам?', 'mk'), {
        'en': 'What is spam?',
        'mk': 'Што е спам?',
      });
    });

    test('overwrites an existing translation without touching English', () {
      final q = QuestionModel.fromMap(migratedDoc(), lang: 'en');
      expect(q.fieldWithTranslation('text', 'Нов превод', 'mk'), {
        'en': 'What is phishing?',
        'mk': 'Нов превод',
      });
    });

    test('carries options across as a list', () {
      final q = QuestionModel.fromMap(legacyDoc(), lang: 'en');
      expect(q.fieldWithTranslation('options', ['Ѓубре', 'Месо'], 'mk'), {
        'en': ['Junk mail', 'Meat'],
        'mk': ['Ѓубре', 'Месо'],
      });
    });

    test('rejects a field that is not translatable', () {
      final q = QuestionModel.fromMap(legacyDoc(), lang: 'en');
      expect(() => q.fieldWithTranslation('difficulty', 'x', 'mk'),
          throwsA(anything));
    });
  });

  group('hasTranslation', () {
    test('true only when the language is actually present', () {
      expect(QuestionModel.fromMap(migratedDoc()).hasTranslation('mk'), isTrue);
      expect(QuestionModel.fromMap(legacyDoc()).hasTranslation('mk'), isFalse);
    });

    test('an empty translation does not count as done', () {
      final doc = migratedDoc()..['text'] = {'en': 'Hi', 'mk': ''};
      expect(QuestionModel.fromMap(doc).hasTranslation('mk'), isFalse);
    });
  });

  group('textOf', () {
    test('reads English out of a migrated doc without building a model', () {
      expect(QuestionModel.textOf(migratedDoc()), 'What is phishing?');
      expect(QuestionModel.textOf(migratedDoc(), lang: 'mk'), 'Што е фишинг?');
    });

    test('reads a legacy scalar', () {
      expect(QuestionModel.textOf(legacyDoc()), 'What is spam?');
    });
  });
}
