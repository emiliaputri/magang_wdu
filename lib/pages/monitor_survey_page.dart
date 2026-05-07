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
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: AppBar(
                    backgroundColor: const Color(
                      0xFFF8FAF8,
                    ).withValues(alpha: 0.8),
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.leaderboard, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'SIS',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    actions: const [],
                  ),
                ),
              ),
            ),
            body: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006B1B)),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Filter UI
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showFilterSheet(
                                              context,
                                              provider,
                                            ),
                                            child: Container(
                                              height: 28,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    provider.dateFilter != 'all'
                                                    ? const Color(0xFF15803D)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF15803D,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.filter_list,
                                                    size: 14,
                                                    color:
                                                        provider.dateFilter !=
                                                            'all'
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF15803D,
                                                          ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    provider.dateFilter != 'all'
                                                        ? _filterLabel(
                                                            provider.dateFilter,
                                                          )
                                                        : 'Filter',
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          provider.dateFilter !=
                                                              'all'
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF15803D,
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (provider.responses.isEmpty)
                                        _buildEmptyFilterState(provider)
                                      else
                                        ListResponWidget(
                                          responses: provider.responses,
                                          currentPage: _currentPage,
                                          totalData: provider.totalRespon,
                                          perPage: 10,
                                          onPageChanged: (page) => setState(
                                            () => _currentPage = page,
                                          ),
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
                                          onEditResponse:
                                              (
                                                responseId,
                                                surveySlug,
                                                clientSlug,
                                                projectSlug,
                                                responseData,
                                              ) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        CekEditMonitorPage(
                                                          surveySlug:
                                                              surveySlug,
                                                          clientSlug:
                                                              clientSlug,
                                                          projectSlug:
                                                              projectSlug,
                                                          responseId:
                                                              responseId,
                                                        ),
                                                  ),
                                                ).then(
                                                  (_) => provider.loadSurvey(),
                                                );
                                              },
                                        ),
                                    ],
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
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.ijoTerang,
            AppTheme.ijoGelap,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 72),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitoring Survey',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _pillBadge(
                    Icons.groups,
                    '${provider.totalRespon} Respon',
                    const Color(0xFF64B5F6),
                  ),
                  const SizedBox(width: 12),
                  _pillBadge(
                    Icons.map,
                    _locationLabel(provider.targetLocation),
                    const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(IconData icon, String text, Color iconColor) {
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
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
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

  String _filterLabel(String filter) {
    switch (filter) {
      case 'last_week':
        return 'Minggu lalu';
      case 'last_month':
        return 'Bulan lalu';
      case 'last_year':
        return 'Setahun terakhir';
      case 'custom':
        return 'Rentang tanggal';
      default:
        return 'Filter';
    }
  }

  String _fmtShortDate(DateTime dt) {
    final m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  void _showFilterSheet(BuildContext context, MonitoringProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final Map<String, String> options = {
              'all': 'Semua tanggal',
              'last_week': 'Minggu lalu',
              'last_month': 'Bulan lalu',
              'last_year': 'Setahun terakhir',
              'custom': 'Rentang tanggal',
            };

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Filter berdasarkan tanggal',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ...options.entries.map((entry) {
                      final isCustom = entry.key == 'custom';
                      final isSelected = provider.dateFilter == entry.key;
                      return InkWell(
                        onTap: () async {
                          if (isCustom) {
                            final picked = await showDateRangePicker(
                              context: sheetCtx,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              initialDateRange: provider.customDateRange,
                              builder: (ctx, child) {
                                return Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF15803D),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              provider.setDateFilter(
                                'custom',
                                customRange: picked,
                              );
                              setState(() => _currentPage = 1);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            }
                          } else {
                            provider.setDateFilter(entry.key);
                            setState(() => _currentPage = 1);
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: isSelected
                                            ? const Color(0xFF15803D)
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    // Tampilkan rentang tanggal yang dipilih
                                    if (isCustom &&
                                        isSelected &&
                                        provider.customDateRange != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${_fmtShortDate(provider.customDateRange!.start)} - ${_fmtShortDate(provider.customDateRange!.end)}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF6F7A6B),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isCustom && !isSelected)
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
                                )
                              else
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFE5E7EB),
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: isSelected
                                      ? Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF15803D),
                                          ),
                                        )
                                      : null,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyFilterState(MonitoringProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Data tidak ditemukan',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              provider.setDateFilter('all');
              setState(() => _currentPage = 1);
            },
            child: Text(
              'Tampilkan semua data',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
