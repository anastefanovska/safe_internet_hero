import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/moderator_request_model.dart';
import '../../models/question_model.dart';
import '../../services/moderator_service.dart';
import '../../services/questions_service.dart';
import '../../widgets/admin_widgets.dart';
import 'import_data_screen.dart';
import 'manage_categories_topics_screen.dart';
import 'manage_learning_content_screen.dart';
import 'manage_moderators_screen.dart';
import 'manage_questions_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AdminHeader(
            title: 'Admin',
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
                'ADMIN',
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
                  'Content',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: 'Questions',
                  subtitle: 'Create quiz questions, set difficulty and correct answers.',
                  icon: Icons.quiz_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ManageQuestionsScreen())),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: 'Learning Content',
                  subtitle: 'Create and edit articles and video resources.',
                  icon: Icons.library_books_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ManageLearningContentScreen())),
                ),
                const SizedBox(height: 24),
                Text(
                  'Structure',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: 'Categories & Topics',
                  subtitle: 'Organise categories and their topics.',
                  icon: Icons.account_tree_rounded,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CategoryTopicManagerScreen())),
                ),
                const SizedBox(height: 24),
                Text(
                  'Community',
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
                  'Tools',
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                AdminDashboardCard(
                  title: 'Import JSON',
                  subtitle: 'Bulk-upload questions or articles from a JSON file.',
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
                        'Admin accounts are excluded from the leaderboard and public rankings.',
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
              title: 'Moderators',
              subtitle:
                  'Review moderator requests and approve submitted questions.',
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

