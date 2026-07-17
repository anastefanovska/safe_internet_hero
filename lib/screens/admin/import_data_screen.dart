import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({super.key});

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen>
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              decoration: const BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4)),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFFFFF0C2), width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.blueDark, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).importTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // â”€â”€ Tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabs,
                labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, fontSize: 14),
                unselectedLabelStyle:
                    GoogleFonts.nunito(fontWeight: FontWeight.w600),
                labelColor: AppColors.blue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.blue,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: AppLocalizations.of(context).importTabQuestions),
                  Tab(text: AppLocalizations.of(context).importTabArticles),
                ],
              ),
            ),

            // â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: TabBarView(
                    controller: _tabs,
                    children: const [
                      _ImportTab(mode: _ImportMode.questions),
                      _ImportTab(mode: _ImportMode.articles),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _ImportMode { questions, articles }

class _ImportTab extends StatefulWidget {
  final _ImportMode mode;
  const _ImportTab({required this.mode});

  @override
  State<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends State<_ImportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _controller = TextEditingController();

  // Parsed state
  List<QuestionModel> _questions = [];
  List<LearningContentModel> _articles = [];
  String? _parseError;
  bool _uploading = false;
  String? _uploadResult;
  bool _uploadOk = false;

  bool get _isQuestions => widget.mode == _ImportMode.questions;

  void _parse() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _questions = [];
        _articles = [];
        _parseError = null;
        _uploadResult = null;
      });
      return;
    }

    try {
      final decoded = jsonDecode(text);
      final List<dynamic> list =
          decoded is List ? decoded : [decoded];

      if (_isQuestions) {
        final parsed = list
            .map((e) => QuestionModel.fromMap(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _questions = parsed;
          _parseError = null;
          _uploadResult = null;
        });
      } else {
        final parsed = list.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return LearningContentModel.fromMap({
            'id': '',
            'categoryId': map['categoryId'] ?? '',
            'topicId': map['topicId'] ?? '',
            'title': map['title'] ?? '',
            'content': map['body'] ?? map['content'] ?? '',
            'description': (map['keyPoints'] as List?)
                    ?.map((k) => '- $k')
                    .join('\n') ??
                map['description'] ?? '',
            'type': map['type'] ?? 'article',
            'thumbnailUrl': map['thumbnailUrl'] ?? '',
            'readTimeMinutes': map['readTimeMinutes'] ?? 3,
          });
        }).toList();
        setState(() {
          _articles = parsed;
          _parseError = null;
          _uploadResult = null;
        });
      }
    } catch (e) {
      setState(() {
        _questions = [];
        _articles = [];
        _parseError = AppLocalizations.of(context).importJsonError(e.toString().split('\n').first);
        _uploadResult = null;
      });
    }
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context);
    final count = _isQuestions ? _questions.length : _articles.length;
    if (count == 0) return;

    setState(() {
      _uploading = true;
      _uploadResult = null;
    });

    try {
      if (_isQuestions) {
        await QuestionService().seedQuestions(_questions);
      } else {
        await LearningService().seedContent(_articles);
      }
      setState(() {
        _uploadResult = _isQuestions
            ? l10n.importUploadedQuestions(count)
            : l10n.importUploadedArticles(count);
        _uploadOk = true;
        _questions = [];
        _articles = [];
        _controller.clear();
      });
    } catch (e) {
      setState(() {
        _uploadResult = l10n.importFailed(e.toString().split('\n').first);
        _uploadOk = false;
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final count = _isQuestions ? _questions.length : _articles.length;
    final hasItems = count > 0;
    final resultIsSuccess = _uploadResult != null && _uploadOk;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // â”€â”€ Instructions card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.blue.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.blue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isQuestions
                      ? l10n.importInstructionsQuestions
                      : l10n.importInstructionsArticles,
                  style: GoogleFonts.nunito(
                    color: AppColors.blueDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Topic ID reference ────────────────────────────────────────
        const _TopicIdReference(),

        const SizedBox(height: 16),

        // ── Paste area ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _parseError != null
                  ? AppColors.red
                  : hasItems
                      ? AppColors.blue
                      : AppColors.border,
              width: _parseError != null || hasItems ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _controller,
            maxLines: 12,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  '[\n  {\n    "categoryId": "passwords",\n    "topicId": "strong_passwords",\n    ...\n  }\n]',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
            onChanged: (_) => _parse(),
          ),
        ),

        const SizedBox(height: 10),

        // â”€â”€ Parse status â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_parseError != null)
          _StatusBanner(
            icon: Icons.error_outline_rounded,
            text: _parseError!,
            color: AppColors.red,
            bg: AppColors.redLight,
          )
        else if (hasItems)
          _StatusBanner(
            icon: Icons.check_circle_outline_rounded,
            text: _isQuestions ? l10n.importReadyQuestions(count) : l10n.importReadyArticles(count),
            color: AppColors.green,
            bg: AppColors.greenLight,
          ),

        // â”€â”€ Upload result â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_uploadResult != null) ...[
          const SizedBox(height: 10),
          _StatusBanner(
            icon: resultIsSuccess
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            text: _uploadResult!,
            color: resultIsSuccess ? AppColors.green : AppColors.red,
            bg: resultIsSuccess ? AppColors.greenLight : AppColors.redLight,
          ),
        ],

        const SizedBox(height: 20),

        // â”€â”€ Preview list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (hasItems) ...[
          Text(
            l10n.importPreview,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ..._buildPreview(),
          const SizedBox(height: 20),
        ],

        // â”€â”€ Upload button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasItems && !_uploading ? _upload : null,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(
              _uploading
                  ? l10n.importUploading
                  : (_isQuestions ? l10n.importUploadBtnQuestions(count) : l10n.importUploadBtnArticles(count)),
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreview() {
    if (_isQuestions) {
      final items = <Widget>[
        ..._questions.take(20).map((q) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DiffBadge(q.difficulty.name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${q.categoryId} / ${q.topicId}  -  ${q.points} pts',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if (_questions.length > 20)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${_questions.length - 20} more questions...',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ];
      return items;
    } else {
      return _articles.take(20).map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article_rounded,
                    color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.categoryId} / ${a.topicId}  -  ${a.readTimeMinutes} min read',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList();
    }
  }
}

// â”€â”€â”€ Difficulty badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DiffBadge extends StatelessWidget {
  final String level;
  const _DiffBadge(this.level);

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'intermediate' => AppColors.orange,
      'advanced' => AppColors.red,
      _ => AppColors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level[0].toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Status banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  const _StatusBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Topic ID reference ───────────────────────────────────────────────────────
// Shows every category and its topic IDs so the admin knows what to put in JSON.

class _TopicIdReference extends StatefulWidget {
  const _TopicIdReference();

  @override
  State<_TopicIdReference> createState() => _TopicIdReferenceState();
}

class _TopicIdReferenceState extends State<_TopicIdReference> {
  bool _expanded = false;
  List<CategoryModel> _categories = [];
  Map<String, List<TopicModel>> _topicsMap = {};
  bool _loading = false;

  Future<void> _load() async {
    if (_categories.isNotEmpty) return;
    setState(() => _loading = true);
    final svc = TopicsService();
    final cats = await svc.getCategories();
    final map = <String, List<TopicModel>>{};
    for (final c in cats) {
      map[c.id] = await svc.getTopicsByCategory(c.id);
    }
    if (mounted) {
      setState(() {
        _categories = cats;
        _topicsMap = map;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _load();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              const Icon(Icons.tag_rounded, color: AppColors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).importTopicIdRef,
                  style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.blue, size: 18),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(
                              color: AppColors.blue, strokeWidth: 2),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 1, color: AppColors.border),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalizations.of(context).importUseExactIds,
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._categories.map((cat) => _CategoryBlock(
                                  category: cat,
                                  topics: _topicsMap[cat.id] ?? [],
                                )),
                          ],
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  const _CategoryBlock({required this.category, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('categoryId: ',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: category.id));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalizations.of(context).importCopied(category.id),
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.blue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  duration: const Duration(seconds: 1),
                ));
              },
              child: Text(
                '"${category.id}"',
                style: GoogleFonts.nunito(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ]),
        if (topics.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...topics.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const SizedBox(width: 12),
                  Text('topicId: ',
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: t.id));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context).importCopied(t.id),
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700)),
                          backgroundColor: AppColors.blue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          duration: const Duration(seconds: 1),
                        ));
                      },
                      child: Text(
                        '"${t.id}"  (${t.name})',
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ]),
              )),
        ],
      ]),
    );
  }
}
