class Endpoints {
  // ── BASE URL ──────────────────────────────────────────────
  // Digunakan untuk mendeteksi IP yang tepat (Emulator vs HP Fisik)
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Untuk HP Fisik: Gunakan IP Komputer (192.168.0.158)
    // Untuk Emulator: Gunakan 10.0.2.2
    return 'https://sis.wahanadata.co.id/api';
  }

  static String get storageUrl {
    // Menghapus '/api' dari baseUrl untuk mendapatkan domain utama
    // dan menambahkan '/storage' untuk akses file publik Laravel
    return baseUrl.replaceAll('/api', '') + '/storage';
  }

  // ── AUTH ──────────────────────────────────────────────────
  // POST /api/login
  static const String login = '/login';

  // GET  /api/user  ← bukan /auth/me
  static const String me = '/user';

  // ── CLIENT ────────────────────────────────────────────────
  // GET /api/clients
  static const String clients = '/clients';

  // ── SURVEY ────────────────────────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys
  static String surveys(String clientSlug, String projectSlug) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/detail
  static String surveyDetail(
    String clientSlug,
    String projectSlug,
    String slug,
  ) => '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/detail';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/all-report
  static String surveyAllReport(
    String clientSlug,
    String projectSlug,
    String slug,
  ) => '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/all-report';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/report/{responseId}
  static String surveyReport(
    String clientSlug,
    String projectSlug,
    String slug,
    int responseId,
  ) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/report/$responseId';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/responses/{responseId}
  static String surveyResponses(
    String clientSlug,
    String projectSlug,
    String slug,
    int responseId,
  ) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/responses/$responseId';

  // POST /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{surveyId}/submit
  static String editAnswer(
    String clientSlug,
    String projectSlug,
    String slug,
    int userId,
  ) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/edit-answer/$userId';

  // POST /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{surveyId}/submit
  static String submitAnswer(
    String clientSlug,
    String projectSlug,
    String slug,
  ) => '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/submit';

  // PATCH /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{Survey:slug}/change-answer/{responseId}
  static String changeAnswer(
    String clientSlug,
    String projectSlug,
    String slug,
    int responseId,
  ) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/change-answer/$responseId';

  // DELETE /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/responses/{responseId}
  static String deleteResponse(
    String clientSlug,
    String projectSlug,
    String slug,
    int responseId,
  ) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/responses/$responseId';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/submission
  static String surveySubmission(
    String clientSlug,
    String projectSlug,
    String slug,
  ) => '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/submission';
}
