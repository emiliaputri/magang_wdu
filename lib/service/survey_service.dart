import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../models/survey_model.dart';
import '../models/survey_response_detail_model.dart';

class SurveyService {
  final _api = ApiClient();

  // ── AMBIL LIST SURVEY ─────────────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys
  Future<List<SurveyModel>> getSurveys(
    String clientSlug,
    String projectSlug,
  ) async {
    final response = await _api.get(Endpoints.surveys(clientSlug, projectSlug));

    final List raw = response.data?['data'] ?? [];
    return raw.map((e) => SurveyModel.fromJson(e)).toList();
  }

  // ── AMBIL DETAIL SURVEY / LOCATION ───────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/detail
  Future<Map<String, dynamic>> getSurveyDetail(
    String clientSlug,
    String projectSlug,
    String surveySlug,
  ) async {
    final response = await _api.get(
      Endpoints.surveyDetail(clientSlug, projectSlug, surveySlug),
    );

    return response.data ?? {};
  }

  // ── AMBIL SEMUA REPORT SURVEY ─────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/all-report
  Future<Map<String, dynamic>> getSurveyAllReport(
    String clientSlug,
    String projectSlug,
    String surveySlug,
  ) async {
    final response = await _api.get(
      Endpoints.surveyAllReport(clientSlug, projectSlug, surveySlug),
    );

    return response.data ?? {};
  }

  // ── AMBIL JAWABAN INDIVIDU ────────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/report/{responseId}
  Future<Map<String, dynamic>> getSurveyResponse(
    String clientSlug,
    String projectSlug,
    String surveySlug,
    int responseId,
  ) async {
    final response = await _api.get(
      Endpoints.surveyReport(clientSlug, projectSlug, surveySlug, responseId),
      queryParams: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
    );

    return response.data ?? {};
  }

  Future<SurveyResponseDetail?> getSurveyResponseDetail(
    String clientSlug,
    String projectSlug,
    String surveySlug,
    int responseId,
  ) async {
    final response = await _api.get(
      Endpoints.surveyReport(clientSlug, projectSlug, surveySlug, responseId),
      queryParams: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
    );

    if (response.data != null) {
      return SurveyResponseDetail.fromJson(response.data!);
    }
    return null;
  }

  // ── GABUNGKAN REPORT + ALL-REPORT ────────────────────────────
  // GET /report/{responseId} + GET /all-report
  // Untuk dapat: respondent info, location, status + pertanyaan lengkap
  Future<SurveyResponseDetail?> getFullSurveyDetail({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required int responseId,
  }) async {
    try {
      final cacheBuster = {
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final results = await Future.wait([
        _api.get(
          Endpoints.surveyReport(
            clientSlug,
            projectSlug,
            surveySlug,
            responseId,
          ),
          queryParams: cacheBuster,
        ),
        _api.get(
          Endpoints.surveyAllReport(clientSlug, projectSlug, surveySlug),
        ),
      ]);

      final reportData = results[0].data;
      final allReportData = results[1].data;

      if (reportData == null && allReportData == null) return null;

      final Map<String, dynamic> combined = {};

      if (reportData != null) {
        combined.addAll(reportData);
        // Ensure pages don't block from all-report
        if (combined['pages'] is List && (combined['pages'] as List).isEmpty) {
          combined.remove('pages');
        }
        if (combined['page'] is List && (combined['page'] as List).isEmpty) {
          combined.remove('page');
        }
      }

      if (allReportData != null) {
        final actualData = allReportData['data'] ?? allReportData;
        if (actualData is Map<String, dynamic>) {
          if (actualData.containsKey('page')) {
            combined['detail_pages'] = actualData['page'];
          } else if (actualData.containsKey('pages')) {
            combined['detail_pages'] = actualData['pages'];
          } else if (actualData.containsKey('surveys')) {
            final sData = actualData['surveys'];
            if (sData is Map) {
              combined['detail_pages'] =
                  sData['page'] ?? sData['pages'] ?? sData['questions'];
            }
          }
        }
      }

      return SurveyResponseDetail.fromJson(combined);
    } catch (e, st) {
      debugPrint('Error getFullSurveyDetail: $e');
      debugPrint('Stack: $st');
      // Debug: print raw response
      try {
        final rawReport = await _api.get(
          Endpoints.surveyReport(
            clientSlug,
            projectSlug,
            surveySlug,
            responseId,
          ),
        );
        debugPrint('Raw report response: ${rawReport.data}');
      } catch (_) {}
      return null;
    }
  }

  // ── EDIT JAWABAN INDIVIDU ─────────────────────────────────
  // POST /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/change-answer/{responseId}
  Future<bool> changeAnswer({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required String responseId,
    required int questionId,
    required dynamic answerValue,
  }) async {
    try {
      await _api.post(
        Endpoints.changeAnswer(
          clientSlug,
          projectSlug,
          surveySlug,
          int.parse(responseId),
        ),
        body: {'question_id': questionId, 'answer': answerValue},
      );

      // assuming success if status code is 200/201
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── HAPUS RESPONSE ─────────────────────────────────────────
  // DELETE /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/responses/{responseId}
  Future<bool> deleteResponse(
    String clientSlug,
    String projectSlug,
    String surveySlug,
    int responseId,
  ) async {
    try {
      await _api.delete(
        Endpoints.deleteResponse(
          clientSlug,
          projectSlug,
          surveySlug,
          responseId,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error delete response: $e');
      return false;
    }
  }
}
