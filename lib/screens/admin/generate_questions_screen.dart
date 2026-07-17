import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/enums.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/ai_question_service.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/draft_question_editor.dart';

/// Admin-only "Generate with AI" tool. The admin picks a category + topic,
/// difficulty, age group and how many questions, then Gemini (via Firebase AI
/// Logic) drafts them. Nothing is saved until the admin reviews, edits/deletes
/// and taps Save — every generated question then lands in the existing
/// `questions` collection as approved admin content.
class GenerateQuestionsScreen extends StatefulWidget {
  const GenerateQuestionsScreen({super.key});

  @override
  State<GenerateQuestionsScreen> createState() =>
      _GenerateQuestionsScreenState();
}

class _GenerateQuestionsScreenState extends State<GenerateQuestionsScreen> {
  final _topicsService = TopicsService();
  final _aiService = AiQuestionService();
  final _focusCtrl = TextEditingController();

  // ── Config ────────────────────────────────────────────────────────────────
  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  // null = mixed (the model picks a type / difficulty per question).
  QuestionType? _type = QuestionType.multipleChoice;
  DifficultyLevel? _difficulty = DifficultyLevel.beginner;
  int _count = 5;
  static const _countOptions = [3, 5, 8, 10];

  bool _loadingFilters = true;
  bool _generating = false;
  bool _saving = false;

