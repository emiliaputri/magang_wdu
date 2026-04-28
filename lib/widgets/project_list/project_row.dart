import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../pages/list_survey_page.dart';
import '../../core/theme/app_theme.dart';

class ProjectRow extends StatelessWidget {
  final int index;
  final Project project;
  final Client client;
  final bool isLast;

  const ProjectRow({
    super.key,
    required this.index,
    required this.project,
    required this.client,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.rowBorder),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndex(),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              project.projectName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                project.desc ?? '-',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(child: _buildSurveysButton(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildIndex() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textGrey,
        ),
      ),
    );
  }

  Widget _buildSurveysButton(BuildContext context) {
    return Material(
      color: AppTheme.bgGreen,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _navigateToSurveys(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_outlined, size: 13, color: AppTheme.green),
              SizedBox(width: 4),
              Text(
                'Surveys',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSurveys(BuildContext context) {
    if (project.slug == null || client.slug == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/surveys',
          arguments: {
            'clientSlug':   client.slug!,
            'clientName':   client.clientName,
            'projectSlug':  project.slug!,
            'projectTitle': project.projectName,
          },
        ),
        builder: (_) => SurveyListPage(
          clientSlug:   client.slug!,
          clientName:   client.clientName,
          projectSlug:  project.slug!,
          projectTitle: project.projectName,
        ),
      ),
    );
  }
}