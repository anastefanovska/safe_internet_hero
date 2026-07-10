import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/enums.dart';
import '../models/question_model.dart';
import 'admin_widgets.dart';

/// Edits a single AI-generated draft [QuestionModel] that has **not** been saved
/// yet. Pushed as a screen; pops with the edited copy (or null if cancelled).
///
/// Category and topic are fixed for the whole generated batch, so this editor
/// only touches the per-question fields (text, options, correct answer,
/// explanation, difficulty). Built on `admin_widgets.dart` — it's admin
/// authoring UI, mirroring [QuestionAuthorForm] without the Firestore write.
class DraftQuestionEditorScreen extends StatefulWidget {
  final QuestionModel draft;
  const DraftQuestionEditorScreen({super.key, required this.draft});

  @override
  State<DraftQuestionEditorScreen> createState() =>
      _DraftQuestionEditorScreenState();
}

class _DraftQuestionEditorScreenState extends State<DraftQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _explanationCtrl;
  late final List<TextEditingController> _optCtrls;

  late int _correctIndex;
  late DifficultyLevel _difficulty;
  late QuestionType _type;

  bool get _isTrueFalse => _type == QuestionType.trueFalse;

  @override
  void initState() {
    super.initState();
    final q = widget.draft;
    _type = q.type;
    _textCtrl = TextEditingController(text: q.text);
    _explanationCtrl = TextEditingController(text: q.explanation);
    _optCtrls = List.generate(
      4,
      (i) => TextEditingController(
          text: i < q.options.length ? q.options[i] : ''),
    );
    _correctIndex =
        q.correctIndex.clamp(0, _type == QuestionType.trueFalse ? 1 : 3);
    _difficulty = q.difficulty;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  int get _points => switch (_difficulty) {
        DifficultyLevel.beginner => 10,
        DifficultyLevel.intermediate => 20,
        DifficultyLevel.advanced => 30,
      };

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isTrueFalse && _optCtrls.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fill in all 4 options',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
      return;
    }
    // copyWith, not a fresh QuestionModel: it carries the draft's translations
    // through so editing one language never drops the other.
    final updated = widget.draft.copyWith(
      text: _textCtrl.text.trim(),
      type: _type,
      options: _isTrueFalse
          ? const ['True', 'False']
          : _optCtrls.map((c) => c.text.trim()).toList(),
      correctIndex: _correctIndex,
      explanation: _explanationCtrl.text.trim(),
      difficulty: _difficulty,
      points: _points,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AdminHeader(title: 'Edit Draft'),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      // ── Difficulty ─────────────────────────────────────────
                      AdminCard(
                        title: 'Difficulty',
                        child: Row(children: [
                          Expanded(
                            child: AdminDifficultyTile(
                              label: 'Beginner',
                              color: AppColors.green,
                              selected:
                                  _difficulty == DifficultyLevel.beginner,
                              onTap: () => setState(
                                  () => _difficulty = DifficultyLevel.beginner),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AdminDifficultyTile(
                              label: 'Intermediate',
                              color: AppColors.orange,
                              selected:
                                  _difficulty == DifficultyLevel.intermediate,
                              onTap: () => setState(() =>
                                  _difficulty = DifficultyLevel.intermediate),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AdminDifficultyTile(
                              label: 'Advanced',
                              color: AppColors.red,
                              selected:
                                  _difficulty == DifficultyLevel.advanced,
                              onTap: () => setState(
                                  () => _difficulty = DifficultyLevel.advanced),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // ── Question & answers ─────────────────────────────────
                      AdminCard(
                        title: 'Question & Answers',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AdminLabel('Question text'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _textCtrl,
                                maxLines: 3,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                                decoration: AdminField.decoration(
                                    'Type your question here...'),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              if (_isTrueFalse) ...[
                                const AdminLabel('Correct answer'),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: AdminSelectTile(
                                      label: 'True',
                                      color: AppColors.green,
                                      selected: _correctIndex == 0,
                                      onTap: () =>
                                          setState(() => _correctIndex = 0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AdminSelectTile(
                                      label: 'False',
                                      color: AppColors.green,
                                      selected: _correctIndex == 1,
                                      onTap: () =>
                                          setState(() => _correctIndex = 1),
                                    ),
                                  ),
                                ]),
                              ] else ...[
                                const AdminLabel(
                                    'Options - tap letter to mark correct'),
                                const SizedBox(height: 8),
                                for (var i = 0; i < 4; i++) ...[
                                  AdminOptionField(
                                    controller: _optCtrls[i],
                                    letter:
                                        String.fromCharCode(65 + i), // A..D
                                    index: i,
                                    correctIndex: _correctIndex,
                                    onTap: () =>
                                        setState(() => _correctIndex = i),
                                  ),
                                  if (i < 3) const SizedBox(height: 8),
                                ],
                              ],
                              const SizedBox(height: 14),
                              const AdminLabel('Explanation'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _explanationCtrl,
                                maxLines: 3,
                                style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                                decoration: AdminField.decoration(
                                    'Why is this the correct answer?'),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      AdminPrimaryButton(label: 'Done', onTap: _save),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
