import '../core/constants/endpoints.dart';

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
    // Mencoba berbagai kemungkinan key untuk gambar klien (termasuk dari join table)
    String? rawImage = json['image'] ?? 
                       json['image_url'] ?? 
                       json['client_image'] ?? 
                       json['client_logo'] ?? 
                       json['logo'];

    // Jika masih null, coba cek di dalam objek 'client' jika ada (nested relationship)
    if (rawImage == null && json['client'] != null && json['client'] is Map) {
      final clientJson = json['client'] as Map<String, dynamic>;
      rawImage = clientJson['image'] ?? clientJson['image_url'];
    }

    return UserProject(
      id:          json['id'],
      projectName: json['project_name'] ?? '',
      slug:        json['slug'] ?? '',
      desc:        json['desc'],
      clientName:  json['client_name'] ?? '',
      clientSlug:  json['client_slug'] ?? '',
      surveyCount: json['survey_count'] ?? 0,
      updatedAt:   json['updated_at'],
      clientImage: _buildImageUrl(rawImage), // ✅ Gunakan helper untuk prefix URL
    );
  }

  UserProject copyWith({
    int? id,
    String? projectName,
    String? slug,
    String? desc,
    String? clientName,
    String? clientSlug,
    int? surveyCount,
    String? updatedAt,
    String? clientImage,
  }) {
    return UserProject(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      slug: slug ?? this.slug,
      desc: desc ?? this.desc,
      clientName: clientName ?? this.clientName,
      clientSlug: clientSlug ?? this.clientSlug,
      surveyCount: surveyCount ?? this.surveyCount,
      updatedAt: updatedAt ?? this.updatedAt,
      clientImage: clientImage ?? this.clientImage,
    );
  }

  static String? _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final base = Endpoints.storageUrl;
    
    // Jika url mengandung 'img/client/', kita pastikan tidak ada double slash saat tempel ke base
    if (url.contains('img/client/')) {
       final cleanPath = url.startsWith('/') ? url.substring(1) : url;
       return '$base/$cleanPath';
    }

    // Paksa tambahkan /img/client/ jika belum ada
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$base/img/client/$cleanUrl';
  }
}