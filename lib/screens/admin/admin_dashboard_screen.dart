import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme.dart';
import '../../models/moderator_request_model.dart';
import '../../models/question_model.dart';
import '../../services/moderator_service.dart';
import '../../services/questions_service.dart';
import '../../widgets/admin_widgets.dart';
import 'generate_questions_screen.dart';
import 'import_data_screen.dart';
import 'manage_categories_topics_screen.dart';
import 'manage_learning_content_screen.dart';
import 'manage_moderators_screen.dart';
import 'translate_questions_screen.dart';
import 'manage_questions_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(
            title: l10n.adminTitle,
            trailing: Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: Text(
                l10n.adminBadge,
                style: GoogleFonts.nunito(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                Text(
                  l10n.adminSectionContent,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminQuestions,
                  subtitle: l10n.adminQuestionsSub,
                  icon: Icons.quiz_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ManageQuestionsScreen())),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminGenerateAi,
                  subtitle: l10n.adminGenerateAiSub,
                  icon: Icons.auto_awesome_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GenerateQuestionsScreen())),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminTranslate,
                  subtitle: l10n.adminTranslateSub,
                  icon: Icons.translate_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TranslateQuestionsScreen())),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminLearningContent,
                  subtitle: l10n.adminLearningContentSub,
                  icon: Icons.library_books_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ManageLearningContentScreen())),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.adminSectionStructure,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminCategoriesTopics,
                  subtitle: l10n.adminCategoriesTopicsSub,
                  icon: Icons.account_tree_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CategoryTopicManagerScreen())),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.adminSectionCommunity,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                const _ModeratorsCard(),
                const SizedBox(height: 24),
                Text(
                  l10n.adminSectionTools,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: l10n.adminImportJson,
                  subtitle: l10n.adminImportJsonSub,
                  icon: Icons.upload_file_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ImportDataScreen())),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.blue.withValues(alpha: 0.2),
                        width: 1.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.blue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.adminExcludedNote,
                        style: GoogleFonts.nunito(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ]),
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

/// The Moderators dashboard card, badged with the admin's open workload:
/// pending submissions + pending moderator requests. Two streams are nested
/// (no rxdart in the project) and summed.
class _ModeratorsCard extends StatelessWidget {
  const _ModeratorsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchPendingSubmissions(),
      builder: (context, subSnap) {
        final pendingSubs = subSnap.data?.length ?? 0;
        return StreamBuilder<List<ModeratorRequestModel>>(
          stream: ModeratorService().watchPendingRequests(),
          builder: (context, reqSnap) {
            final pendingReqs = reqSnap.data?.length ?? 0;
            return AdminDashboardCard(
              title: AppLocalizations.of(context).adminModerators,
              subtitle: AppLocalizations.of(context).adminModeratorsSub,
              icon: Icons.shield_rounded,
              badgeCount: pendingSubs + pendingReqs,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageModeratorsScreen())),
            );
          },
        );
      },
    );
  }
}

