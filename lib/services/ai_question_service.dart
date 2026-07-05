import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/enums.dart';
import '../models/question_model.dart';

/// Thrown when generation fails. Carries a short, user-friendly [message] that
/// the admin UI can drop straight into a snackbar.
class AiGenerationException implements Exception {
  final String message;
  AiGenerationException(this.message);
  @override
  String toString() => message;
}

/// Generates draft quiz questions with Google's Gemini model through
/// **Firebase AI Logic** (the Gemini Developer API backend).
///
/// Why this design fits the project:
/// - The model is reached via Firebase's managed proxy, so **no API key ever
///   ships inside the app** — the key is provisioned and secured by Firebase,
///   and App Check guards the endpoint against abuse. This satisfies the "keys
///   never in the client" rule without standing up a Cloud Functions backend.
/// - It plugs into the existing `firebase_core` setup and follows the project's
///   one-class-per-service convention (mirrors [QuestionService]).
///
/// The service only *produces* drafts: it returns unsaved [QuestionModel]s
/// (category/topic come from the admin's selection). A fixed [QuestionType] /
/// [DifficultyLevel] is applied to the whole batch, or `null` lets the model
/// **mix** them per question. Admins review, edit and delete the drafts in the
/// UI, and only then are they written to Firestore through the normal
/// admin-only [QuestionService] — players never touch the AI.
class AiQuestionService {
  /// Fast, free-tier Gemini model. Swap this one constant to upgrade the model;
  /// nothing else in the app changes.
  static const String _modelName = 'gemini-2.5-flash';

  final FirebaseAI _ai = FirebaseAI.googleAI();

