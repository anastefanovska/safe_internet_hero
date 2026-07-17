import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
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
  /// Tab to open on (0 = Requests, 1 = Submissions). Lets the notification
  /// review-queue cards deep-link to the relevant tab.
  final int initialTab;
  const ManageModeratorsScreen({super.key, this.initialTab = 0});

  @override
  State<ManageModeratorsScreen> createState() => _ManageModeratorsScreenState();
}

class _ManageModeratorsScreenState extends State<ManageModeratorsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
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
          // Live tab badges so an admin sees at a glance whether the pending
          // work is requests or submissions.
          StreamBuilder<List<ModeratorRequestModel>>(
            stream: _service.watchPendingRequests(),
            builder: (context, reqSnap) {
              final reqCount = reqSnap.data?.length ?? 0;
              return StreamBuilder<List<QuestionModel>>(
                stream: QuestionService().watchPendingSubmissions(),
                builder: (context, subSnap) {
                  final subCount = subSnap.data?.length ?? 0;
                  return AdminHeader(
                    title: AppLocalizations.of(context).adminModerators,
                    tabController: _tabs,
                    tabs: [AppLocalizations.of(context).modTabRequests, AppLocalizations.of(context).modTabSubmissions],
                    tabBadges: [reqCount, subCount],
                  );
                },
              );
            },
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

/// A confirm dialog that collects a reason the user will see. Used for both
/// rejecting (reason optional) and requesting changes (reason required — the
/// action button stays disabled until something is typed). Returns null if
/// cancelled, otherwise the (trimmed-by-caller) reason text.
Future<String?> _reasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required Color actionColor,
  required bool requireReason,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final canSubmit =
            !requireReason || controller.text.trim().isNotEmpty;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                  style: GoogleFonts.nunito(
                      color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) => setLocal(() {}),
                style: GoogleFonts.nunito(fontSize: 13),
                decoration: InputDecoration(
                  hintText: requireReason
                      ? l10n.modReasonRequiredHint
                      : l10n.modReasonOptionalHint,
                  hintStyle: GoogleFonts.nunito(
                      color: AppColors.textLight, fontSize: 12.5),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonCancel,
                    style:
                        GoogleFonts.nunito(color: AppColors.textSecondary))),
            TextButton(
                onPressed: canSubmit
                    ? () => Navigator.pop(ctx, controller.text)
                    : null,
                child: Text(actionLabel,
                    style: GoogleFonts.nunito(
                        color: canSubmit ? actionColor : AppColors.textLight,
                        fontWeight: FontWeight.w700))),
          ],
        );
      },
    ),
  );
  controller.dispose();
  return result;
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

  Future<void> _approve(
      BuildContext context, ModeratorRequestModel req) async {
    final l10n = AppLocalizations.of(context);
    final adminUid = _adminUid(context);
    try {
      await _service.approveRequest(req, adminUid);
      if (!context.mounted) return;
      _snack(context, l10n.modNowModerator(req.username));
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  Future<void> _reject(
      BuildContext context, ModeratorRequestModel req) async {
    final l10n = AppLocalizations.of(context);
    final reason = await _reasonDialog(context,
        title: l10n.modRejectReqTitle(req.username),
        message: l10n.modRejectReqBody,
        actionLabel: l10n.modReject,
        actionColor: AppColors.red,
        requireReason: false);
    if (reason == null || !context.mounted) return;
    final adminUid = _adminUid(context);
    try {
      await _service.rejectRequest(req, adminUid, reason: reason);
      if (!context.mounted) return;
      _snack(context, l10n.modRequestRejected);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  Future<void> _revoke(BuildContext context, UserModel mod) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.modRevokeTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            l10n.modRevokeBody(mod.username),
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel,
                  style: GoogleFonts.nunito(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.modRevoke,
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
      _snack(context, l10n.modAccessRevoked);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _SectionLabel(l10n.modPendingRequests),
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
              return AdminEmptyState(
                icon: Icons.how_to_reg_rounded,
                title: l10n.profileNoRequests,
                subtitle: l10n.modApplicationsHere,
              );
            }
            return Column(
              children: reqs
                  .map((r) => _RequestCard(
                        request: r,
                        onApprove: () => _approve(context, r),
                        onReject: () => _reject(context, r),
                      ))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        _SectionLabel(l10n.modCurrentMods),
        StreamBuilder<List<UserModel>>(
          stream: _service.watchModerators(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox.shrink();
            }
            final mods = snap.data!;
            if (mods.isEmpty) {
              return Text(l10n.modNoModerators,
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
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.schedule_rounded,
                color: AppColors.textLight, size: 13),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context).modRequestedAgo(timeAgo(request.createdAt)),
                style: GoogleFonts.nunito(
                    color: AppColors.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _ActionButton(
              label: AppLocalizations.of(context).modApprove,
              color: AppColors.green,
              icon: Icons.check_rounded,
              onTap: onApprove),
          const SizedBox(width: 8),
          _ActionButton(
              label: AppLocalizations.of(context).modReject,
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
          child: Text(AppLocalizations.of(context).modRevoke,
              style: GoogleFonts.nunito(
                  color: AppColors.red, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Submissions tab ─────────────────────────────────────────────────────────

/// Label + colour for a submission status (admin side).
Color _subStatusColor(QuestionStatus s) => switch (s) {
      QuestionStatus.approved => AppColors.green,
      QuestionStatus.rejected => AppColors.red,
      QuestionStatus.pending => AppColors.orange,
      QuestionStatus.needsRevision => AppColors.blue,
    };

String _subStatusLabel(QuestionStatus s, AppLocalizations l10n) => switch (s) {
      QuestionStatus.approved => l10n.statusApproved,
      QuestionStatus.rejected => l10n.statusRejected,
      QuestionStatus.pending => l10n.modStatusPending,
      QuestionStatus.needsRevision => l10n.statusNeedsChanges,
    };

class _SubmissionsTab extends StatefulWidget {
  const _SubmissionsTab();

  @override
  State<_SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<_SubmissionsTab> {
  // Open on the review queue; admins switch to see decided submissions.
  QuestionStatus _filter = QuestionStatus.pending;

  Future<void> _approve(BuildContext context, QuestionModel q) async {
    final l10n = AppLocalizations.of(context);
    final adminUid = context.read<AuthProvider>().user?.id ?? '';
    try {
      await _service.approveSubmission(q, adminUid);
      if (!context.mounted) return;
      _snack(context, l10n.modQuestionApproved);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  Future<void> _reject(BuildContext context, QuestionModel q) async {
    final l10n = AppLocalizations.of(context);
    final reason = await _reasonDialog(context,
        title: l10n.modRejectQuestionTitle,
        message: l10n.modRejectQuestionBody,
        actionLabel: l10n.modReject,
        actionColor: AppColors.red,
        requireReason: false);
    if (reason == null || !context.mounted) return;
    final adminUid = context.read<AuthProvider>().user?.id ?? '';
    try {
      await _service.rejectSubmission(q, adminUid, reason: reason);
      if (!context.mounted) return;
      _snack(context, l10n.modSubmissionRejected);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  Future<void> _requestChanges(BuildContext context, QuestionModel q) async {
    final l10n = AppLocalizations.of(context);
    final reason = await _reasonDialog(context,
        title: l10n.modRequestChangesTitle,
        message: l10n.modRequestChangesBody,
        actionLabel: l10n.modSend,
        actionColor: AppColors.blue,
        requireReason: true);
    if (reason == null || !context.mounted) return;
    final adminUid = context.read<AuthProvider>().user?.id ?? '';
    try {
      await _service.requestChangesSubmission(q, adminUid, reason);
      if (!context.mounted) return;
      _snack(context, l10n.modSentBack);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  Future<void> _delete(BuildContext context, QuestionModel q) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.modDeleteTitle,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
            l10n.modDeleteSubmissionBody,
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
    try {
      await QuestionService().deleteQuestion(q.id);
      if (!context.mounted) return;
      _snack(context, l10n.modSubmissionDeleted);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, l10n.formError('$e'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchAllSubmissions(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.blue));
        }
        final all = snap.data!;
        final items = all.where((q) => q.status == _filter).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SubFilterBar(
                all: all,
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? AdminEmptyState(
                      icon: Icons.inbox_rounded,
                      title: AppLocalizations.of(context).modNothingHere,
                      subtitle: _filter == QuestionStatus.pending
                          ? AppLocalizations.of(context).modNewSubmissionsHere
                          : AppLocalizations.of(context).modNoStatusSubmissions(_subStatusLabel(_filter, AppLocalizations.of(context)).toLowerCase()),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _SubmissionCard(
                        question: items[i],
                        onApprove: () => _approve(context, items[i]),
                        onReject: () => _reject(context, items[i]),
                        onRequestChanges: () =>
                            _requestChanges(context, items[i]),
                        // Approved questions are live content — delete them from
                        // the Questions manager, not here.
                        onDelete: items[i].status == QuestionStatus.approved
                            ? null
                            : () => _delete(context, items[i]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Status filter chips with live counts for the submissions queue.
class _SubFilterBar extends StatelessWidget {
  final List<QuestionModel> all;
  final QuestionStatus selected;
  final ValueChanged<QuestionStatus> onChanged;
  const _SubFilterBar(
      {required this.all, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const order = [
      QuestionStatus.pending,
      QuestionStatus.needsRevision,
      QuestionStatus.approved,
      QuestionStatus.rejected,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: order.map((s) {
          final label = _subStatusLabel(s, AppLocalizations.of(context));
          final color = _subStatusColor(s);
          final count = all.where((q) => q.status == s).length;
          final active = selected == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? color : AppColors.border,
                      width: active ? 1.8 : 1.5),
                ),
                child: Text(
                  '${label[0]}${label.substring(1).toLowerCase()} ($count)',
                  style: GoogleFonts.nunito(
                      color: active ? color : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestChanges;

  /// Null for approved (live) questions, which can't be deleted from here.
  final VoidCallback? onDelete;
  const _SubmissionCard({
    required this.question,
    required this.onApprove,
    required this.onReject,
    required this.onRequestChanges,
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
    final statusLabel = _subStatusLabel(q.status, l10n);
    final statusColor = _subStatusColor(q.status);
    final isPending = q.status == QuestionStatus.pending;

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
              text: q.type == QuestionType.trueFalse ? l10n.badgeTF : l10n.badgeMCQ,
              color: AppColors.blue),
          AdminBadge(text: statusLabel.toUpperCase(), color: statusColor),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              tooltip: l10n.commonDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textLight, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
        ]),
        const SizedBox(height: 8),
        Text(q.text,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        // Full option list so the reviewer can judge every choice, not just the
        // correct one. The correct answer is highlighted green.
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(
                i == q.correctIndex
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 15,
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
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: i == q.correctIndex
                            ? AppColors.green
                            : AppColors.textSecondary)),
              ),
            ]),
          ),
        if (q.explanation.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(l10n.modExplanationLabel(q.explanation),
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35)),
          ),
        ],
        // Prior decision feedback (for reviewed items shown via the filter).
        if (q.reviewNote.trim().isNotEmpty && !isPending) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(l10n.modFeedbackSent(q.reviewNote),
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35)),
          ),
        ],
        const SizedBox(height: 6),
        Text('${q.categoryId} / ${q.topicId}',
            style: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 11)),
        // Actions only for items in the review queue. Decided items are
        // read-only history.
        if (isPending) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ActionButton(
                label: l10n.modApprove,
                color: AppColors.green,
                icon: Icons.check_rounded,
                onTap: onApprove),
            _ActionButton(
                label: l10n.modRequestChangesBtn,
                color: AppColors.blue,
                icon: Icons.rate_review_rounded,
                onTap: onRequestChanges),
            _ActionButton(
                label: l10n.modReject,
                color: AppColors.red,
                icon: Icons.close_rounded,
                onTap: onReject),
          ]),
        ],
      ]),
    );
  }
}
