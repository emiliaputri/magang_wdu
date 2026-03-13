class Endpoints {
  // ── BASE URL ──────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

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
          String clientSlug, String projectSlug, String slug) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/detail';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/all-report
  static String surveyAllReport(
          String clientSlug, String projectSlug, String slug) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/all-report';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/report/{responseId}
  static String surveyReport(
          String clientSlug, String projectSlug, String slug, int responseId) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/report/$responseId';

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{Survey:slug}/edit-answer/{userId}
  static String editAnswer(
          String clientSlug, String projectSlug, String slug, int userId) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/edit-answer/$userId';

  // PATCH /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{Survey:slug}/change-answer/{responseId}
  static String changeAnswer(
          String clientSlug, String projectSlug, String slug, int responseId) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/change-answer/$responseId';
}