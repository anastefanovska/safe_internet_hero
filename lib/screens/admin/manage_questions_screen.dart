import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/question_model.dart';
import '../../services/questions_service.dart';
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
            title: 'Questions',
            tabController: _tabs,
            tabs: const ['Add Question', 'All Questions'],
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
                    _QuestionsList(),
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

// â”€â”€â”€ Questions list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _QuestionsList extends StatelessWidget {
  const _QuestionsList();

  Future<void> _delete(BuildContext context, QuestionModel q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete question?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(q.text,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style: GoogleFonts.nunito(
                      color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await QuestionService().deleteQuestion(q.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Deleted',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.blue,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchAllQuestions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.blue));
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.quiz_rounded,
            title: 'No questions yet',
            subtitle: 'Add some from the "Add Question" tab',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final q = items[i];
            final diffColor = q.difficulty == DifficultyLevel.beginner
                ? AppColors.green
                : q.difficulty == DifficultyLevel.intermediate
                    ? AppColors.orange
                    : AppColors.red;
            final diffLabel = q.difficulty.name[0].toUpperCase() +
                q.difficulty.name.substring(1);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            AdminBadge(text: diffLabel, color: diffColor),
                            AdminBadge(
                                text: q.type == QuestionType.trueFalse
                                    ? 'T/F'
                                    : 'MCQ',
                                color: AppColors.blue),
                            Text(' ${q.points} pts',
                                style: GoogleFonts.nunito(
                                    color: AppColors.textLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 6),
                          Text(q.text,
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(
                            'Correct: ${q.options.isNotEmpty ? q.options[q.correctIndex] : ''}',
                            style: GoogleFonts.nunito(
                                color: AppColors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${q.categoryId} / ${q.topicId}',
                            style: GoogleFonts.nunito(
                                color: AppColors.textLight, fontSize: 11),
                          ),
                        ])),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.red, size: 20),
                      onPressed: () => _delete(context, q),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ]),
            );
          },
        );
      },
    );
  }
}

