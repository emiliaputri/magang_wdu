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
  int totalRespon       = 0;
  int targetRespon      = 0;
  String targetLocation = '-';
  bool isOpen           = false;

  List<Map<String, dynamic>> responses = [];
  List<Map<String, dynamic>> pages     = [];

  Map<String, dynamic>? executiveSummary;
  Map<String, dynamic>  questionSummaries = {};

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
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Panggil kedua endpoint secara paralel
      final results = await Future.wait([
        _service.getSurveyDetail(clientSlug, projectSlug, surveySlug),
        _service.getSurveyAllReport(clientSlug, projectSlug, surveySlug),
      ]);

      final detail    = results[0]; // /detail
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
        targetRespon  = surveyData['target_response'] ?? 0;

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
      final rawResponses = allReport['responses'];
      if (rawResponses is List && rawResponses.isNotEmpty) {
        debugPrint('SAMPLE RESPONSE FULL: ${rawResponses.first}');
        debugPrint('SAMPLE RESPONSE KEYS: ${rawResponses.first.keys.toList()}');
        responses = rawResponses
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        totalRespon = responses.length;
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

      debugPrint('MonitoringProvider loaded: '
          'survey="$_resolvedName", '
          'responses=${responses.length}, '
          'targetRespon=$targetRespon, '
          'isOpen=$isOpen');
    } catch (e, st) {
      debugPrint('MonitoringProvider.loadSurvey ERROR: $e');
      debugPrint('$st');
      errorMessage = 'Gagal memuat data. Coba lagi.';
    }

    isLoading = false;
    notifyListeners();
  }
}