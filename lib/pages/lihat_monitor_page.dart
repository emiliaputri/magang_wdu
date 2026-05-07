import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/endpoints.dart';
import '../service/survey_service.dart';
import '../models/survey_response_detail_model.dart';

class LihatMonitorPage extends StatefulWidget {
  final int responseId;
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;

  const LihatMonitorPage({
    super.key,
    required this.responseId,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
  });

  @override
  State<LihatMonitorPage> createState() => _LihatMonitorPageState();
}

class _LihatMonitorPageState extends State<LihatMonitorPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  SurveyResponseDetail? _detail;

  late String _timelineStart;
  late String _timelineFinish;
  late String _timelineDuration;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _timelineStart = '-';
    _timelineFinish = '-';
    _timelineDuration = '-';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await SurveyService().getFullSurveyDetail(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        responseId: widget.responseId,
      );

      if (detail != null) {
        _calculateTimeline(detail);
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Data tidak ditemukan.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.monSurface,
      body: Container(
        decoration: BoxDecoration(
          color: AppTheme.monSurface,
          gradient: RadialGradient(
            center: const Alignment(-1, -1),
            radius: 1.5,
            colors: [
              AppTheme.monPrimary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.monGreenMid,
                      ),
                    )
                  : _errorMessage != null
                  ? _buildErrorUI()
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRespondentInfo(),
                              const SizedBox(height: 24),
                              ..._buildQuestionsList(),
                              const SizedBox(height: 100),
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
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.ijoTerang,
            AppTheme.ijoGelap,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Monitor Detail',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance spacer
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Responden Survey',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Analisis data responden terdaftar, campaign, dan guest',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.monPrimary, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Terjadi kesalahan"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  Widget _buildRespondentInfo() {
    final responses = _detail?.responses;
    final userData = responses?['user'] as Map<String, dynamic>?;
    final userObj = userData?['user'] as Map<String, dynamic>? ?? userData;
    final name =
        userObj?['name'] ??
        userData?['email'] ??
        _detail?.responses?['email'] ??
        'Guest';
    final userType = userObj?['usertype'] ?? 'USER';
    final responseIdStr = "ID: #SRV-${widget.responseId}";

    return Column(
      children: [
        // Respondent Profile Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getAvatarGradient(name),
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.monPrimary,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.monOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.monSecondaryContainer.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            userType.toString().toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.monSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '•',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          responseIdStr,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bento Grid Content
        _buildBentoGrid(),
      ],
    );
  }

  Widget _buildBentoGrid() {
    final responses = _detail?.responses;
    final location = _detail?.location;
    final biodata = _detail?.biodata;
    final ip = location?['ip']?.toString() ?? '-';
    final provider = location?['provider']?.toString() ?? 'Telkomsel';
    final city = _getWilayah(location);

    final latRaw =
        responses?['latitude'] ?? biodata?['latitude'] ?? location?['latitude'];
    final lngRaw =
        responses?['longitude'] ??
        biodata?['longitude'] ??
        location?['longitude'];
    final lat = latRaw?.toString() ?? '-';
    final lng = lngRaw?.toString() ?? '-';

    return Column(
      children: [
        // Timing Card (Full Width)
        _buildTimingCard(),
        const SizedBox(height: 16),
        // IP Address Card (Full Width now)
        _buildIPCard(ip, provider),
        const SizedBox(height: 16),
        // Location Card
        _buildLocationCard(city, lat, lng),
      ],
    );
  }

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.monSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppTheme.monSecondary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SURVEY TIMING',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimingItem('START', _timelineStart.split('\n').last),
              const SizedBox(width: 8),
              _buildTimingItem('FINISH', _timelineFinish.split('\n').last),
              const SizedBox(width: 8),
              _buildTimingItem('DURATION', _timelineDuration, isDuration: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimingItem(
    String label,
    String value, {
    bool isDuration = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDuration
              ? AppTheme.monSecondaryFixed.withValues(alpha: 0.3)
              : AppTheme.monSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDuration
                ? AppTheme.monSecondaryFixed
                : Colors.grey.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDuration ? AppTheme.monSecondary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDuration
                    ? AppTheme.monSecondary
                    : AppTheme.monOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIPCard(String ip, String provider) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lan_rounded,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'IP ADDRESS',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ip,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.monOnSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Provider: $provider',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String city, String lat, String lng) {
    final biodata = _detail?.biodata;
    final responses = _detail?.responses;
    final address =
        biodata?['address'] ??
        responses?['address'] ??
        biodata?['alamat'] ??
        responses?['alamat'] ??
        'Alamat tidak tersedia';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.monPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 20,
                        color: AppTheme.monPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KOTA / WILAYAH',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  city,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.monPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF8F8F8)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      color: AppTheme.monPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ALAMAT LENGKAP',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              color: AppTheme.monOnSurface,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    _buildEnhancedMapPreview(lat, lng),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.my_location_rounded,
                              size: 14,
                              color: AppTheme.monPrimary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'GEOTAGGED',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.monOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildCoordItem('LATITUDE', lat),
                    const SizedBox(width: 16),
                    _buildCoordItem('LONGITUDE', lng),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.monOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _calculateTimeline(SurveyResponseDetail detail) {
    final responses = detail.responses;
    final startRaw =
        responses?['started_at'] ??
        responses?['created_at'] ??
        detail.editedAt?.toString();
    final finishRaw =
        responses?['finished_at'] ??
        responses?['updated_at'] ??
        detail.editedAt?.toString();

    String formatTime(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      try {
        final dt = DateTime.parse(raw);
        final monthNames = [
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
        return '${dt.day.toString().padLeft(2, '0')} ${monthNames[dt.month]} ${dt.year}\n${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return '-';
      }
    }

    String calcDuration(String? start, String? finish) {
      if (start == null || finish == null || start.isEmpty || finish.isEmpty)
        return '-';
      try {
        final s = DateTime.parse(start);
        final f = DateTime.parse(finish);
        final diff = f.difference(s);
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        if (h > 0) return '${h}j ${m}m';
        return '${m}m';
      } catch (_) {
        return '-';
      }
    }

    _timelineStart = formatTime(startRaw);
    _timelineFinish = formatTime(finishRaw);
    _timelineDuration = calcDuration(startRaw, finishRaw);
  }

  String _getWilayah(Map<String, dynamic>? location) {
    if (location == null) return '-';
    final city = location['city'];
    final region = location['region'];
    if (city != null &&
        city.toString().isNotEmpty &&
        region != null &&
        region.toString().isNotEmpty) {
      return '$city, $region';
    }
    if (city != null && city.toString().isNotEmpty) return city.toString();
    if (region != null && region.toString().isNotEmpty)
      return region.toString();
    return 'Unknown';
  }

  String _getProvinsi(
    Map<String, dynamic>? biodata, [
    Map<String, dynamic>? responses,
  ]) {
    if (biodata == null && responses == null) return '-';
    final bName = biodata?['province_name'];
    if (bName != null && bName.toString().isNotEmpty) return bName.toString();
    final rProvId = responses?['response_province_id'];
    if (rProvId != null) return 'Provinsi ID: $rProvId';
    final bId = biodata?['province_id'];
    if (bId != null) return 'Prov. $bId';
    return '-';
  }

  List<Widget> _buildQuestionsList() {
    if (_detail == null) return [];
    final currentResponseId = widget.responseId;
    List<Widget> list = [];

    for (var page in _detail!.pages) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 24),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.monPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                page.pageName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.monPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );

      for (var q in page.questions) {
        String rawAnswer = "-";
        if (q.embeddedAnswers.isNotEmpty) {
          final matchingAnswer = q.embeddedAnswers.firstWhere(
            (a) => a['response_id'] == currentResponseId,
            orElse: () => <String, dynamic>{},
          );
          if (matchingAnswer.isNotEmpty) {
            rawAnswer = matchingAnswer['answer']?.toString() ?? "-";
          }
        }
        list.add(_buildQuestionCard(q, rawAnswer));
        list.add(const SizedBox(height: 16));
      }
    }
    return list;
  }

  Widget _buildQuestionCard(SurveyQuestionData q, String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.plainText,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.monOnSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnswerDisplay(q, answer),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay(SurveyQuestionData q, String answer) {
    if (q.typeString == 'info') return const SizedBox.shrink();

    if (q.typeString == 'matrix') {
      if (q.matrixRows.isNotEmpty && q.matrixColumns.isNotEmpty) {
        return _buildMatrixAnswer(q, answer);
      }
      if (answer.isNotEmpty && answer != "-" && answer != "Unknown") {
        return _buildAnswerContainer(answer);
      }
      return _buildEmptyAnswer();
    }

    if (q.questionTypeId == 10) {
      if (answer.isNotEmpty && answer != "-" && answer != "Unknown") {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.monSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.insert_drive_file_rounded,
                size: 24,
                color: AppTheme.monPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.monOnSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Klik untuk membuka file",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 20,
                  color: AppTheme.monPrimary,
                ),
                onPressed: () async {
                  final url = "${Endpoints.storageUrl}/documents/$answer";
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      }
      return _buildEmptyAnswer();
    }

    if (q.typeString == 'checkbox' && q.choices.isNotEmpty)
      return _buildCheckboxAnswer(q, answer);
    if ((q.typeString == 'radio' || q.typeString == 'dropdown') &&
        q.choices.isNotEmpty)
      return _buildRadioAnswer(q, answer);

    if (q.questionTypeId == 11) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.monPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.monPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 16,
              color: AppTheme.monPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                answer,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.monPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (answer.isEmpty || answer == "-" || answer == "Unknown")
      return _buildEmptyAnswer();
    return _buildAnswerContainer(answer);
  }

  Widget _buildAnswerContainer(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.monSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reply_rounded, size: 16, color: AppTheme.monPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.monOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnswer() {
    return Text(
      "Belum ada jawaban",
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildCheckboxAnswer(SurveyQuestionData q, String answer) {
    List<String> selectedLabels = [];
    try {
      final decoded = jsonDecode(answer);
      if (decoded is List) {
        for (var id in decoded) {
          final choice = q.choices.firstWhere(
            (c) => c.id.toString() == id.toString(),
            orElse: () =>
                QuestionChoiceData(id: 0, value: '', questionId: 0, order: 0),
          );
          if (choice.value.isNotEmpty) selectedLabels.add(choice.value);
        }
      }
    } catch (_) {
      if (answer.isNotEmpty && answer != "-" && answer != "Unknown")
        selectedLabels.add(answer);
    }

    if (selectedLabels.isEmpty) return _buildEmptyAnswer();

    return Column(
      children: selectedLabels
          .map(
            (label) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_box_rounded,
                    size: 18,
                    color: AppTheme.monPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRadioAnswer(SurveyQuestionData q, String answer) {
    String label = answer;
    try {
      final choice = q.choices.firstWhere(
        (c) => c.id.toString() == answer,
        orElse: () =>
            QuestionChoiceData(id: 0, value: '', questionId: 0, order: 0),
      );
      if (choice.value.isNotEmpty) label = choice.value;
    } catch (_) {}

    return Row(
      children: [
        const Icon(
          Icons.radio_button_checked_rounded,
          size: 18,
          color: AppTheme.monPrimary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixAnswer(SurveyQuestionData q, String answer) {
    Map<String, dynamic> parsed = {};
    try {
      parsed = jsonDecode(answer) as Map<String, dynamic>;
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.monSurface),
            columns: [
              const DataColumn(
                label: Text(
                  'Pernyataan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...q.matrixColumns.map(
                (col) => DataColumn(
                  label: Text(
                    col.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            rows: q.matrixRows.asMap().entries.map((rowEntry) {
              final rowIndex = rowEntry.key;
              final row = rowEntry.value;
              return DataRow(
                cells: [
                  DataCell(Text(row.label)),
                  ...q.matrixColumns.asMap().entries.map((colEntry) {
                    final colIndex = colEntry.key;
                    bool isSelected = false;
                    final val = parsed[rowIndex.toString()];
                    if (q.matrixType == 'radio') {
                      isSelected = val?.toString() == colIndex.toString();
                    } else if (val is List) {
                      isSelected = val.any(
                        (v) => v.toString() == colIndex.toString(),
                      );
                    }
                    return DataCell(
                      Center(
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppTheme.monPrimary
                              : Colors.grey.withValues(alpha: 0.3),
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMapPreview(String latStr, String lngStr) {
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    if (lat == null || lng == null) return _buildEmptyMap();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: LatLng(lat, lng), initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMap() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.monSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, color: Colors.grey, size: 32),
            SizedBox(height: 8),
            Text(
              "Peta tidak tersedia",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getAvatarGradient(String name) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF6441A5), Color(0xFF2a0845)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFff9966), Color(0xFFff5e62)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFDC830), Color(0xFFF37335)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];
    final index = name.hashCode.abs() % gradients.length;
    return gradients[index];
  }

  dynamic _parseJson(String jsonStr) {
    try {
      return jsonStr.isEmpty ? {} : jsonDecode(jsonStr);
    } catch (_) {
      return {};
    }
  }
}
