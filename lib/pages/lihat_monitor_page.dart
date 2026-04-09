import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
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
      backgroundColor: AppTheme.monBgColor,
      body: Column(
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.monGreenDark, AppTheme.monGreenMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Text(
                'Monitor Detail',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Detail Responden Survey",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Analisis data responden terdaftar, campaign, dan guest",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
    final location = _detail?.location;
    final userData = responses?['user'] as Map<String, dynamic>?;
    final biodata = _detail?.biodata;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.monBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.monGreenMid,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "INFORMASI DASAR & LOKASI",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppTheme.monTextMid,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildLeftInfoColumn(
                        userData,
                        biodata,
                        _timelineStart,
                        _timelineFinish,
                        _timelineDuration,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 400,
                      color: const Color(0xFFF0F0F0),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildRightGeotaggingColumn(location),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildLeftInfoColumn(
                      userData,
                      biodata,
                      _timelineStart,
                      _timelineFinish,
                      _timelineDuration,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF0F0F0),
                    ),
                    _buildRightGeotaggingColumn(location),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeftInfoColumn(
    Map<String, dynamic>? userData,
    Map<String, dynamic>? biodata,
    dynamic start,
    dynamic finish,
    dynamic duration,
  ) {
    final name = userData?['name'] ?? _detail?.responses?['email'] ?? 'Guest';
    final province = _getProvinsi(biodata);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.monTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Instansi tidak tersedia",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.monTextLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEDFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.public,
                            size: 14,
                            color: Color(0xFF3F51B5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            province == '-' ? "Tidak ada provinsi" : province,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3F51B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1, color: Color(0xFFF8F8F8)),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ALAMAT",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.monTextLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      size: 20,
                      color: AppTheme.monTextMid,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "Alamat tidak tersedia",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.monTextDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        _buildTimelineFooter(
          _timelineStart,
          _timelineFinish,
          _timelineDuration,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String label,
    String value,
    Color color, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.monTextLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (icon != null)
              Icon(icon, size: 14, color: color)
            else
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineFooter(String start, String finish, String durasi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTimelineItem("MULAI", start, Colors.green),
          _buildTimelineItem("SELESAI", finish, Colors.blue),
          _buildTimelineItem(
            "DURASI",
            durasi,
            Colors.orange,
            icon: Icons.access_time_rounded,
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

  Widget _buildRightGeotaggingColumn(Map<String, dynamic>? location) {
    final ip = location?['ip']?.toString() ?? '-';
    final wilayah = _getWilayah(location);
    final lat = location?['latitude']?.toString() ?? '-';
    final lng = location?['longitude']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.monGreenMid,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Geotagging",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.monTextDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "GPS Aktif",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryWide = constraints.maxWidth > 350;
              if (isVeryWide) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildGeoItem(
                            "IP ADDRESS",
                            ip,
                            Icons.language_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGeoItem(
                            "KOTA / WILAYAH",
                            wilayah,
                            Icons.location_city_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCoordinateRow(lat, lng),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildGeoItem("IP ADDRESS", ip, Icons.language_rounded),
                    const SizedBox(height: 16),
                    _buildGeoItem(
                      "KOTA / WILAYAH",
                      wilayah,
                      Icons.location_city_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildCoordinateRow(lat, lng),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),
          _buildEnhancedMapPreview(location),
        ],
      ),
    );
  }

  Widget _buildGeoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.monTextLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppTheme.monTextLight),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.monTextDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoordinateRow(String lat, String lng) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "KOORDINAT",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppTheme.monTextLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.map_outlined,
                size: 16,
                color: AppTheme.monTextLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "$lat, $lng",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.monTextDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final url = 'https://www.google.com/maps?q=$lat,$lng';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 12,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Maps",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMapPreview(Map<String, dynamic>? location) {
    final lat = double.tryParse(location?['latitude']?.toString() ?? '');
    final lng = double.tryParse(location?['longitude']?.toString() ?? '');

    if (lat == null || lng == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                color: AppTheme.monTextLight,
                size: 32,
              ),
              SizedBox(height: 12),
              Text(
                "Peta tidak tersedia",
                style: TextStyle(color: AppTheme.monTextLight, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_application_wdu',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
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

  String _getProvinsi(Map<String, dynamic>? biodata) {
    if (biodata == null) return '-';
    final id = biodata['province_id'];
    final name = biodata['province_name'];
    if (name != null && name.toString().isNotEmpty) return name.toString();
    if (id != null) return 'Prov. $id';
    return '-';
  }

  List<Widget> _buildQuestionsList() {
    if (_detail == null) return [];

    debugPrint(
      'DEBUG _buildQuestionsList: pages count = ${_detail!.pages.length}',
    );
    for (var p in _detail!.pages) {
      debugPrint(
        'DEBUG: Page ${p.pageName} has ${p.questions.length} questions',
      );
    }

    final currentResponseId = widget.responseId;

    List<Widget> list = [];

    for (var page in _detail!.pages) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Text(
            page.pageName.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

      for (var q in page.questions) {
        debugPrint(
          'DEBUG: Question ${q.id} has ${q.embeddedAnswers.length} embedded answers',
        );

        // Get raw answer for this specific responseId
        String rawAnswer = "-";

        // Check embedded answers and filter by responseId
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
        list.add(const SizedBox(height: 12));
      }
    }

    return list;
  }

  // Hapus _formatAnswer karena sekarang _buildAnswerDisplay yang handle

  dynamic _parseJson(String jsonStr) {
    try {
      return jsonStr.isEmpty
          ? {}
          : jsonStr.startsWith('[')
          ? jsonDecode(jsonStr) as List
          : jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Widget _buildQuestionCard(SurveyQuestionData q, String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.plainText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF202124),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnswerDisplay(q, answer),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay(SurveyQuestionData q, String answer) {
    // Matrix question (type_id = 9)
    if (q.isMatrix && q.matrixRows.isNotEmpty) {
      return _buildMatrixAnswer(q, answer);
    }

    // Checkbox question (type_id = 3)
    if (q.questionTypeId == 3 && q.choices.isNotEmpty) {
      return _buildCheckboxAnswer(q, answer);
    }

    // Radio question (type_id = 2)
    if (q.questionTypeId == 2 && q.choices.isNotEmpty) {
      return _buildRadioAnswer(q, answer);
    }

    // Dropdown question (type_id = 7)
    if (q.questionTypeId == 7 && q.choices.isNotEmpty) {
      return _buildRadioAnswer(q, answer);
    }

    // Text, number, paragraph - show as plain text
    if (answer.isEmpty || answer == "-" || answer == "Unknown") {
      return _buildEmptyAnswer();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.monBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.reply, size: 14, color: AppTheme.monGreenMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.monGreenDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixAnswer(SurveyQuestionData q, String answer) {
    if (answer.isEmpty || answer == "-" || answer == "Unknown") {
      return _buildEmptyAnswer();
    }

    try {
      final Map<String, dynamic> parsed = Map<String, dynamic>.from(
        _parseJson(answer),
      );

      if (parsed.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.monBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(answer, style: const TextStyle(fontSize: 12)),
        );
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header columns (SS, S, TS, STS)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Pernyataan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(4, (i) {
                    return Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          ['SS', 'S', 'TS', 'STS'][i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Table rows
            ...List.generate(q.matrixRows.length, (index) {
              final rowKey = 'row-$index';
              final selectedValue = parsed[rowKey] as int? ?? -1;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    // Row label
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Text(
                          q.matrixRows[index].label.replaceAll(
                            RegExp(r'^\d+\.\s*'),
                            '',
                          ),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    // Radio buttons for each column
                    ...List.generate(4, (colIndex) {
                      final isSelected = selectedValue == colIndex;
                      return Expanded(
                        flex: 1,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? _getMatrixColor(colIndex)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? _getMatrixColor(colIndex)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.monBgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(answer, style: const TextStyle(fontSize: 12)),
      );
    }
  }

  Color _getMatrixColor(int value) {
    switch (value) {
      case 0:
        return AppTheme.monGreenDark; // SS
      case 1:
        return AppTheme.monGreenMid; // S
      case 2:
        return Colors.orange; // TS
      case 3:
        return Colors.red; // STS
      default:
        return Colors.grey;
    }
  }

  Widget _buildCheckboxAnswer(SurveyQuestionData q, String answer) {
    if (answer.isEmpty || answer == "-" || answer == "Unknown") {
      return _buildEmptyAnswer();
    }

    try {
      final List<String> selectedIds = [];

      if (answer.startsWith('[')) {
        final List<dynamic> parsed = _parseJson(answer);
        for (var item in parsed) {
          selectedIds.add(item.toString());
        }
      } else {
        selectedIds.add(answer);
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: q.choices
              .asMap()
              .map((index, opt) {
                final optId = opt.id.toString();
                final isChecked = selectedIds.contains(optId);
                final isLast = index == q.choices.length - 1;

                return MapEntry(
                  index,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? const Color(0xFFF0F7FF)
                          : Colors.transparent,
                      border: Border(
                        bottom: !isLast
                            ? BorderSide(color: Colors.grey.shade200)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? const Color(0xFF4285F4)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isChecked
                                  ? const Color(0xFF4285F4)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            opt.value,
                            style: TextStyle(
                              fontSize: 12,
                              color: isChecked
                                  ? const Color(0xFF202124)
                                  : Colors.grey.shade700,
                              fontWeight: isChecked
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .values
              .toList(),
        ),
      );
    } catch (e) {
      return _buildTextInputAnswer(answer);
    }
  }

  Widget _buildTextInputAnswer(String answer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.text_fields, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              answer.isEmpty ? 'Tidak dijawab' : answer,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioAnswer(SurveyQuestionData q, String answer) {
    if (answer.isEmpty || answer == "-" || answer == "Unknown") {
      return _buildEmptyAnswer();
    }

    String? selectedValue;
    for (var choice in q.choices) {
      if (choice.id.toString() == answer) {
        selectedValue = choice.value;
        break;
      }
    }

    final displayValue = selectedValue ?? answer;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: q.choices
            .asMap()
            .map((index, choice) {
              final isSelected =
                  choice.value == selectedValue ||
                  choice.id.toString() == answer;
              final isLast = index == q.choices.length - 1;

              return MapEntry(
                index,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF0F7FF)
                        : Colors.transparent,
                    border: Border(
                      bottom: !isLast
                          ? BorderSide(color: Colors.grey.shade200)
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF4285F4)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4285F4)
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          choice.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFF202124)
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .values
            .toList(),
      ),
    );
  }

  Widget _buildEmptyAnswer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.remove_circle_outline, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(
            'Tidak dijawab',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getMatrixColumnLabel(int value, List<MatrixColumnData> columns) {
    const columnLabels = ['SS', 'S', 'TS', 'STS', 'TR'];
    if (value >= 0 && value < columnLabels.length) {
      return columnLabels[value];
    }
    return 'N/A';
  }
}
