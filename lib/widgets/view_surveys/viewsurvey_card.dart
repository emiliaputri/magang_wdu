import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../pages/monitor_survey_page.dart';
import '../../pages/province_target_page.dart';
import '../../pages/camera_capture_page.dart';
import '../../models/survey_model.dart';

class ViewSurveyCard extends StatelessWidget {
  final SurveyModel survey;
  final String clientSlug;
  final String projectSlug;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onTapResponden;
  final VoidCallback onCekEdit;
  final bool hasAnswered;

  const ViewSurveyCard({
    super.key,
    required this.survey,
    required this.clientSlug,
    required this.projectSlug,
    required this.onRefresh,
    required this.onDelete,
    required this.onTapResponden,
    required this.onCekEdit,
    this.hasAnswered = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOpen = survey.isOpen;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // 🔥 diperkecil
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // 🔥 lebih ringan
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // 🔥 dari 16 → 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TITLE + RESPONSE ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    maxLines: 2, // 🔥 penting
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11, // 🔥 dari 12 → 11
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onTapResponden,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${survey.responseCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── DESCRIPTION ──
            if (survey.desc != null && survey.desc!.isNotEmpty)
              Text(
                survey.desc!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),

            const SizedBox(height: 12),

            // ── LOCATION + STATUS ──
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                if (survey.provinceTargets.isEmpty)
                  Expanded(
                    child: Text(
                      survey.targetLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppTheme.primaryContainer
                        : AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOpen ? AppTheme.primary : AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOpen ? 'DIBUKA' : 'DITUTUP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOpen
                              ? AppTheme.onPrimaryContainer
                              : AppTheme.error,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(), // 🔥 KUNCI BIAR MUAT DI GRID

            const Divider(height: 1),
            const SizedBox(height: 6),

            // ── BUTTONS FIX ──
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Isi Kuesioner',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CameraCapturePage(
                            surveySlug: survey.slug,
                            clientSlug: clientSlug,
                            projectSlug: projectSlug,
                            surveyTitle: survey.title,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8), // 🔥 dari 24 → 8
                Expanded(
                  child: _ActionBtn(
                    label: 'Monitor',
                    color: AppTheme.primary,
                    onTap: () => Navigator.push(
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
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── BUTTON FIX ──
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30, // 🔥 kecilin
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10, // 🔥 kecil
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
}