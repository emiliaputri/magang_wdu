import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_project_model.dart';
import '../../pages/list_survey_page.dart';
import '../common/status_badge.dart';
import '../common/gradient_button.dart';

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
      duration: const Duration(milliseconds: 600),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
        settings: RouteSettings(
          name: '/surveys',
          arguments: {
            'clientSlug': widget.project.clientSlug,
            'clientName': widget.project.clientName,
            'projectSlug': widget.project.slug,
            'projectTitle': widget.project.projectName,
          },
        ),
        builder: (_) => SurveyListPage(
          clientSlug: widget.project.clientSlug,
          clientName: widget.project.clientName,
          projectSlug: widget.project.slug,
          projectTitle: widget.project.projectName,
          clientLogoUrl: widget.project.clientImage, // ✅ Teruskan logo klien
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.onSurface.withOpacity(0.08),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                  spreadRadius: -12,
                ),
              ],
              border: Border.all(
                color: AppTheme.outlineVariant.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── ICON & STATUS ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder_open_rounded,
                          color: AppTheme.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    const StatusBadge(label: 'Active', color: AppTheme.primary),
                  ],
                ),
                const SizedBox(height: 12),

                // ── TITLES ──
                Text(
                  p.projectName,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.clientName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // ── DIVIDER ──
                Divider(
                  color: AppTheme.outlineVariant.withOpacity(0.1),
                  height: 1,
                ),
                const SizedBox(height: 10),

                // ── UPDATED INFO ──
                Row(
                  children: [
                     const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.monTextMid,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Updated ${p.updatedAt ?? 'baru saja'}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.monTextMid,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(color: AppTheme.monBorderColor, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.surveyCount} SURVEYS TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ijoGelap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── ACTION BUTTON ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GradientButton(
                      label: 'View Surveys',
                      onPressed: () => _viewSurveys(context),
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
