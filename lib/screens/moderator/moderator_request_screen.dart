import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../services/moderator_service.dart';
import '../../widgets/app_widgets.dart';

/// Lets a trusted learner see whether they qualify to become a moderator and,
/// if so, file a request. Reached from the home screen.
class ModeratorRequestScreen extends StatefulWidget {
  const ModeratorRequestScreen({super.key});

  @override
  State<ModeratorRequestScreen> createState() => _ModeratorRequestScreenState();
}

class _ModeratorRequestScreenState extends State<ModeratorRequestScreen> {
  final _service = ModeratorService();
  ModeratorEligibility? _eligibility;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final e = await _service.checkEligibility(user);
      if (!mounted) return;
      setState(() {
        _eligibility = e;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _submitting = true);
    try {
      await _service.requestModerator(user);
      await auth.refreshUser();
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.modReqSent,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.modReqError('$e'),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final status = auth.user?.moderatorStatus ?? ModeratorStatus.none;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(children: [
              // A native desktop window has no browser back button, so always
              // show one when there's a route to pop back to.
              if (Navigator.of(context).canPop())
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 4),
            ]),
          ),
          TabHeader(
            title: AppLocalizations.of(context).homeBecomeModerator,
            subtitle: AppLocalizations.of(context).modReqSubtitle,
            icon: Icons.shield_rounded,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.blue))
                    : _body(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(ModeratorStatus status) {
    final l10n = AppLocalizations.of(context);
    if (status == ModeratorStatus.pending) {
      return _StatusMessage(
        icon: Icons.hourglass_top_rounded,
        color: AppColors.orange,
        title: l10n.modReqPending,
        message: l10n.modReqPendingBody,
      );
    }

    final e = _eligibility;
    if (e == null) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        color: AppColors.red,
        title: l10n.modReqStatsError,
        message: l10n.modReqStatsErrorBody,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.modReqWhatTitle,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              l10n.modReqWhatBody,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(l10n.modReqRequirements,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        _CriterionRow(
          met: e.meetsAnswered,
          label: l10n.modReqAnswerQuestions,
          detail: '${e.answeredCount} / ${ModeratorEligibility.minAnswered}',
        ),
        _CriterionRow(
          met: e.meetsRead,
          label: l10n.modReqReadContent,
          detail:
              '${(e.readFraction * 100).round()}% / ${(ModeratorEligibility.minReadFraction * 100).round()}%',
        ),
        _CriterionRow(
          met: e.meetsRank,
          label: l10n.modReqRank,
          detail:
              '#${e.rank} / top ${ModeratorEligibility.maxRank}',
        ),
        const SizedBox(height: 20),
        if (status == ModeratorStatus.rejected && !e.isEligible)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.modReqDeclined,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
          ),
        if (e.isEligible)
          AppButton(
            label: _submitting ? l10n.modReqSending : l10n.modReqButton,
            variant: AppButtonVariant.success,
            icon: Icons.send_rounded,
            onTap: _submitting ? null : _request,
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.blue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).modReqKeepLearning,
                  style: GoogleFonts.nunito(
                      color: AppColors.blue,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final bool met;
  final String label;
  final String detail;
  const _CriterionRow(
      {required this.met, required this.label, required this.detail});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.green : AppColors.textLight;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
        ),
        Text(detail,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: met ? AppColors.green : AppColors.textSecondary)),
      ]),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
        ]),
      ),
    );
  }
}
