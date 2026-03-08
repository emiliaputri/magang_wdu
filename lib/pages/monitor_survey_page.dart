import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/monitoring_surveys/pulse_dot.dart';
import '../widgets/monitoring_surveys/list_respon_widget.dart';

class MonitoringSurveyPage extends StatefulWidget {
  final String surveyName;
  final String clientSlug;
  final String projectSlug;
  final String surveySlug;

  final int    totalRespon;
  final String targetLocation;
  final bool   isOpen;

  const MonitoringSurveyPage({
    super.key,
    required this.surveyName,
    required this.clientSlug,
    required this.projectSlug,
    required this.surveySlug,
    this.totalRespon    = 0,
    this.targetLocation = '-',
    this.isOpen         = true,
  });

  @override
  State<MonitoringSurveyPage> createState() => _MonitoringSurveyPageState();
}

class _MonitoringSurveyPageState extends State<MonitoringSurveyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MonitoringProvider(
        surveyName:  widget.surveyName,
        clientSlug:  widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug:  widget.surveySlug,
      )..loadSurvey(),
      child: Consumer<MonitoringProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppTheme.monBgColor,
            body: Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.monGreenMid),
                        )
                      : provider.errorMessage != null
                          ? _buildError(context, provider)
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: RefreshIndicator(
                                  color: AppTheme.monGreenMid,
                                  onRefresh: provider.loadSurvey,
                                  child: SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 20, 16, 32),
                                    child: ListResponWidget(
                                      responses:     provider.responses,
                                      currentPage:   _currentPage,
                                      totalData:     provider.totalRespon,
                                      perPage:       10,
                                      onPageChanged: (page) =>
                                          setState(() => _currentPage = page),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── ERROR ──────────────────────────────────────────────────
  Widget _buildError(BuildContext context, MonitoringProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.loadSurvey,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.monGreenMid,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, MonitoringProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.monGreenDark,
            AppTheme.monGreenMid,
            AppTheme.monGreenLight,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(top: -30, right: -30, child: _blob(150, 0.06)),
            Positioned(bottom: -40, left: -20, child: _blob(120, 0.04)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: _circleBtn(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                      _statusBadge(provider.isOpen),
                      const Spacer(),
                      _circleBtn(Icons.more_vert_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'MONITORING SURVEY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white60,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.resolvedName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Mini stats di header ───────────────────
                  Row(
                    children: [
                      _headerChip(
                        Icons.bar_chart_rounded,
                        '${provider.totalRespon} Respon',
                      ),
                      const SizedBox(width: 8),
                      _headerChip(
                        Icons.location_on_rounded,
                        _locationLabel(provider.targetLocation),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, double opacity) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _circleBtn(IconData icon) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      );

  Widget _statusBadge(bool open) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseDot(active: open),
            const SizedBox(width: 6),
            Text(
              open ? 'DIBUKA' : 'DITUTUP',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );

  String _locationLabel(String raw) {
    if (raw.isEmpty || raw == '-') return 'Semua Wilayah';
    final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length == 1) return parts.first;
    return '${parts.length} Provinsi';
  }

  Widget _headerChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}