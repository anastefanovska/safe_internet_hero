import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/ai_translation_service.dart';
import '../../services/learning_service.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class TranslateQuestionsScreen extends StatefulWidget {
  const TranslateQuestionsScreen({super.key});

  @override
  State<TranslateQuestionsScreen> createState() =>
      _TranslateQuestionsScreenState();
}

class _TranslateQuestionsScreenState extends State<TranslateQuestionsScreen> {
  static const _targetLang = 'mk';

  final _questionService = QuestionService();
  final _topicsService = TopicsService();
  final _learningService = LearningService();
  final _aiService = AiTranslationService();

  List<QuestionModel>? _questions;
  List<TopicModel>? _topics;
  List<LearningContentModel>? _content;
  String? _loadError;

  bool _running = false;
  bool _cancelled = false;
  int _processed = 0;
  int _translated = 0;
  final List<String> _failures = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _topics = null;
      _content = null;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _questionService.getAllQuestionsForTranslation(),
        _topicsService.getAllTopicsForTranslation(),
        _learningService.getAllContentForTranslation(),
      ]);
      if (!mounted) return;
      setState(() {
        _questions = results[0] as List<QuestionModel>;
        _topics = results[1] as List<TopicModel>;
        _content = results[2] as List<LearningContentModel>;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  bool get _loaded =>
      _questions != null && _topics != null && _content != null;

  List<QuestionModel> get _pendingQuestions =>
      _questions?.where((q) => !q.hasTranslation(_targetLang)).toList() ??
      const [];
  List<TopicModel> get _pendingTopics =>
      _topics?.where((t) => !t.hasTranslation(_targetLang)).toList() ?? const [];
  List<LearningContentModel> get _pendingContent =>
      _content?.where((c) => !c.hasTranslation(_targetLang)).toList() ??
      const [];

  int get _total =>
      (_questions?.length ?? 0) +
      (_topics?.length ?? 0) +
      (_content?.length ?? 0);
  int get _pendingCount =>
      _pendingQuestions.length + _pendingTopics.length + _pendingContent.length;

  Future<void> _run() async {
    final total = _pendingCount;
    if (total == 0) return;

    setState(() {
      _running = true;
      _cancelled = false;
      _processed = 0;
      _translated = 0;
      _failures.clear();
    });

    // Questions
    for (final question in _pendingQuestions) {
      if (_cancelled || !mounted) break;
      try {
        final t = await _aiService.translate(question);
        await _questionService.saveTranslation(question,
            lang: _targetLang,
            text: t.text,
            options: t.options,
            explanation: t.explanation);
        if (mounted) setState(() => _translated++);
      } catch (e) {
        if (mounted) setState(() => _failures.add('${_preview(question.text)} — $e'));
      }
      if (mounted) setState(() => _processed++);
    }

    // Topics
    for (final topic in _pendingTopics) {
      if (_cancelled || !mounted) break;
      try {
        final t = await _aiService.translateFields(
            {'name': topic.nameEn, 'desc': topic.descEn});
        await _topicsService.saveTopicTranslation(topic,
            lang: _targetLang, name: t['name'] ?? '', desc: t['desc'] ?? '');
        if (mounted) setState(() => _translated++);
      } catch (e) {
        if (mounted) setState(() => _failures.add('${_preview(topic.nameEn)} — $e'));
      }
      if (mounted) setState(() => _processed++);
    }

    // Learning content
    for (final item in _pendingContent) {
      if (_cancelled || !mounted) break;
      try {
        final t = await _aiService.translateFields({
          'title': item.titleEn,
          'description': item.descriptionEn,
          'content': item.contentEn,
        });
        await _learningService.saveContentTranslation(item,
            lang: _targetLang,
            title: t['title'] ?? '',
            description: t['description'] ?? '',
            body: t['content'] ?? '');
        if (mounted) setState(() => _translated++);
      } catch (e) {
        if (mounted) setState(() => _failures.add('${_preview(item.titleEn)} — $e'));
      }
      if (mounted) setState(() => _processed++);
    }

    if (!mounted) return;
    setState(() => _running = false);
    await _load();
  }

  static String _preview(String text) =>
      text.length <= 48 ? text : '${text.substring(0, 45)}...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(title: AppLocalizations.of(context).adminTranslate),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final l10n = AppLocalizations.of(context);
    if (_loadError != null) {
      return AdminEmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.translateLoadError,
        subtitle: _loadError!,
      );
    }
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = _total;
    final pending = _pendingCount;
    final done = total - pending;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminCard(
            title: l10n.languageMacedonian,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(label: l10n.adminQuestions, value: '${_questions!.length}'),
                const SizedBox(height: 8),
                _StatRow(label: l10n.adminCategoriesTopics, value: '${_topics!.length}'),
                const SizedBox(height: 8),
                _StatRow(label: l10n.adminLearningContent, value: '${_content!.length}'),
                const Divider(height: 20),
                _StatRow(label: l10n.translateAlready, value: '$done'),
                const SizedBox(height: 8),
                _StatRow(label: l10n.translateStillTo, value: '$pending'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_running) ...[
            LinearProgressIndicator(
              value: pending == 0 ? 0 : _processed / pending,
              minHeight: 8,
              backgroundColor: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.translateProgress(_processed, pending),
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AdminSecondaryButton(
              label: l10n.translateStop,
              onTap: () => setState(() => _cancelled = true),
            ),
          ] else if (pending == 0) ...[
            AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: l10n.translateAllDone,
              subtitle: l10n.translateAllDoneBody(total),
            ),
          ] else ...[
            AdminPrimaryButton(
              label: l10n.translateButton(pending),
              onTap: _run,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.translateInfo,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],

          if (!_running && _processed > 0) ...[
            const SizedBox(height: 24),
            Text(
              l10n.translateLastRun(_translated, _failures.length),
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],

          if (_failures.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final failure in _failures)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    failure,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
        ],
      );
}
