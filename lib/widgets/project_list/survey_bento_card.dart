import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/survey_model.dart';
import '../../pages/monitor_survey_page.dart';
import '../../pages/biodata_page.dart';
import '../../pages/submission_page.dart';

class SurveyBentoCard extends StatelessWidget {
  final SurveyModel survey;
  final String clientSlug;
  final String projectSlug;
  final bool? hasAnswered;

  const SurveyBentoCard({
    super.key,
    required this.survey,
    required this.clientSlug,
    required this.projectSlug,
    this.hasAnswered,
  });

  void _showAllProvinces(BuildContext context) {
    if (survey.provinceTargets.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ALL PROVINCES',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${survey.provinceTargets.length} provinces',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: survey.provinceTargets.length,
                  itemBuilder: (context, index) {
                    final province = survey.provinceTargets[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  province.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${province.targetResponse} responden',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            survey.title,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            survey.desc ??
                                'Evaluasi pemanfaatan infrastruktur digital nasional.',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [_buildStatusBadge()],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoEntry(
                      Icons.location_on_outlined,
                      survey.provinceTargets.isEmpty
                          ? 'Nasional'
                          : '${survey.provinceTargets.length} Provinsi',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 12,
                      width: 1,
                      color: AppTheme.outlineVariant.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    _infoEntry(Icons.calendar_today_rounded, 'Batch 1'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TARGET PROVINCES',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                              letterSpacing: 1.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showAllProvinces(context),
                            child: Text(
                              'View all',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...survey.provinceTargets
                              .take(3)
                              .map((p) => _chip(p.name)),
                          if (survey.provinceTargets.length > 3)
                            _chip(
                              '+${survey.provinceTargets.length - 3} Others',
                            ),
                          if (survey.provinceTargets.isEmpty)
                            _chip('Nasional (All Provinces)', isSpecial: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        label: 'Isi Kuesioner',
                        icon: Icons.edit_note_rounded,
                        gradient: const LinearGradient(
                          colors: [AppTheme.ijoGelap, AppTheme.ijoTerang],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BiodataPage(
                                surveySlug: survey.slug,
                                clientSlug: clientSlug,
                                projectSlug: projectSlug,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        label: 'Monitor',
                        icon: Icons.analytics_rounded,
                        gradient: const LinearGradient(
                          colors: [AppTheme.ijoGelap, AppTheme.ijoTerang],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MonitoringSurveyPage(
                                surveyName: survey.title,
                                clientSlug: clientSlug,
                                projectSlug: projectSlug,
                                surveySlug: survey.slug,
                                totalRespon: survey.responseCount,
                                targetLocation: survey.targetLocation,
                                isOpen: survey.isOpen,
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildStatusBadge() {
    final bool isActive = survey.isOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.primary : AppTheme.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isActive ? 'AKTIF' : 'DITUTUP',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isActive ? AppTheme.primary : AppTheme.error,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _infoEntry(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, {bool isSpecial = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSpecial
            ? AppTheme.primary.withOpacity(0.05)
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(isSpecial ? 0.3 : 0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: isSpecial ? FontWeight.w700 : FontWeight.w500,
          color: isSpecial ? AppTheme.primary : AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    Color? color,
    Gradient? gradient,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppTheme.primary).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
