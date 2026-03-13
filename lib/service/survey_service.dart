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
    );

    if (response.data != null) {
      debugPrint("survey_report keys: ${response.data!.keys.toList()}");
      return SurveyResponseDetail.fromJson(response.data!);
    }
    return null;
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
}
