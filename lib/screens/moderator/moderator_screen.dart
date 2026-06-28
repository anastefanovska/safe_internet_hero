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
                          _SubmissionsSection(authorId: user.id),
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

/// Visual identity for a question status — one source of truth for the badge
/// label, colour and icon shown to the moderator.
({String label, Color color, IconData icon}) _statusStyle(QuestionStatus s) {
  switch (s) {
    case QuestionStatus.approved:
      return (
        label: 'Approved',
        color: AppColors.green,
        icon: Icons.check_circle_rounded
      );
    case QuestionStatus.rejected:
      return (
        label: 'Rejected',
        color: AppColors.red,
        icon: Icons.cancel_rounded
      );
    case QuestionStatus.pending:
      return (
        label: 'Pending review',
        color: AppColors.orange,
        icon: Icons.hourglass_top_rounded
      );
    case QuestionStatus.needsRevision:
      return (
        label: 'Needs changes',
        color: AppColors.blue,
        icon: Icons.rate_review_rounded
      );
  }
}

/// Ordering for the "All" view: actionable items first, history last.
int _statusRank(QuestionStatus s) => switch (s) {
      QuestionStatus.needsRevision => 0,
      QuestionStatus.pending => 1,
      QuestionStatus.approved => 2,
      QuestionStatus.rejected => 3,
    };

/// "My submissions" with a status filter, distinct badges, inline reviewer
/// feedback, and an edit-and-resubmit action for items needing changes.
class _SubmissionsSection extends StatefulWidget {
  final String authorId;
  const _SubmissionsSection({required this.authorId});

  @override
  State<_SubmissionsSection> createState() => _SubmissionsSectionState();
}

class _SubmissionsSectionState extends State<_SubmissionsSection> {
  // null == "All".
  QuestionStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchSubmissionsByAuthor(widget.authorId),
      builder: (context, snap) {
        final all = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('MY SUBMISSIONS',
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              const Spacer(),
              if (all != null && all.isNotEmpty)
                Text('${all.length} total',
                    style: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            if (all == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
              )
            else if (all.isEmpty)
              _emptyCard('No submissions yet. Tap "Submit a new question" to '
                  'add one.')
            else ...[
              _FilterBar(
                all: all,
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 12),
              ..._buildList(all),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildList(List<QuestionModel> all) {
    final items = (_filter == null
        ? [...all]
        : all.where((q) => q.status == _filter).toList())
      ..sort((a, b) {
        final r = _statusRank(a.status).compareTo(_statusRank(b.status));
        return r != 0 ? r : b.id.compareTo(a.id);
      });
    if (items.isEmpty) {
      return [_emptyCard('Nothing here in this filter.')];
    }
    return items.map((q) => _SubmissionTile(question: q)).toList();
  }

  Widget _emptyCard(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Text(text,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
      );
}

/// Horizontally scrollable status filter chips with per-status counts.
class _FilterBar extends StatelessWidget {
  final List<QuestionModel> all;
  final QuestionStatus? selected;
  final ValueChanged<QuestionStatus?> onChanged;
  const _FilterBar(
      {required this.all, required this.selected, required this.onChanged});

  int _count(QuestionStatus? s) =>
      s == null ? all.length : all.where((q) => q.status == s).length;

  @override
  Widget build(BuildContext context) {
    final options = <(String, QuestionStatus?)>[
      ('All', null),
      ('Needs changes', QuestionStatus.needsRevision),
      ('Pending', QuestionStatus.pending),
      ('Approved', QuestionStatus.approved),
      ('Rejected', QuestionStatus.rejected),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) {
          final count = _count(o.$2);
          final active = selected == o.$2;
          final color = o.$2 == null
              ? AppColors.textPrimary
              : _statusStyle(o.$2!).color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(o.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? color : AppColors.border,
                      width: active ? 1.8 : 1.5),
                ),
                child: Text('${o.$1} ($count)',
                    style: GoogleFonts.nunito(
                        color: active ? color : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  final QuestionModel question;
  const _SubmissionTile({required this.question});

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle(question.status);
    final hasFeedback = question.reviewNote.trim().isNotEmpty &&
        (question.status == QuestionStatus.needsRevision ||
            question.status == QuestionStatus.rejected);
    final canEdit = question.status == QuestionStatus.needsRevision;
    // Live (approved) questions are protected; everything else the author can
    // clear out to keep the list tidy.
    final canDelete = question.status != QuestionStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Status badge row (+ delete for non-approved submissions).
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(s.icon, color: s.color, size: 14),
              const SizedBox(width: 5),
              Text(s.label.toUpperCase(),
                  style: GoogleFonts.nunito(
                      color: s.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.4)),
            ]),
          ),
          const Spacer(),
          if (canDelete)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textLight, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _confirmAndDelete(context),
            ),
        ]),
        const SizedBox(height: 10),
        Text(question.text,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.3,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.folder_outlined,
              color: AppColors.textLight, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text('${question.categoryId} / ${question.topicId}',
                style: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 11.5)),
          ),
        ]),
        if (hasFeedback) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: s.color.withValues(alpha: 0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.feedback_outlined, color: s.color, size: 14),
                const SizedBox(width: 6),
                Text('Reviewer feedback',
                    style: GoogleFonts.nunito(
                        color: s.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5)),
              ]),
              const SizedBox(height: 4),
              Text(question.reviewNote,
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.35)),
            ]),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'Edit & resubmit',
            variant: AppButtonVariant.primary,
            icon: Icons.edit_rounded,
            onTap: () => Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => _EditSubmissionScreen(question: question),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete submission?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            'This permanently removes your submission. This can\'t be undone.',
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
    if (ok != true || !context.mounted) return;
    try {
      await QuestionService().deleteQuestion(question.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Submission deleted',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not delete: $e',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
    }
  }
}

/// Hosts the shared authoring form pre-filled for a revision; resubmitting
/// returns the question to the review queue and pops back.
class _EditSubmissionScreen extends StatelessWidget {
  final QuestionModel question;
  const _EditSubmissionScreen({required this.question});

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
            title: 'Revise & Resubmit',
            subtitle: 'Address the feedback, then send it back for review',
            icon: Icons.edit_rounded,
            color: AppColors.blue,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: QuestionAuthorForm(
                  submitAsPending: true,
                  authorId: question.authorId,
                  editQuestion: question,
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