  /// Asks Gemini for [count] questions and returns them as unsaved
  /// [QuestionModel] drafts stamped with the given category/topic.
  ///
  /// - [type] fixes the question type for the whole batch; `null` = mixed
  ///   (the model tags each question as multiple-choice or true/false).
  /// - [difficulty] fixes difficulty for the batch; `null` = mixed (the model
  ///   varies difficulty and tags each question).
  /// - [avoidQuestions] are existing question texts the model must not repeat.
  ///
  /// Throws [AiGenerationException] with a friendly message on any network,
  /// parsing or content problem.
  Future<List<QuestionModel>> generateQuestions({
    required String categoryId,
    required String categoryTitle,
    required String topicId,
    required String topicName,
    required QuestionType? type,
    required DifficultyLevel? difficulty,
    required int count,
    String focus = '',
    List<String> avoidQuestions = const [],
  }) async {
    // The response shape depends on the batch settings (whether the model must
    // return per-question type/difficulty and how many options), so the model
    // is configured per call — creating it is cheap and does no network I/O.
    final model = _ai.generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _buildSchema(type: type, mixedDifficulty: difficulty == null),
        temperature: 0.9,
      ),
    );

    final prompt = _buildPrompt(
      categoryTitle: categoryTitle,
      topicName: topicName,
      type: type,
      difficulty: difficulty,
      count: count,
      focus: focus,
      avoidQuestions: avoidQuestions,
    );

    final GenerateContentResponse response;
    try {
      response = await model.generateContent([Content.text(prompt)]);
    } on FirebaseAIException catch (e) {
      // Surface the real reason so setup problems are diagnosable — e.g. the
      // Firebase AI Logic API not being enabled yet (ServiceApiNotEnabled),
      // an unsupported region, or an exceeded quota all carry a clear message.
      throw AiGenerationException(e.message);
    } catch (e) {
      throw AiGenerationException('Could not reach the AI service: $e');
    }

    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw AiGenerationException(
          'The AI returned an empty response. Please try again.');
    }

    return _parse(
      raw,
      categoryId: categoryId,
      topicId: topicId,
      fixedType: type,
      fixedDifficulty: difficulty,
    );
  }

  /// Builds the structured-output contract for the current batch settings.
  Schema _buildSchema({
    required QuestionType? type,
    required bool mixedDifficulty,
  }) {
    final properties = <String, Schema>{
      'text': Schema.string(
          description: 'The quiz question or statement, one clear sentence.'),
      'explanation': Schema.string(
          description:
              'One or two friendly sentences on why the answer is correct.'),
      'correctIndex': Schema.integer(
        description:
            'Zero-based index of the correct option (for true/false: 0 = true, 1 = false).',
        minimum: 0,
        // Pure true/false batches only ever need 0 or 1.
        maximum: type == QuestionType.trueFalse ? 1 : 3,
      ),
    };
    final optional = <String>[];

    // Only ask the model to tag the type when the batch is mixed.
    if (type == null) {
      properties['type'] = Schema.enumString(
        enumValues: [QuestionType.multipleChoice.name, QuestionType.trueFalse.name],
        description: 'Question type for this item.',
      );
    }
    // Only ask the model to tag difficulty when the batch is mixed.
    if (mixedDifficulty) {
      properties['difficulty'] = Schema.enumString(
        enumValues: DifficultyLevel.values.map((d) => d.name).toList(),
        description: 'Difficulty for this item.',
      );
    }

    // Options are needed for multiple-choice (exactly 4) and for mixed batches
    // (2-4, optional so true/false items may omit them). Pure true/false
    // batches don't need options at all — they're always ["True", "False"].
    if (type == QuestionType.multipleChoice) {
      properties['options'] = Schema.array(
        items: Schema.string(),
        description: 'Exactly four answer choices.',
        minItems: 4,
        maxItems: 4,
      );
    } else if (type == null) {
      properties['options'] = Schema.array(
        items: Schema.string(),
        description:
            'Four answer choices for multiple-choice items; omit for true/false.',
        minItems: 2,
        maxItems: 4,
      );
      optional.add('options');
    }

    return Schema.object(properties: {
      'questions': Schema.array(
        items: Schema.object(
          properties: properties,
          optionalProperties: optional,
        ),
      ),
    });
  }

  String _buildPrompt({
    required String categoryTitle,
    required String topicName,
    required QuestionType? type,
    required DifficultyLevel? difficulty,
    required int count,
    required String focus,
    required List<String> avoidQuestions,
  }) {
    final levelLine = difficulty == null
        ? 'Vary the difficulty across the batch (beginner, intermediate and advanced) and set each question\'s "difficulty" field accordingly.'
        : 'All questions are ${difficulty.name}-level.';

    final typeLine = switch (type) {
      QuestionType.multipleChoice =>
        'Every question is multiple-choice with exactly 4 options and one correct answer; "correctIndex" is the 0-based position (0-3), varied across questions.',
      QuestionType.trueFalse =>
        'Every question is a true/false statement. Do NOT provide options. Set "correctIndex" to 0 if the statement is TRUE or 1 if it is FALSE, with a roughly even mix of true and false.',
      null =>
        'Mix multiple-choice and true/false questions. For each, set "type" to "${QuestionType.multipleChoice.name}" or "${QuestionType.trueFalse.name}". Multiple-choice items need exactly 4 options with "correctIndex" 0-3; true/false items omit options and use "correctIndex" 0 (true) or 1 (false).',
    };

    final focusLine =
        focus.trim().isEmpty ? '' : '\n- Focus specifically on: ${focus.trim()}.';

    // Keep the prompt bounded — a recent sample is enough to steer away from
    // duplicates without ballooning the request.
    final avoidLine = avoidQuestions.isEmpty
        ? ''
        : '\n\nDo NOT repeat or closely paraphrase any of these existing questions:\n'
            '${avoidQuestions.take(40).map((q) => '- $q').join('\n')}';

    return '''
You are an expert online-safety educator writing quiz questions for "Safe Internet Hero", an app that teaches children to use the internet safely.

Write $count question(s) about "$topicName" (category: "$categoryTitle").

Requirements:
- $typeLine
- $levelLine
- Keep all options plausible and similar in length; avoid "all of the above" / "none of the above".
- The explanation teaches why the correct answer is right, in one or two friendly sentences.
- Content must be accurate, age-appropriate, encouraging, and never frightening or harmful.
- Do not duplicate questions within this batch.$focusLine$avoidLine

Return ONLY JSON matching the required schema.''';
  }

  /// Validates and converts the model's JSON into drafts. Malformed items are
  /// skipped rather than aborting the whole batch; only a total failure throws.
  List<QuestionModel> _parse(
    String raw, {
    required String categoryId,
    required String topicId,
    required QuestionType? fixedType,
    required DifficultyLevel? fixedDifficulty,
  }) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw AiGenerationException(
          'The AI response could not be read. Please try again.');
    }

    final list = decoded is Map ? decoded['questions'] : decoded;
    if (list is! List) {
      throw AiGenerationException(
          'The AI response was missing questions. Please try again.');
    }

    final drafts = <QuestionModel>[];
    for (final item in list) {
      if (item is! Map) continue;
      final text = (item['text'] ?? '').toString().trim();
      final explanation = (item['explanation'] ?? '').toString().trim();
      if (text.isEmpty || explanation.isEmpty) continue;

      // Resolve type & difficulty: a fixed batch value wins; otherwise trust the
      // model's per-item tag (falling back to safe defaults).
      final type = fixedType ??
          QuestionType.values.firstWhere(
            (t) => t.name == item['type'],
            orElse: () => QuestionType.multipleChoice,
          );
      final difficulty = fixedDifficulty ??
          DifficultyLevel.values.firstWhere(
            (d) => d.name == item['difficulty'],
            orElse: () => DifficultyLevel.beginner,
          );

      final List<String> options;
      final int correctIndex;
      if (type == QuestionType.trueFalse) {
        options = const ['True', 'False'];
        // Anything other than an explicit 0 means "false".
        final idx = item['correctIndex'] is num
            ? (item['correctIndex'] as num).toInt()
            : 0;
        correctIndex = idx <= 0 ? 0 : 1;
      } else {
        final opts = (item['options'] as List?)
                ?.map((o) => o.toString().trim())
                .where((o) => o.isNotEmpty)
                .toList() ??
            const <String>[];
        if (opts.length != 4) continue; // multiple-choice needs exactly 4
        options = opts;
        var idx =
            item['correctIndex'] is num ? (item['correctIndex'] as num).toInt() : 0;
        if (idx < 0 || idx > 3) idx = 0;
        correctIndex = idx;
      }

      drafts.add(QuestionModel(
        id: '',
        categoryId: categoryId,
        topicId: topicId,
        text: text,
        type: type,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
        difficulty: difficulty,
        points: _pointsFor(difficulty),
        // Admin-reviewed content: approved with an empty authorId, exactly like
        // questions created from the admin "Add Question" tab.
        status: QuestionStatus.approved,
      ));
    }

    if (drafts.isEmpty) {
      throw AiGenerationException(
          'The AI did not return any usable questions. Try again or adjust the topic.');
    }
    return drafts;
  }

  /// Mirrors the points ladder used by the manual authoring form.
  int _pointsFor(DifficultyLevel d) => switch (d) {
        DifficultyLevel.beginner => 10,
        DifficultyLevel.intermediate => 20,
        DifficultyLevel.advanced => 30,
      };
}
