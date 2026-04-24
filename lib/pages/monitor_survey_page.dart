import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/monitoring_provider.dart';
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
            backgroundColor: AppTheme.surface,
            body: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : provider.errorMessage != null
                ? _buildError(context, provider)
                : RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: provider.loadSurvey,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(child: _buildHeader(provider)),
                        SliverToBoxAdapter(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 24),
                                    _buildFilterRow(provider),
                                    const SizedBox(height: 16),
                                    ListResponWidget(
                                      responses: provider.responses,
                                      currentPage: _currentPage,
                                      totalData: provider.responses.length,
                                      perPage: 10,
                                      onPageChanged: (p) =>
                                          setState(() => _currentPage = p),
                                      onDeleteResponse: (id, s, c, pr) =>
                                          provider.deleteResponse(id),
                                      onEditResponse: (id, s, c, pr, data) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CekEditMonitorPage(
                                              responseId: id,
                                              surveySlug: s,
                                              clientSlug: c,
                                              projectSlug: pr,
                                            ),
                                          ),
                                        ).then((_) => provider.loadSurvey());
                                      },
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.surface.withOpacity(0.8),
      elevation: 0,
      pinned: true,
      centerTitle: true,
      expandedHeight: 60,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(vertical: 12),
            centerTitle: true,
            title: Text(
              'Monitoring',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader(MonitoringProvider provider) {
    return Column(
      children: [
        // ══════════════ GRADIENT HEADER ══════════════
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7FDF9), Color(0xFFE9FBF1), Color(0xFFDAF5E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.leaderboard_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'MONITORING SURVEY',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(provider.isOpen),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  provider.resolvedName,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatusBreakdown(provider),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOpen ? AppTheme.primary : AppTheme.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isOpen ? 'DIBUKA' : 'DITUTUP',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isOpen ? AppTheme.primary : AppTheme.error,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown(MonitoringProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAPAIAN STATUS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceVariant.withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusItem('Pending', provider.pendingCount, const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _statusItem('Revision', provider.revisionCount, const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _statusItem('Approved', provider.approvedCount, const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _statusItem('Declined', provider.declinedCount, const Color(0xFF6366F1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusItem(String label, int count, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(MonitoringProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'LIST RESPONSES (${provider.responses.length})',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurfaceVariant.withOpacity(0.8),
            letterSpacing: 1,
          ),
        ),
        _buildSortDropdown(provider),
      ],
    );
  }

  Widget _buildSortDropdown(MonitoringProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: provider.isNewestFirst,
          icon: const Icon(Icons.sort_rounded, size: 16, color: AppTheme.primary),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
          onChanged: (val) {
            if (val != null) provider.toggleSortOrder(val);
          },
          items: const [
            DropdownMenuItem(value: true, child: Text('Terbaru')),
            DropdownMenuItem(value: false, child: Text('Terlama')),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, MonitoringProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage!,
            style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.loadSurvey,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
