import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/enums.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';
import '../../widgets/question_author_form.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(
            title: AppLocalizations.of(context).adminQuestions,
            tabController: _tabs,
            tabs: [AppLocalizations.of(context).adminAddQuestion, AppLocalizations.of(context).adminAllQuestions],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    QuestionAuthorForm(),
                    _QuestionsBrowser(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Questions browser (search + category/topic filters + list) ──────────────

/// A fast way to find and manage questions: type to search, narrow by category
/// then topic with chips, and act inline (edit / delete) on each row. Replaces
/// the old endless scroll. Categories/topics are loaded once; questions stream
/// live and are filtered in Dart.
class _QuestionsBrowser extends StatefulWidget {
  const _QuestionsBrowser();

  @override
  State<_QuestionsBrowser> createState() => _QuestionsBrowserState();
}

class _QuestionsBrowserState extends State<_QuestionsBrowser> {
  final _searchCtrl = TextEditingController();
  final _topicsService = TopicsService();

  String _search = '';
  String? _categoryId; // null = all categories
  String? _topicId; // null = all topics

  List<CategoryModel> _categories = [];
  List<TopicModel> _allTopics = [];
  bool _loadingFilters = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final cats = await _topicsService.getCategories();
      final topics = await _topicsService.getAllTopics();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _allTopics = topics;
        _loadingFilters = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFilters = false);
    }
  }

  String _categoryTitle(String id) {
    for (final c in _categories) {
      if (c.id == id) return c.title;
    }
    return id;
  }

  String _topicName(String id) {
    for (final t in _allTopics) {
      if (t.id == id) return t.name;
    }
    return id;
  }

  List<TopicModel> get _topicsForCategory => _categoryId == null
      ? const []
      : _allTopics.where((t) => t.categoryId == _categoryId).toList();

  Future<void> _delete(BuildContext context, QuestionModel q) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.adminDeleteQuestion,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(q.text,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel,
                  style: GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete,
                  style: GoogleFonts.nunito(
                      color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await QuestionService().deleteQuestion(q.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.adminDeleted,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: AppColors.blue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ));
  }

  void _edit(BuildContext context, QuestionModel q) => Navigator.push(
        context,
        AppPageRoute(builder: (_) => _EditQuestionScreen(question: q)),
      );

  List<QuestionModel> _applyFilters(List<QuestionModel> all) {
    final query = _search.trim().toLowerCase();
    return all.where((q) {
      if (_categoryId != null && q.categoryId != _categoryId) return false;
      if (_topicId != null && q.topicId != _topicId) return false;
      if (query.isNotEmpty) {
        final inText = q.text.toLowerCase().contains(query);
        final inOptions =
            q.options.any((o) => o.toLowerCase().contains(query));
        if (!inText && !inOptions) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // ── Search ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AdminSearchField(
            controller: _searchCtrl,
            hint: l10n.adminSearchQuestions,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        // ── Category / topic dropdowns ────────────────────────────────────
        if (!_loadingFilters && _categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(children: [
              Expanded(
                child: AdminFilterDropdown(
                  icon: Icons.category_outlined,
                  value: _categoryId ?? 'all',
                  options: [
                    (value: 'all', label: l10n.adminAllCategories),
                    for (final c in _categories) (value: c.id, label: c.title),
                  ],
                  onChanged: (v) => setState(() {
                    _categoryId = v == 'all' ? null : v;
                    _topicId = null;
                  }),
                ),
              ),
              // Topic narrows within the chosen category.
              if (_categoryId != null && _topicsForCategory.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AdminFilterDropdown(
                    icon: Icons.tag_rounded,
                    value: _topicId ?? 'all',
                    options: [
                      (value: 'all', label: l10n.adminAllTopics),
                      for (final t in _topicsForCategory)
                        (value: t.id, label: t.name),
                    ],
                    onChanged: (v) =>
                        setState(() => _topicId = v == 'all' ? null : v),
                  ),
                ),
              ],
            ]),
          ),
        // ── Results ───────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<QuestionModel>>(
            stream: QuestionService().watchAllQuestions(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.blue));
              }
              if (snap.data!.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.quiz_rounded,
                  title: l10n.adminNoQuestions,
                  subtitle: l10n.adminNoQuestionsSub,
                );
              }
              final items = _applyFilters(snap.data!);
              if (items.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.adminNoMatches,
                  subtitle: l10n.adminNoMatchesSub,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 16, 6),
                    child: Text(
                      '${items.length} question${items.length == 1 ? '' : 's'}',
                      style: GoogleFonts.nunito(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _QuestionRow(
                        question: items[i],
                        categoryTitle: _categoryTitle(items[i].categoryId),
                        topicName: _topicName(items[i].topicId),
                        onEdit: () => _edit(context, items[i]),
                        onDelete: () => _delete(context, items[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One compact, scannable question row with inline edit + delete.
class _QuestionRow extends StatelessWidget {
  final QuestionModel question;
  final String categoryTitle;
  final String topicName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuestionRow({
    required this.question,
    required this.categoryTitle,
    required this.topicName,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
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
              AdminBadge(text: diffLabel, color: diffColor),
              AdminBadge(
                  text: q.type == QuestionType.trueFalse ? l10n.badgeTF : l10n.badgeMCQ,
                  color: AppColors.blue),
              if (q.status == QuestionStatus.rejected)
                AdminBadge(text: l10n.statusRejected.toUpperCase(), color: AppColors.red),
            ]),
            const SizedBox(height: 6),
            Text(q.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.folder_outlined,
                  color: AppColors.textLight, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text('$categoryTitle • $topicName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        color: AppColors.textLight, fontSize: 11.5)),
              ),
            ]),
          ]),
        ),
        // Inline actions — edit and delete in one tap each.
        IconButton(
          tooltip: l10n.commonEdit,
          icon:
              const Icon(Icons.edit_outlined, color: AppColors.blue, size: 19),
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
    );
  }
}

/// Hosts the shared authoring form pre-filled to edit an existing question.
/// Saving updates it in place (status preserved) and pops back.
class _EditQuestionScreen extends StatelessWidget {
  final QuestionModel question;
  const _EditQuestionScreen({required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(title: AppLocalizations.of(context).adminEditQuestion),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: QuestionAuthorForm(
                  editQuestion: question,
                  authorId: question.authorId,
                  onSubmitted: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

