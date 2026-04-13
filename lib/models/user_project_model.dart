class UserProject {
  final int id;
  final String projectName;
  final String slug;
  final String? desc;
  final String clientName;
  final String clientSlug;
  final int surveyCount;
  final String? updatedAt;
  final String? clientImage;

  UserProject({
    required this.id,
    required this.projectName,
    required this.slug,
    this.desc,
    required this.clientName,
    required this.clientSlug,
    required this.surveyCount,
    this.updatedAt,
    this.clientImage,
  });

  factory UserProject.fromJson(Map<String, dynamic> json) {
    return UserProject(
      id:          json['id'],
      projectName: json['project_name'] ?? '',
      slug:        json['slug'] ?? '',
      desc:        json['desc'],
      clientName:  json['client_name'] ?? '',
      clientSlug:  json['client_slug'] ?? '',
      surveyCount: json['survey_count'] ?? 0,
      updatedAt:   json['updated_at'],
      clientImage: json['image'], // ✅ Ambil logo dari JSON
    );
  }
}