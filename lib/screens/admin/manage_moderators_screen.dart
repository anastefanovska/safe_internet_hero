import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/moderator_request_model.dart';
import '../../models/question_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/moderator_service.dart';
import '../../services/questions_service.dart';
import '../../widgets/admin_widgets.dart';

class ManageModeratorsScreen extends StatefulWidget {
  const ManageModeratorsScreen({super.key});

  @override
  State<ManageModeratorsScreen> createState() => _ManageModeratorsScreenState();
}

class _ManageModeratorsScreenState extends State<ManageModeratorsScreen>
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
            title: 'Moderators',
            tabController: _tabs,
            tabs: const ['Requests', 'Submissions'],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: TabBarView(
                  controller: _tabs,
                  children: const [
                    _RequestsTab(),
                    _SubmissionsTab(),
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

// ─── shared helpers ──────────────────────────────────────────────────────────

final _service = ModeratorService();

void _snack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
    backgroundColor: isError ? AppColors.red : AppColors.blue,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
  ));
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A compact approve / reject (or single) action button used inside cards.
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.nunito(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

// ─── Requests tab ────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  String _adminUid(BuildContext context) =>
      context.read<AuthProvider>().user?.id ?? '';

  Future<void> _review(BuildContext context, ModeratorRequestModel req,
      {required bool approve}) async {
    final adminUid = _adminUid(context);
    try {
      if (approve) {
        await _service.approveRequest(req, adminUid);
      } else {
        await _service.rejectRequest(req, adminUid);
      }
      if (!context.mounted) return;
      _snack(context,
          approve ? '${req.username} is now a moderator' : 'Request rejected');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _revoke(BuildContext context, UserModel mod) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Revoke moderator?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            '${mod.username} will lose the ability to submit questions.',
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Revoke',
                  style: GoogleFonts.nunito(
                      color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final adminUid = _adminUid(context);
    try {
      await _service.revokeModerator(mod.id, adminUid);
      if (!context.mounted) return;
      _snack(context, 'Moderator access revoked');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const _SectionLabel('PENDING REQUESTS'),
        StreamBuilder<List<ModeratorRequestModel>>(
          stream: _service.watchPendingRequests(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.blue)),
              );
            }
            final reqs = snap.data!;
            if (reqs.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.how_to_reg_rounded,
                title: 'No pending requests',
                subtitle: 'Moderator applications will appear here',
              );
            }
            return Column(
              children: reqs
                  .map((r) => _RequestCard(
                        request: r,
                        onApprove: () => _review(context, r, approve: true),
                        onReject: () => _review(context, r, approve: false),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const _SectionLabel('CURRENT MODERATORS'),
        StreamBuilder<List<UserModel>>(
          stream: _service.watchModerators(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox.shrink();
            }
            final mods = snap.data!;
            if (mods.isEmpty) {
              return Text('No moderators yet',
                  style: GoogleFonts.nunito(
                      color: AppColors.textLight, fontSize: 13));
            }
            return Column(
              children: mods
                  .map((m) => _ModeratorCard(
                        moderator: m,
                        onRevoke: () => _revoke(context, m),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ModeratorRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_rounded, color: AppColors.blue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(request.username,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _ActionButton(
              label: 'Approve',
              color: AppColors.green,
              icon: Icons.check_rounded,
              onTap: onApprove),
          const SizedBox(width: 8),
          _ActionButton(
              label: 'Reject',
              color: AppColors.red,
              icon: Icons.close_rounded,
              onTap: onReject),
        ]),
      ]),
    );
  }
}

class _ModeratorCard extends StatelessWidget {
  final UserModel moderator;
  final VoidCallback onRevoke;
  const _ModeratorCard({required this.moderator, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        const Icon(Icons.shield_rounded, color: AppColors.green, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(moderator.username,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
        ),
        TextButton(
          onPressed: onRevoke,
          child: Text('Revoke',
              style: GoogleFonts.nunito(
                  color: AppColors.red, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Submissions tab ─────────────────────────────────────────────────────────

class _SubmissionsTab extends StatelessWidget {
  const _SubmissionsTab();

  Future<void> _review(BuildContext context, QuestionModel q,
      {required bool approve}) async {
    final adminUid = context.read<AuthProvider>().user?.id ?? '';
    try {
      if (approve) {
        await _service.approveSubmission(q, adminUid);
      } else {
        await _service.rejectSubmission(q, adminUid);
      }
      if (!context.mounted) return;
      _snack(context, approve ? 'Question approved & live' : 'Submission rejected');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchPendingSubmissions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.blue));
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No submissions to review',
            subtitle: 'Questions submitted by moderators show up here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: items.length,
          itemBuilder: (context, i) => _SubmissionCard(
            question: items[i],
            onApprove: () => _review(context, items[i], approve: true),
            onReject: () => _review(context, items[i], approve: false),
          ),
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _SubmissionCard({
    required this.question,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final q = question;
    final diffColor = q.difficulty == DifficultyLevel.beginner
        ? AppColors.green
        : q.difficulty == DifficultyLevel.intermediate
            ? AppColors.orange
            : AppColors.red;
    final diffLabel =
        q.difficulty.name[0].toUpperCase() + q.difficulty.name.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AdminBadge(text: diffLabel, color: diffColor),
          AdminBadge(
              text: q.type == QuestionType.trueFalse ? 'T/F' : 'MCQ',
              color: AppColors.blue),
          const AdminBadge(text: 'PENDING', color: AppColors.orange),
        ]),
        const SizedBox(height: 8),
        Text(q.text,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(
          'Correct: ${q.options.isNotEmpty ? q.options[q.correctIndex] : ''}',
          style: GoogleFonts.nunito(
              color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text('${q.categoryId} / ${q.topicId}',
            style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 11)),
        const SizedBox(height: 12),
        Row(children: [
          _ActionButton(
              label: 'Approve',
              color: AppColors.green,
              icon: Icons.check_rounded,
              onTap: onApprove),
          const SizedBox(width: 8),
          _ActionButton(
              label: 'Reject',
              color: AppColors.red,
              icon: Icons.close_rounded,
              onTap: onReject),
        ]),
      ]),
    );
  }
}
