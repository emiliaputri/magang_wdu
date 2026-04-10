import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../pages/monitor_survey_page.dart';
import '../../pages/province_target_page.dart';
import '../../pages/cek_edit_survey_page.dart';
import '../../pages/biodata_page.dart';
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
                      horizontal: 8, // 🔥 kecilin
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 12, // 🔥 kecil
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${survey.responseCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10, // 🔥 kecil
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── DESCRIPTION ──
            if (survey.desc != null && survey.desc!.isNotEmpty)
              Text(
                survey.desc!,
                maxLines: 2, // 🔥 penting
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF777777),
                  height: 1.3,
                ),
              ),

            const SizedBox(height: 8),

            // ── LOCATION + STATUS ──
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: Color(0xFFAAAAAA),
                ),
                const SizedBox(width: 3),
                if (survey.provinceTargets.isEmpty)
                  Expanded(
                    child: Text(
                      survey.targetLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isOpen ? 'DIBUKA' : 'DITUTUP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isOpen
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFB71C1C),
                    ),
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
                    label: hasAnswered ? 'Edit' : 'Isi',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      if (hasAnswered) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CekEditSurveyPage(
                              surveySlug: survey.slug,
                              clientSlug: clientSlug,
                              projectSlug: projectSlug,
                              responseId: 0,
                            ),
                          ),
                        );
                      } else {
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
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8), // 🔥 dari 24 → 8
                Expanded(
                  child: _ActionBtn(
                    label: 'Monitor',
                    color: const Color(0xFF5C6BC0),
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