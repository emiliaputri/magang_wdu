import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_project_model.dart';
import '../../pages/list_survey_page.dart';

class ProjectCard extends StatefulWidget {
  final UserProject project;
  final Duration animDelay;

  const ProjectCard({
    super.key,
    required this.project,
    required this.animDelay,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.animDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _viewSurveys(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyListPage(
          clientSlug:   widget.project.clientSlug,
          clientName:   widget.project.clientName,
          projectSlug:  widget.project.slug,
          projectTitle: widget.project.projectName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dashSage100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.projectName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.dashTextDark,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.dashSage500,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  p.clientName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.dashTextMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppTheme.dashSage500,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${p.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── DESCRIPTION ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Text(
                    p.desc ?? '-',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.dashTextLight,
                      height: 1.5,
                    ),
                  ),
                ),

                Container(height: 1, color: AppTheme.dashSage100),

                // ── FOOTER ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppTheme.dashSage200),
                      const SizedBox(width: 5),
                      Text(
                        p.updatedAt ?? '-',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.dashSage200),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.dashSage100,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: AppTheme.dashSage200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_outlined,
                                size: 12, color: AppTheme.dashSage500),
                            const SizedBox(width: 4),
                            Text(
                              '${p.surveyCount} survei',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.dashSage500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Container(height: 1, color: AppTheme.dashSage100),

                // ── VIEW SURVEYS BUTTON ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewSurveys(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dashSage500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        'View Surveys',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}