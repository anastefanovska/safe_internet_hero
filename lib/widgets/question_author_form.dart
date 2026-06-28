import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/category_model.dart';
import '../models/enums.dart';
import '../models/question_model.dart';
import '../models/topic_model.dart';
import '../services/questions_service.dart';
import '../services/topics_service.dart';
import 'admin_widgets.dart';

/// Shared question authoring form used by both the admin "Add Question" tab and
/// the moderator submission screen. When [submitAsPending] is true the question
/// is written with `status: pending` and stamped with [authorId] so an admin can
/// review it; otherwise it is saved live (approved) as before.
///
/// Built on `admin_widgets.dart` because it is authoring UI; the moderator
/// screen reuses it rather than importing admin widgets directly.
class QuestionAuthorForm extends StatefulWidget {
  final bool submitAsPending;
  final String authorId;

  const QuestionAuthorForm({
    super.key,
    this.submitAsPending = false,
    this.authorId = '',
  });

  @override
  State<QuestionAuthorForm> createState() => _QuestionAuthorFormState();
}

class _QuestionAuthorFormState extends State<QuestionAuthorForm> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _opt0Ctrl = TextEditingController();
  final _opt1Ctrl = TextEditingController();
  final _opt2Ctrl = TextEditingController();
  final _opt3Ctrl = TextEditingController();

  final _topicsService = TopicsService();
  final _questionService = QuestionService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  bool _loading = true;
  bool _saving = false;
  QuestionType _type = QuestionType.multipleChoice;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  int _correctIndex = 0;

  bool get _pending => widget.submitAsPending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _explanationCtrl.dispose();
    _opt0Ctrl.dispose();
    _opt1Ctrl.dispose();
    _opt2Ctrl.dispose();
    _opt3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await _topicsService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoryId = cats.isNotEmpty ? cats.first.id : null;
      });
      if (_categoryId != null) {
        await _loadTopics(_categoryId!);
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (mounted) setState(() => _loading = true);
    try {
      final topics = await _topicsService.getTopicsByCategory(catId);
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _topicId = topics.isNotEmpty ? topics.first.id : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    _textCtrl.clear();
    _explanationCtrl.clear();
    _opt0Ctrl.clear();
    _opt1Ctrl.clear();
    _opt2Ctrl.clear();
    _opt3Ctrl.clear();
    setState(() {
      _correctIndex = 0;
      _type = QuestionType.multipleChoice;
      _difficulty = DifficultyLevel.beginner;
    });
  }

  int get _points => _difficulty == DifficultyLevel.beginner
      ? 10
      : _difficulty == DifficultyLevel.intermediate
          ? 20
          : 30;

  List<String> get _options => _type == QuestionType.trueFalse
      ? ['True', 'False']
      : [
          _opt0Ctrl.text.trim(),
          _opt1Ctrl.text.trim(),
          _opt2Ctrl.text.trim(),
          _opt3Ctrl.text.trim()
        ];

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) {
      _snack('Select category and topic', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_type == QuestionType.multipleChoice) {
      if ([_opt0Ctrl, _opt1Ctrl, _opt2Ctrl, _opt3Ctrl]
          .any((c) => c.text.trim().isEmpty)) {
        _snack('Fill in all 4 options', isError: true);
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final question = QuestionModel(
        id: '',
        categoryId: _categoryId!,
        topicId: _topicId!,
        text: _textCtrl.text.trim(),
        type: _type,
        options: _options,
        correctIndex: _correctIndex,
        explanation: _explanationCtrl.text.trim(),
        difficulty: _difficulty,
        points: _points,
        status: _pending ? QuestionStatus.pending : QuestionStatus.approved,
        authorId: widget.authorId,
      );
      if (_pending) {
        await _questionService.submitPendingQuestion(question);
      } else {
        await _questionService.seedQuestions([question]);
      }
      if (!mounted) return;
      _clearForm();
      setState(() => _saving = false);
      _snack(_pending ? 'Question submitted for review!' : 'Question saved!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? AppColors.red : AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // ── Location ──────────────────────────────────────────────────────
          AdminCard(
            title: 'Location',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AdminLabel('Category'),
              const SizedBox(height: 8),
              AdminDropdown<String>(
                value: _categoryId,
                hint: 'Select category',
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.title)))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() {
                    _categoryId = val;
                    _topicId = null;
                  });
                  await _loadTopics(val);
                },
              ),
              const SizedBox(height: 12),
              const AdminLabel('Topic'),
              const SizedBox(height: 8),
              AdminDropdown<String>(
                value: _topicId,
                hint: 'Select topic',
                items: _topics
                    .map((t) =>
                        DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (val) => setState(() => _topicId = val),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Setup ─────────────────────────────────────────────────────────
          AdminCard(
            title: 'Setup',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AdminLabel('Type'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: AdminSelectTile(
                    label: 'Multiple Choice',
                    selected: _type == QuestionType.multipleChoice,
                    onTap: () => setState(() {
                      _type = QuestionType.multipleChoice;
                      _correctIndex = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminSelectTile(
                    label: 'True / False',
                    selected: _type == QuestionType.trueFalse,
                    onTap: () => setState(() {
                      _type = QuestionType.trueFalse;
                      _correctIndex = 0;
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const AdminLabel('Difficulty'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: AdminDifficultyTile(
                    label: 'Beginner',
                    color: AppColors.green,
                    selected: _difficulty == DifficultyLevel.beginner,
                    onTap: () =>
                        setState(() => _difficulty = DifficultyLevel.beginner),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdminDifficultyTile(
                    label: 'Intermediate',
                    color: AppColors.orange,
                    selected: _difficulty == DifficultyLevel.intermediate,
                    onTap: () => setState(
                        () => _difficulty = DifficultyLevel.intermediate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdminDifficultyTile(
                    label: 'Advanced',
                    color: AppColors.red,
                    selected: _difficulty == DifficultyLevel.advanced,
                    onTap: () =>
                        setState(() => _difficulty = DifficultyLevel.advanced),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Content ───────────────────────────────────────────────────────
          AdminCard(
            title: 'Question & Answers',
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const AdminLabel('Question text'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textCtrl,
                maxLines: 3,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: AdminField.decoration('Type your question here...'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              if (_type == QuestionType.multipleChoice) ...[
                const AdminLabel('Options - tap letter to mark correct'),
                const SizedBox(height: 8),
                AdminOptionField(
                    controller: _opt0Ctrl,
                    letter: 'A',
                    index: 0,
                    correctIndex: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 0)),
                const SizedBox(height: 8),
                AdminOptionField(
                    controller: _opt1Ctrl,
                    letter: 'B',
                    index: 1,
                    correctIndex: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 1)),
                const SizedBox(height: 8),
                AdminOptionField(
                    controller: _opt2Ctrl,
                    letter: 'C',
                    index: 2,
                    correctIndex: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 2)),
                const SizedBox(height: 8),
                AdminOptionField(
                    controller: _opt3Ctrl,
                    letter: 'D',
                    index: 3,
                    correctIndex: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 3)),
              ],
              if (_type == QuestionType.trueFalse) ...[
                const AdminLabel('Correct answer'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: AdminSelectTile(
                      label: 'True',
                      selected: _correctIndex == 0,
                      color: AppColors.green,
                      onTap: () => setState(() => _correctIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdminSelectTile(
                      label: 'False',
                      selected: _correctIndex == 1,
                      color: AppColors.green,
                      onTap: () => setState(() => _correctIndex = 1),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 14),
              const AdminLabel('Explanation'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _explanationCtrl,
                maxLines: 3,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration:
                    AdminField.decoration('Why is this the correct answer?'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Points chip ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              'This question awards $_points points',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          AdminPrimaryButton(
            label: _saving
                ? (_pending ? 'Submitting...' : 'Saving...')
                : (_pending ? 'Submit for review' : 'Save Question'),
            onTap: _saving ? () {} : _save,
          ),
        ],
      ),
    );
  }
}
