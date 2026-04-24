import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/endpoints.dart';
import '../service/survey_service.dart';
import '../models/survey_response_detail_model.dart';
import '../widgets/universal_image.dart';

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

  String _timelineStart = '-';
  String _timelineFinish = '-';
  String _timelineDuration = '-';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
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
      backgroundColor: AppTheme.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _errorMessage != null
          ? _buildErrorUI()
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _fetchData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildSimpleRespondentInfo(),
                              const SizedBox(height: 32),
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
              'Detail Respon',
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

  Widget _buildHeader() {
    return Container(
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
                      const Icon(Icons.assignment_ind_rounded, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'RESPONSE #${widget.responseId}',
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
                _buildStatusBadge(_getModerationStatus(_detail?.responses ?? {})),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _detail?.survey?.title ?? 'Detail Responden',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xff111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _detail?.responses?['user']?['email'] ?? _detail?.responses?['user']?['name'] ?? 'Guest Response',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = const Color(0xFFF59E0B); // Pending
    if (status == 'APPROVE') color = const Color(0xFF10B981);
    if (status == 'REVISION') color = const Color(0xFFEF4444);
    if (status == 'DECLINE') color = const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSimpleRespondentInfo() {
    final location = _detail?.location;

    final latRaw = location?['latitude'];
    final lngRaw = location?['longitude'];
    final coords = (latRaw != null && lngRaw != null) ? "$latRaw, $lngRaw" : "-";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Waktu Mulai', _timelineStart),
          _divider(),
          _infoRow('Waktu Selesai', _timelineFinish),
          _divider(),
          _infoRow('Durasi Pengisian', _timelineDuration),
          _divider(),
          _infoRow('IP Address', location?['ip']?.toString() ?? '-'),
          _divider(),
          _infoRow('Lokasi / Wilayah', _getWilayah(location)),
          _divider(),
          _infoRow('Koordinat GPS', coords, isLink: coords != "-", onLinkTap: () => _openMaps(latRaw, lngRaw)),
          const SizedBox(height: 20),
          _buildMapPreview(latRaw?.toString(), lngRaw?.toString()),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLink = false, VoidCallback? onLinkTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onLinkTap,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLink ? AppTheme.primary : AppTheme.onSurface,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppTheme.outlineVariant.withOpacity(0.05));

  Widget _buildMapPreview(String? latStr, String? lngStr) {
    final lat = double.tryParse(latStr ?? '');
    final lng = double.tryParse(lngStr ?? '');

    if (lat == null || lng == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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
                  child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionsList() {
    if (_detail == null) return [];
    
    List<Widget> list = [];

    for (var page in _detail!.pages) {
      // Cek apakah halaman ini punya minimal satu pertanyaan yang bertipe input/jawaban
      bool hasInputQuestions = page.questions.any((q) => q.typeString != 'info');
      
      // Jika halaman benar-benar tidak ada input (hanya info), sembunyikan seluruh halaman
      if (!hasInputQuestions) continue;

      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            page.pageName.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurfaceVariant.withOpacity(0.6),
              letterSpacing: 1.5,
            ),
          ),
        ),
      );

      for (var q in page.questions) {
        String rawAnswer = "-";
        
        // 1. Cek di root answers (model global)
        final rootAnswer = _detail!.answers.where((a) => a.questionId == q.id).firstOrNull;
        if (rootAnswer != null) {
          rawAnswer = rootAnswer.answer;
        } 
        // 2. Fallback ke embedded answers
        else if (q.embeddedAnswers.isNotEmpty) {
          final matchingAnswer = q.embeddedAnswers.firstWhere(
            (a) => a['response_id'] == widget.responseId,
            orElse: () => <String, dynamic>{},
          );
          if (matchingAnswer.isNotEmpty) {
            rawAnswer = matchingAnswer['answer']?.toString() ?? "-";
          }
        }
        
        list.add(_buildQuestionItem(q, rawAnswer));
        list.add(const SizedBox(height: 12));
      }
    }
    return list;
  }

  Widget _buildQuestionItem(SurveyQuestionData q, String answer) {
    // Tampilan khusus untuk tipe Info (Teks Statis / Deskripsi)
    if (q.typeString == 'info') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        ),
        child: Text(
          q.plainText,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceVariant.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      );
    }

    final isFlagged = q.supervisionNote != null && q.supervisionNote!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFlagged ? AppTheme.error.withOpacity(0.3) : AppTheme.outlineVariant.withOpacity(0.1),
          width: isFlagged ? 1.5 : 1,
        ),
        boxShadow: isFlagged ? [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
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
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
              if (isFlagged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flag_rounded, size: 12, color: AppTheme.error),
                      const SizedBox(width: 4),
                      Text(
                        'FLAGGED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnswerDisplay(q, answer),
          if (isFlagged) ...[
            const SizedBox(height: 16),
            _buildFlaggingNote(q.supervisionNote!),
          ],
        ],
      ),
    );
  }

  Widget _buildFlaggingNote(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Very light red
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.feedback_rounded, size: 14, color: AppTheme.error),
              const SizedBox(width: 8),
              Text(
                'CATATAN SUPERVISI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.error,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF991B1B), // Darker red text
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay(SurveyQuestionData q, String answer) {
    final isEmpty = answer == "-" || answer.isEmpty || answer == "Unknown";
    
    if (isEmpty && !['radio', 'checkbox', 'dropdown'].contains(q.typeString)) {
      return Text(
        'Tidak dijawab',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: AppTheme.onSurfaceVariant.withOpacity(0.4),
        ),
      );
    }

    if (q.typeString == 'matrix') return _buildMatrixAnswer(q, answer);
    
    // Show all options for Radio / Checkbox / Dropdown
    if (['radio', 'checkbox', 'dropdown'].contains(q.typeString)) {
      return _buildChoiceAnswerWithAllOptions(q, answer);
    }

    // Document type (Images/Files)
    if (q.typeString == 'document') {
      return _buildDocumentAnswer(answer);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        answer,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildChoiceAnswerWithAllOptions(SurveyQuestionData q, String answer) {
    List<String> selectedValues = [];
    if (answer.startsWith('[') && answer.endsWith(']')) {
      try {
        final parsed = jsonDecode(answer) as List;
        selectedValues = parsed.map((e) => e.toString()).toList();
      } catch (_) {
        selectedValues = [answer];
      }
    } else {
      selectedValues = [answer];
    }

    return Column(
      children: q.choices.map((choice) {
        final isSelected = selectedValues.contains(choice.id.toString()) || 
                           selectedValues.contains(choice.value);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.outlineVariant.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                q.typeString == 'checkbox' 
                  ? (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                  : (isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                size: 18,
                color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice.value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDocumentAnswer(String answer) {
    final lower = answer.toLowerCase();
    final isImage = lower.endsWith('.jpg') || 
                    lower.endsWith('.jpeg') || 
                    lower.endsWith('.png') || 
                    lower.endsWith('.webp') ||
                    lower.endsWith('.heic');

    if (isImage) {
      // Build proper URL pointing to public/documents (Laravel path)
      String imageUrl = answer;
      if (!answer.startsWith('http')) {
        final root = Endpoints.baseUrl.split('/api').first;
        imageUrl = "$root/documents/$answer";
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: UniversalImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 350,
              errorWidget: Container(
                height: 200,
                width: double.infinity,
                color: AppTheme.surfaceContainerLow,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: AppTheme.outline, size: 32),
                    SizedBox(height: 8),
                    Text('Gagal memuat gambar', style: TextStyle(fontSize: 10, color: AppTheme.outline)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer.split('/').last,
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.onSurfaceVariant.withOpacity(0.6)),
          ),
        ],
      );
    }

    // Default for non-image files (PDF, etc)
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              answer.split('/').last,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixAnswer(SurveyQuestionData q, String answer) {
    Map<String, dynamic> parsed = {};
    try {
      final decoded = jsonDecode(answer);
      if (decoded is Map) {
        parsed = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (q.matrixRows.isEmpty || q.matrixColumns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(answer, style: const TextStyle(fontSize: 11)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: AppTheme.surfaceContainerLow,
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Pernyataan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ...q.matrixColumns.map((col) => Expanded(
                  flex: 1,
                  child: Center(child: Text(col.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
                )),
              ],
            ),
          ),
          ...q.matrixRows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final rowAnswer = parsed[idx.toString()] ?? parsed['row-$idx'];
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: idx.isEven ? Colors.white : AppTheme.surfaceContainerLow.withOpacity(0.3),
                border: Border(top: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(row.label, style: const TextStyle(fontSize: 11))),
                  ...q.matrixColumns.asMap().entries.map((colEntry) {
                    final colIdx = colEntry.key;
                    bool isSelected = false;
                    
                    if (q.matrixType == 'radio') {
                      isSelected = rowAnswer?.toString() == colIdx.toString();
                    } else if (rowAnswer is List) {
                      isSelected = rowAnswer.contains(colIdx) || rowAnswer.contains(colIdx.toString());
                    }

                    return Expanded(
                      flex: 1,
                      child: Center(
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                          size: 16,
                          color: isSelected ? AppTheme.primary : AppTheme.outlineVariant.withOpacity(0.3),
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
  }

  // Helper methods
  String _getModerationStatus(Map<String, dynamic> r) {
    final dynamic s = r['supervision_status'] ?? r['moderation_status'] ?? r['status_review'] ?? r['status'];
    if (s == null) return 'PENDING';
    final str = s.toString().toLowerCase();
    if (str == 'approve' || str == 'approved') return 'APPROVE';
    if (str == 'revision_needed' || str == 'revision') return 'REVISION';
    if (str == 'decline' || str == 'declined') return 'DECLINE';
    return 'PENDING';
  }

  void _calculateTimeline(SurveyResponseDetail detail) {
    final responses = detail.responses;
    final startRaw = responses?['started_at'] ?? responses?['created_at'];
    final finishRaw = responses?['finished_at'] ?? responses?['updated_at'];

    String formatTime(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      try {
        final dt = DateTime.parse(raw).toLocal();
        final m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        return '${dt.day} ${m[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) { return '-'; }
    }

    String calcDuration(String? start, String? finish) {
      if (start == null || finish == null) return '-';
      try {
        final s = DateTime.parse(start);
        final f = DateTime.parse(finish);
        final diff = f.difference(s);
        final h = diff.inHours;
        final m = diff.inMinutes.remainder(60);
        return h > 0 ? '${h}j ${m}m' : '${m}m';
      } catch (_) { return '-'; }
    }

    _timelineStart = formatTime(startRaw);
    _timelineFinish = formatTime(finishRaw);
    _timelineDuration = calcDuration(startRaw, finishRaw);
  }

  String _getWilayah(Map<String, dynamic>? location) {
    if (location == null) return '-';
    final city = location['city'];
    final region = location['region'];
    if (city != null && region != null) return '$city, $region';
    return city?.toString() ?? region?.toString() ?? 'Unknown';
  }

  Future<void> _openMaps(dynamic lat, dynamic lng) async {
    final url = 'https://www.google.com/maps?q=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Terjadi kesalahan"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }
}
