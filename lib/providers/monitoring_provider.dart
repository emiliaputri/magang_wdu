import 'dart:convert';
import 'package:flutter/material.dart';
import '../../service/survey_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final String surveyName;
  final String clientSlug;
  final String projectSlug;
  final String surveySlug;

  MonitoringProvider({
    required this.surveyName,
    required this.clientSlug,
    required this.projectSlug,
    required this.surveySlug,
  });

  final SurveyService _service = SurveyService();

  // ── STATE ─────────────────────────────────────────────────
  bool isLoading = false;
  String? errorMessage;

  String _resolvedName = '';
  int totalRespon = 0;
  int targetRespon = 0;
  String targetLocation = '-';
  bool isOpen = false;
  bool isNewestFirst = true;

  String dateFilter =
      'all'; // 'all', 'last_week', 'last_month', 'last_year', 'custom'
  DateTimeRange? customDateRange;
  List<Map<String, dynamic>> _rawResponses = [];

  void toggleSortOrder(bool newestFirst) {
    if (isNewestFirst == newestFirst) return;
    isNewestFirst = newestFirst;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setDateFilter(String filter, {DateTimeRange? customRange}) {
    dateFilter = filter;
    if (filter == 'custom' && customRange != null) {
      customDateRange = customRange;
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    if (dateFilter == 'last_week') {
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
      endDate = now;
    } else if (dateFilter == 'last_month') {
      // Aman: DateTime constructor auto-adjust overflow (e.g. month 0 → Dec tahun sebelumnya)
      final targetMonth = now.month - 1;
      startDate = DateTime(now.year, targetMonth, now.day);
      endDate = now;
    } else if (dateFilter == 'last_year') {
      startDate = DateTime(now.year - 1, now.month, now.day);
      endDate = now;
    } else if (dateFilter == 'custom' && customDateRange != null) {
      // Strip waktu supaya inklusif: start dari jam 00:00, end sampai 23:59:59
      startDate = DateTime(
        customDateRange!.start.year,
        customDateRange!.start.month,
        customDateRange!.start.day,
      );
      endDate = DateTime(
        customDateRange!.end.year,
        customDateRange!.end.month,
        customDateRange!.end.day,
        23, 59, 59,
      );
    }

    // DEBUG: Print filter info
    debugPrint(
      '[MonitoringProvider] Filter: $dateFilter, startDate: $startDate, endDate: $endDate',
    );
    debugPrint(
      '[MonitoringProvider] Total raw responses: ${_rawResponses.length}',
    );

    responses = _rawResponses.where((r) {
      if (startDate == null || endDate == null) return true;
      final dateStr =
          r['created_at']?.toString() ?? r['updated_at']?.toString() ?? '';
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return false;
      // Gunakan >= dan <= (inklusif kedua sisi)
      return !dt.isBefore(startDate) && !dt.isAfter(endDate);
    }).toList();

    debugPrint(
      '[MonitoringProvider] Setelah filter: ${responses.length} responses',
    );
    for (var i = 0; i < responses.length && i < 3; i++) {
      debugPrint(
        '  Response[$i]: ${responses[i]['created_at'] ?? responses[i]['updated_at']}',
      );
    }

    responses.sort((a, b) {
      final dateA =
          DateTime.tryParse(
            a['created_at']?.toString() ?? a['updated_at']?.toString() ?? '',
          ) ??
          DateTime(1970);
      final dateB =
          DateTime.tryParse(
            b['created_at']?.toString() ?? b['updated_at']?.toString() ?? '',
          ) ??
          DateTime(1970);

      final cmp = isNewestFirst
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
      if (cmp != 0) return cmp;

      final idA =
          int.tryParse(
            a['id']?.toString() ?? a['response_id']?.toString() ?? '0',
          ) ??
          0;
      final idB =
          int.tryParse(
            b['id']?.toString() ?? b['response_id']?.toString() ?? '0',
          ) ??
          0;
      return isNewestFirst ? idB.compareTo(idA) : idA.compareTo(idB);
    });

    totalRespon = responses.length;
  }

  List<Map<String, dynamic>> responses = [];
  List<Map<String, dynamic>> pages = [];

  Map<String, dynamic>? executiveSummary;
  Map<String, dynamic> questionSummaries = {};

  // ── GETTERS ───────────────────────────────────────────────
  String get resolvedName =>
      _resolvedName.isNotEmpty ? _resolvedName : surveyName;

  double get progressValue {
    if (targetRespon <= 0) return 0;
    return (totalRespon / targetRespon).clamp(0.0, 1.0);
  }

  String get progressLabel {
    if (targetRespon <= 0) return '$totalRespon respon';
    return '${(progressValue * 100).toStringAsFixed(1)}%';
  }

  String get progressSub {
    if (targetRespon <= 0) return 'Target belum diset';
    return 'Target: $targetRespon respon';
  }

  // ── LOAD ──────────────────────────────────────────────────
  Future<void> loadSurvey() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Panggil kedua endpoint secara paralel
      final results = await Future.wait([
        _service.getSurveyDetail(clientSlug, projectSlug, surveySlug),
        _service.getSurveyAllReport(clientSlug, projectSlug, surveySlug),
      ]);

      final detail = results[0]; // /detail
      final allReport = results[1]; // /all-report

      debugPrint('detail keys:    ${detail.keys.toList()}');
      debugPrint('allReport keys: ${allReport.keys.toList()}');

      // ── surveys dari /detail → Array, cari by slug ────────
      final rawSurveys = detail['surveys'];
      Map<String, dynamic>? surveyData;

      if (rawSurveys is List) {
        final matches = rawSurveys
            .whereType<Map>()
            .where((s) => s['slug'] == surveySlug)
            .toList();
        if (matches.isNotEmpty) {
          surveyData = Map<String, dynamic>.from(matches.first);
        } else if (rawSurveys.isNotEmpty) {
          surveyData = Map<String, dynamic>.from(rawSurveys.first as Map);
        }
      } else if (rawSurveys is Map) {
        surveyData = Map<String, dynamic>.from(rawSurveys);
      }

      // ── surveys dari /all-report → Object langsung ────────
      // all-report punya data lebih lengkap, override jika ada
      final rawSurveyReport = allReport['surveys'];
      if (rawSurveyReport is Map) {
        surveyData = Map<String, dynamic>.from(rawSurveyReport);
      }

      // ── parse survey data ─────────────────────────────────
      if (surveyData != null) {
        _resolvedName = surveyData['title'] ?? surveyName;
        targetRespon = surveyData['target_response'] ?? 0;

        final status = surveyData['status'];
        isOpen = status == 1 || status == '1' || status == 'DIBUKA';

        // province_targets: List langsung atau String JSON
        final rawTargets = surveyData['province_targets'];
        List<dynamic> targetsList = [];

        if (rawTargets is List) {
          targetsList = rawTargets;
        } else if (rawTargets is String &&
            rawTargets.isNotEmpty &&
            rawTargets != '[]') {
          try {
            final decoded = jsonDecode(rawTargets);
            if (decoded is List) targetsList = decoded;
          } catch (_) {}
        }

        if (targetsList.isNotEmpty) {
          targetLocation = targetsList
              .whereType<Map>()
              .map((e) => e['province_name']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (targetLocation.isEmpty) targetLocation = '-';
        } else {
          targetLocation = '-';
        }
      }

      // ── responses dari /all-report ─────────────────────────
      final rawResponsesList = allReport['responses'];
      if (rawResponsesList is List && rawResponsesList.isNotEmpty) {
        debugPrint('SAMPLE RESPONSE FULL: ${rawResponsesList.first}');
        debugPrint(
          'SAMPLE RESPONSE KEYS: ${rawResponsesList.first.keys.toList()}',
        );
        _rawResponses = rawResponsesList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _applyFiltersAndSort();

        if (responses.isNotEmpty) {
          debugPrint('DEBUG: Response keys: ${responses.first.keys.toList()}');
          debugPrint('DEBUG: Full first response: ${responses.first}');
        }
      }

      // ── pages dari /all-report ────────────────────────────
      final rawPages = allReport['page'];
      if (rawPages is List) {
        pages = rawPages
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // ── executive summary dari /all-report ────────────────
      final rawExec = allReport['existingExecutiveSummary'];
      if (rawExec is Map) {
        executiveSummary = Map<String, dynamic>.from(rawExec);
      } else {
        executiveSummary = null;
      }

      // ── question summaries dari /all-report ───────────────
      final rawQS = allReport['questionSummaries'];
      if (rawQS is Map) {
        questionSummaries = Map<String, dynamic>.from(rawQS);
      } else {
        questionSummaries = {};
      }

      debugPrint(
        'MonitoringProvider loaded: '
        'survey="$_resolvedName", '
        'responses=${responses.length}, '
        'targetRespon=$targetRespon, '
        'isOpen=$isOpen',
      );
    } catch (e, st) {
      debugPrint('MonitoringProvider.loadSurvey ERROR: $e');
      debugPrint('$st');
      errorMessage = 'Gagal memuat data. Coba lagi.';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── DELETE RESPONSE ─────────────────────────────────────────
  Future<bool> deleteResponse(int responseId) async {
    try {
      final success = await _service.deleteResponse(
        clientSlug,
        projectSlug,
        surveySlug,
        responseId,
      );

      if (success) {
        // Hapus dari data mentah juga
        _rawResponses.removeWhere(
          (r) => r['id'] == responseId || r['response_id'] == responseId,
        );
        responses.removeWhere(
          (r) => r['id'] == responseId || r['response_id'] == responseId,
        );
        totalRespon = responses.length;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error delete response: $e');
      return false;
    }
  }
}