  /// Generated drafts awaiting review. Null while still on the config step.
  List<QuestionModel>? _drafts;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final cats = await _topicsService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _categoryId = cats.isNotEmpty ? cats.first.id : null;
        _loadingFilters = _categoryId != null;
      });
      if (_categoryId != null) await _loadTopics(_categoryId!);
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (mounted) setState(() => _loadingFilters = true);
    try {
      final topics = await _topicsService.getTopicsByCategory(catId);
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _topicId = topics.isNotEmpty ? topics.first.id : null;
        _loadingFilters = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  CategoryModel? get _category {
    for (final c in _categories) {
      if (c.id == _categoryId) return c;
    }
    return null;
  }

  TopicModel? get _topic {
    for (final t in _topics) {
      if (t.id == _topicId) return t;
    }
    return null;
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context);
    final category = _category;
    final topic = _topic;
    if (category == null || topic == null) {
      _snack(l10n.genSelectCategoryTopic, isError: true);
      return;
    }
    setState(() => _generating = true);
    try {
      // Pull existing question texts for this topic so the model doesn't repeat
      // them. Non-fatal: if it fails we just generate without the de-dup hint.
      List<String> existing = const [];
      try {
        existing = await QuestionService().getExistingQuestionTexts(
          categoryId: category.id,
          topicId: topic.id,
        );
      } catch (_) {}
      final drafts = await _aiService.generateQuestions(
        categoryId: category.id,
        categoryTitle: category.title,
        topicId: topic.id,
        topicName: topic.name,
        type: _type,
        difficulty: _difficulty,
        count: _count,
        focus: _focusCtrl.text,
        avoidQuestions: existing,
      );
      if (!mounted) return;
      setState(() {
        _drafts = drafts;
        _generating = false;
      });
    } on AiGenerationException catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      _snack(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      _snack(AppLocalizations.of(context).genSomethingWrong, isError: true);
    }
  }

  Future<void> _editDraft(int index) async {
    final edited = await Navigator.push<QuestionModel>(
      context,
      AppPageRoute(
          builder: (_) => DraftQuestionEditorScreen(draft: _drafts![index])),
    );
    if (edited != null && mounted) {
      setState(() => _drafts![index] = edited);
    }
  }

  void _deleteDraft(int index) => setState(() => _drafts!.removeAt(index));

  Future<void> _saveAll() async {
    final drafts = _drafts;
    if (drafts == null || drafts.isEmpty) return;
    setState(() => _saving = true);
    try {
      await QuestionService().seedQuestions(drafts);
      if (!mounted) return;
      _snack(AppLocalizations.of(context).genSaved(drafts.length));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(AppLocalizations.of(context).genCouldNotSave, isError: true);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(title: _drafts == null ? AppLocalizations.of(context).adminGenerateAi : AppLocalizations.of(context).genReview),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: _generating
                    ? const _GeneratingState()
                    : (_drafts == null ? _buildConfig() : _buildPreview()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: configuration ──────────────────────────────────────────────────
  Widget _buildConfig() {
    final l10n = AppLocalizations.of(context);
    if (_loadingFilters) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }
    if (_categories.isEmpty) {
      return AdminEmptyState(
        icon: Icons.category_outlined,
        title: l10n.ctNoCategories,
        subtitle: l10n.genNoCategoriesSub,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        AdminCard(
          title: l10n.formTopic,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminLabel(l10n.formCategory),
            const SizedBox(height: 8),
            AdminDropdown<String>(
              value: _categoryId,
              hint: l10n.formSelectCategory,
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
            AdminLabel(l10n.formTopic),
            const SizedBox(height: 8),
            AdminDropdown<String>(
              value: _topicId,
              hint: l10n.formSelectTopic,
              items: _topics
                  .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                  .toList(),
              onChanged: (val) => setState(() => _topicId = val),
            ),
            const SizedBox(height: 12),
            AdminLabel(l10n.genFocus),
            const SizedBox(height: 8),
            AdminField(
              controller: _focusCtrl,
              hint: l10n.genFocusHint,
            ),
          ]),
        ),
        const SizedBox(height: 12),
        AdminCard(
          title: l10n.genQuestionType,
          child: IntrinsicHeight(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AdminSelectTile(
                      label: l10n.formMultipleChoice,
                      selected: _type == QuestionType.multipleChoice,
                      onTap: () => setState(
                          () => _type = QuestionType.multipleChoice),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminSelectTile(
                      label: l10n.formTrueFalse,
                      selected: _type == QuestionType.trueFalse,
                      onTap: () =>
                          setState(() => _type = QuestionType.trueFalse),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminSelectTile(
                      label: l10n.genMixed,
                      selected: _type == null,
                      onTap: () => setState(() => _type = null),
                    ),
                  ),
                ]),
          ),
        ),
        const SizedBox(height: 12),
        AdminCard(
          title: l10n.formDifficulty,
          child: IntrinsicHeight(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AdminDifficultyTile(
                      label: l10n.formBeginner,
                      color: AppColors.green,
                      selected: _difficulty == DifficultyLevel.beginner,
                      onTap: () => setState(
                          () => _difficulty = DifficultyLevel.beginner),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminDifficultyTile(
                      label: l10n.formIntermediate,
                      color: AppColors.orange,
                      selected: _difficulty == DifficultyLevel.intermediate,
                      onTap: () => setState(
                          () => _difficulty = DifficultyLevel.intermediate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminDifficultyTile(
                      label: l10n.formAdvanced,
                      color: AppColors.red,
                      selected: _difficulty == DifficultyLevel.advanced,
                      onTap: () => setState(
                          () => _difficulty = DifficultyLevel.advanced),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AdminDifficultyTile(
                      label: l10n.genMixed,
                      color: AppColors.blue,
                      selected: _difficulty == null,
                      onTap: () => setState(() => _difficulty = null),
                    ),
                  ),
                ]),
          ),
        ),
        const SizedBox(height: 12),
        AdminCard(
          title: l10n.genHowMany,
          child: Row(children: [
            for (final n in _countOptions) ...[
              Expanded(
                child: AdminSelectTile(
                  label: '$n',
                  selected: _count == n,
                  onTap: () => setState(() => _count = n),
                ),
              ),
              if (n != _countOptions.last) const SizedBox(width: 8),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        AdminPrimaryButton(label: l10n.genGenerateButton, onTap: _generate),
        const SizedBox(height: 12),
        _AiDisclaimer(),
      ],
    );
  }

  // ── Step 2: preview / review ────────────────────────────────────────────────
  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context);
    final drafts = _drafts!;
    if (drafts.isEmpty) {
      return Column(children: [
        Expanded(
          child: AdminEmptyState(
            icon: Icons.inbox_rounded,
            title: l10n.genNothingLeft,
            subtitle: l10n.genNothingLeftSub,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: AdminSecondaryButton(
            label: l10n.genStartOver,
            onTap: () => setState(() => _drafts = null),
          ),
        ),
      ]);
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: drafts.length,
            itemBuilder: (context, i) => _DraftCard(
              index: i,
              question: drafts[i],
              onEdit: () => _editDraft(i),
              onDelete: () => _deleteDraft(i),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(children: [
            Expanded(
              child: AdminSecondaryButton(
                label: l10n.genDiscard,
                onTap: _saving ? () {} : () => setState(() => _drafts = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminPrimaryButton(
                label: _saving ? l10n.formSaving : l10n.genSaveCount(drafts.length),
                onTap: _saving ? () {} : _saveAll,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

/// A generated-question preview card with inline edit + delete.
class _DraftCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DraftCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = question;
    final diffColor = q.difficulty == DifficultyLevel.beginner
        ? AppColors.green
        : q.difficulty == DifficultyLevel.intermediate
            ? AppColors.orange
            : AppColors.red;
    final diffLabel = switch (q.difficulty) {
      DifficultyLevel.beginner => l10n.formBeginner,
      DifficultyLevel.intermediate => l10n.formIntermediate,
      DifficultyLevel.advanced => l10n.formAdvanced,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AdminBadge(text: 'Q${index + 1}', color: AppColors.blue),
              AdminBadge(text: diffLabel, color: diffColor),
              AdminBadge(
                  text: q.type == QuestionType.trueFalse ? l10n.badgeTF : l10n.badgeMCQ,
                  color: AppColors.textSecondary),
            ]),
            const SizedBox(height: 8),
            Text(q.text,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        i == q.correctIndex
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 16,
                        color: i == q.correctIndex
                            ? AppColors.green
                            : AppColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(q.options[i],
                            style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: i == q.correctIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == q.correctIndex
                                    ? AppColors.greenDark
                                    : AppColors.textSecondary)),
                      ),
                    ]),
              ),
            const SizedBox(height: 6),
            Text(q.explanation,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textLight)),
          ]),
        ),
        Column(children: [
          IconButton(
            tooltip: l10n.commonEdit,
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.blue, size: 19),
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.red, size: 19),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ]),
      ]),
    );
  }
}

/// Full-screen busy state shown while Gemini is generating.
class _GeneratingState extends StatelessWidget {
  const _GeneratingState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: AppColors.blue),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context).genGenerating,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(AppLocalizations.of(context).genGeneratingSub,
              style: GoogleFonts.nunito(
                  fontSize: 13, color: AppColors.textLight)),
        ]),
      );
}

/// Reminder that AI drafts still need a human check before saving.
class _AiDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blueLight,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppColors.blue.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.blue, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).genDisclaimer,
              style: GoogleFonts.nunito(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ]),
      );
}
