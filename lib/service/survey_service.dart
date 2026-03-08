import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../models/survey_model.dart';

class SurveyService {
  final _api = ApiClient();

  // ── AMBIL LIST SURVEY ─────────────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys
  Future<List<SurveyModel>> getSurveys(
    String clientSlug,
    String projectSlug,
  ) async {
    final response = await _api.get(
      Endpoints.surveys(clientSlug, projectSlug),
    );

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
}