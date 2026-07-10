import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../models/question_model.dart';
import '../../services/ai_translation_service.dart';
import '../../services/questions_service.dart';
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
  final _aiService = AiTranslationService();

  List<QuestionModel>? _questions;
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
      _loadError = null;
    });
    try {
      final questions = await _questionService.getAllQuestionsForTranslation();
      if (mounted) setState(() => _questions = questions);
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  List<QuestionModel> get _pending =>
      _questions?.where((q) => !q.hasTranslation(_targetLang)).toList() ??
      const [];

  Future<void> _run() async {
    final pending = _pending;
    if (pending.isEmpty) return;

    setState(() {
      _running = true;
      _cancelled = false;
      _processed = 0;
      _translated = 0;
      _failures.clear();
    });

    for (final question in pending) {
      if (_cancelled || !mounted) break;

      try {
        final translation = await _aiService.translate(question);
        await _questionService.saveTranslation(
          question,
          lang: _targetLang,
          text: translation.text,
          options: translation.options,
          explanation: translation.explanation,
        );
        if (mounted) setState(() => _translated++);
      } catch (e) {
        if (mounted) {
          setState(() => _failures.add('${_preview(question.text)} — $e'));
        }
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
          const AdminHeader(title: 'Translate Questions'),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return AdminEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load questions',
        subtitle: _loadError!,
      );
    }
    if (_questions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = _questions!.length;
    final pending = _pending.length;
    final done = total - pending;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminCard(
            title: 'Macedonian',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(label: 'Questions', value: '$total'),
                const SizedBox(height: 8),
                _StatRow(label: 'Already in Macedonian', value: '$done'),
                const SizedBox(height: 8),
                _StatRow(label: 'Still to translate', value: '$pending'),
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
              'Translating $_processed of $pending...',
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            AdminSecondaryButton(
              label: 'Stop',
              onTap: () => setState(() => _cancelled = true),
            ),
          ] else if (pending == 0) ...[
            AdminEmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Everything is translated',
              subtitle:
                  'All $total questions have a Macedonian copy. Switch the app '
                  'language in Settings to see them.',
            ),
          ] else ...[
            AdminPrimaryButton(
              label: 'Translate $pending question${pending == 1 ? '' : 's'}',
              onTap: _run,
            ),
            const SizedBox(height: 10),
            Text(
              'Runs one question at a time and writes each result as it '
              'arrives, so stopping early keeps what has already been done. '
              'The English original is never overwritten.',
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
              'Last run: $_translated translated, ${_failures.length} failed',
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
