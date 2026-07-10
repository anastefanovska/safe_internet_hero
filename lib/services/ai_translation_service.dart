import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/question_model.dart';

class AiTranslationException implements Exception {
  final String message;
  AiTranslationException(this.message);
  @override
  String toString() => message;
}

class QuestionTranslation {
  final String text;
  final String explanation;
  final List<String> options;

  const QuestionTranslation({
    required this.text,
    required this.explanation,
    required this.options,
  });
}

class AiTranslationService {
  static const String _modelName = 'gemini-3.1-flash-lite';
  static const int _maxRetries = 5;

  final FirebaseAI _ai = FirebaseAI.googleAI();

  Future<QuestionTranslation> translate(
      QuestionModel question, {
        String languageName = 'Macedonian (Cyrillic script)',
      }) async {
    final model = _ai.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _buildSchema(question.options.length),
        temperature: 0.2,
      ),
    );

    final prompt = _buildPrompt(question, languageName);

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response =
        await model.generateContent([Content.text(prompt)]);

        final raw = response.text;
        if (raw == null || raw.trim().isEmpty) {
          throw AiTranslationException('The AI returned an empty response.');
        }
        return _parse(raw, sourceOptionCount: question.options.length);
      } on FirebaseAIException catch (e) {
        final msg = e.message.toLowerCase();
        final isRateLimit = msg.contains('429') ||
            msg.contains('resource') ||
            msg.contains('quota') ||
            msg.contains('rate');

        if (isRateLimit && attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 20));
          continue;
        }
        throw AiTranslationException(e.message);
      } catch (e) {
        if (e is AiTranslationException) rethrow;
        throw AiTranslationException('Could not reach the AI service: $e');
      }
    }
    throw AiTranslationException('Failed after $_maxRetries attempts.');
  }

  Schema _buildSchema(int optionCount) {
    final properties = <String, Schema>{
      'text': Schema.string(description: 'The translated question.'),
      'explanation':
          Schema.string(description: 'The translated explanation.'),
    };

    if (optionCount > 0) {
      properties['options'] = Schema.array(
        items: Schema.string(),
        description:
            'The translated answer choices, in exactly the original order.',
        minItems: optionCount,
        maxItems: optionCount,
      );
    }

    return Schema.object(properties: properties);
  }

  String _buildPrompt(QuestionModel question, String languageName) {
    final payload = {
      'text': question.text,
      'explanation': question.explanation,
      if (question.options.isNotEmpty) 'options': question.options,
    };

    return '''
You are a professional translator localising a children's internet-safety quiz app into $languageName.

Translate ONLY the values in the JSON below from English to $languageName.
Rules:
- Keep the "options" array in the SAME ORDER. Do not add, remove, or reorder items.
- Use natural, age-appropriate language a child or teenager would understand.
- Keep well-known technical terms readable (e.g. "phishing" -> "фишинг", "spam" -> "спам").
- Do NOT translate proper nouns or brand names.

JSON to translate:
${const JsonEncoder.withIndent('  ').convert(payload)}

Return ONLY JSON matching the required schema.''';
  }

  QuestionTranslation _parse(String raw, {required int sourceOptionCount}) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw AiTranslationException('The AI response could not be read.');
    }
    if (decoded is! Map) {
      throw AiTranslationException('The AI response had an unexpected shape.');
    }

    final text = (decoded['text'] ?? '').toString().trim();
    final explanation = (decoded['explanation'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw AiTranslationException('The AI returned no question text.');
    }

    final options = (decoded['options'] as List?)
            ?.map((o) => o.toString().trim())
            .toList() ??
        const <String>[];


    if (options.length != sourceOptionCount) {
      throw AiTranslationException(
          'Option count changed: expected $sourceOptionCount, got ${options.length}.');
    }
    if (options.any((o) => o.isEmpty)) {
      throw AiTranslationException('The AI returned an empty answer choice.');
    }

    return QuestionTranslation(
      text: text,
      explanation: explanation,
      options: options,
    );
  }
}
