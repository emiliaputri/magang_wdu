import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/monitoring_surveys/pulse_dot.dart';
import '../widgets/monitoring_surveys/list_respon_widget.dart';
import 'cek_edit_monitor.dart';

class MonitoringSurveyPage extends StatefulWidget {
  final String surveyName;
  final String clientSlug;
  final String projectSlug;
  final String surveySlug;

  final int totalRespon;
  final String targetLocation;
  final bool isOpen;

  const MonitoringSurveyPage({
    super.key,
    required this.surveyName,
    required this.clientSlug,
    required this.projectSlug,
    required this.surveySlug,
    this.totalRespon = 0,
    this.targetLocation = '-',
    this.isOpen = true,
  });

  @override
  State<MonitoringSurveyPage> createState() => _MonitoringSurveyPageState();
}

class _MonitoringSurveyPageState extends State<MonitoringSurveyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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
        surveyName: widget.surveyName,
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
      )..loadSurvey(),
      child: Consumer<MonitoringProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AppBar(
                    backgroundColor: const Color(0xFFF8FAF8).withValues(alpha: 0.8),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15803D), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.leaderboard, color: Color(0xFF15803D)),
                        SizedBox(width: 8),
                        Text(
                          'SIS',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout, color: Color(0xFF78716C)),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
            body: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006B1B),
                    ),
                  )
                : provider.errorMessage != null
                    ? _buildError(context, provider)
                    : RefreshIndicator(
                        color: const Color(0xFF006B1B),
                        onRefresh: provider.loadSurvey,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                children: [
                                  _buildHero(context, provider),
                                  Transform.translate(
                                    offset: const Offset(0, -32),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: ListResponWidget(
                                        responses: provider.responses,
                                        currentPage: _currentPage,
                                        totalData: provider.totalRespon,
                                        perPage: 10,
                                        onPageChanged: (page) =>
                                            setState(() => _currentPage = page),
                                        onDeleteResponse:
                                            (
                                              responseId,
                                              surveySlug,
                                              clientSlug,
                                              projectSlug,
                                            ) async {
                                              final success = await provider
                                                  .deleteResponse(responseId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success
                                                          ? 'Data berhasil dihapus'
                                                          : 'Gagal menghapus data',
                                                    ),
                                                    backgroundColor: success
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                        onEditResponse: (
                                          responseId,
                                          surveySlug,
                                          clientSlug,
                                          projectSlug,
                                          responseData,
                                        ) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => CekEditMonitorPage(
                                                    surveySlug: surveySlug,
                                                    clientSlug: clientSlug,
                                                    projectSlug: projectSlug,
                                                    responseId: responseId,
                                                  ),
                                            ),
                                          ).then((_) => provider.loadSurvey());
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO ───────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, MonitoringProvider provider) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006B1B), Color(0xFF268630)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 72),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitoring Survey',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.resolvedName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _pillBadge(Icons.groups, '${provider.totalRespon} Respon'),
                  const SizedBox(width: 12),
                  _pillBadge(Icons.map, _locationLabel(provider.targetLocation)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  String _locationLabel(String raw) {
    if (raw.isEmpty || raw == '-') return 'Semua Wilayah';
    final parts = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first;
    return '${parts.length} Provinsi';
  }
}
