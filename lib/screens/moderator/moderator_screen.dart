import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/question_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/question_author_form.dart';

/// Moderator home: submit new questions and track the status of past
/// submissions. Reached from the home screen when `user.isModerator == true`.
class ModeratorScreen extends StatelessWidget {
  const ModeratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final user = context.watch<AuthProvider>().user;
    final questionService = QuestionService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(children: [
              if (!desktop)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 4),
            ]),
          ),
          const TabHeader(
            title: 'Moderator Tools',
            subtitle: 'Submit questions for admin review',
            icon: Icons.shield_rounded,
            color: AppColors.green,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: user == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        children: [
                          AppButton(
                            label: 'Submit a new question',
                            variant: AppButtonVariant.success,
                            icon: Icons.add_rounded,
                            onTap: () => Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) =>
                                    _SubmitQuestionScreen(authorId: user.id),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('MY SUBMISSIONS',
                              style: GoogleFonts.nunito(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          _SubmissionsList(
                            stream: questionService
                                .watchSubmissionsByAuthor(user.id),
                          ),
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

class _SubmissionsList extends StatelessWidget {
  final Stream<List<QuestionModel>> stream;
  const _SubmissionsList({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child:
                Center(child: CircularProgressIndicator(color: AppColors.blue)),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              'No submissions yet. Tap "Submit a new question" to add one.',
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }
        // Newest first.
        final sorted = [...items]..sort((a, b) => b.id.compareTo(a.id));
        return Column(
          children: sorted.map((q) => _SubmissionTile(question: q)).toList(),
        );
      },
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final QuestionModel question;
  const _SubmissionTile({required this.question});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (question.status) {
      QuestionStatus.approved => ('APPROVED', AppColors.green),
      QuestionStatus.rejected => ('REJECTED', AppColors.red),
      QuestionStatus.pending => ('PENDING', AppColors.orange),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: GoogleFonts.nunito(
                  color: color, fontWeight: FontWeight.w800, fontSize: 10)),
        ),
        const SizedBox(height: 8),
        Text(question.text,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('${question.categoryId} / ${question.topicId}',
            style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 11)),
      ]),
    );
  }
}

/// Hosts the shared authoring form in moderator (pending) mode.
class _SubmitQuestionScreen extends StatelessWidget {
  final String authorId;
  const _SubmitQuestionScreen({required this.authorId});

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(children: [
              if (!desktop)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 4),
            ]),
          ),
          const TabHeader(
            title: 'Submit a Question',
            subtitle: 'An admin will review it before it goes live',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.green,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: QuestionAuthorForm(
                  submitAsPending: true,
                  authorId: authorId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
