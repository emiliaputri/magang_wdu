class Endpoints {
  // ── BASE URL ──────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sis.wahanadata.co.id/api',
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

  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{Survey:slug}/report/{responseId}
  static String surveyReport(
          String clientSlug, String projectSlug, String slug, int responseId) =>
      '/clients/$clientSlug/projects/$projectSlug/surveys/$slug/report/$responseId';
}