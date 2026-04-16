import 'project_model.dart';
import '../core/constants/endpoints.dart';

class Client {
  final int? id;
  final String clientName;
  final String? image;
  final String? imageUrl;
  final String? alamat;
  final String? phone;
  final String? slug;
  final String? desc;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Project>? projects;

  Client({
    this.id,
    required this.clientName,
    this.image,
    this.imageUrl,
    this.alamat,
    this.phone,
    this.slug,
    this.desc,
    this.createdAt,
    this.updatedAt,
    this.projects,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    // Mencoba berbagai kemungkinan key untuk gambar klien
    String? rawImage = json['image'] ?? 
                       json['image_url'] ?? 
                       json['client_image'] ?? 
                       json['client_logo'] ?? 
                       json['logo'];

    return Client(
      id: json['id'],
      clientName: json['client_name'] ?? '',
      image: _buildImageUrl(rawImage),
      imageUrl: _buildImageUrl(rawImage),
      alamat: json['alamat'],
      phone: json['phone'],
      slug: json['slug'],
      desc: json['desc'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      projects: (json['projects'] as List?)
          ?.map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'image': image,
      'image_url': imageUrl,
      'alamat': alamat,
      'phone': phone,
      'slug': slug,
      'desc': desc,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'projects': projects?.map((e) => e.toJson()).toList(),
    };
  }

  Client copyWith({
    int? id,
    String? clientName,
    String? image,
    String? imageUrl,
    String? alamat,
    String? phone,
    String? slug,
    String? desc,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Project>? projects,
  }) {
    return Client(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      alamat: alamat ?? this.alamat,
      phone: phone ?? this.phone,
      slug: slug ?? this.slug,
      desc: desc ?? this.desc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projects: projects ?? this.projects,
    );
  }

  static String? _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    final base = Endpoints.storageUrl;
    
    // Jika url mengandung 'img/client/', kita pastikan tidak ada double slash saat tempel ke base
    if (url.contains('img/client/')) {
       // Bersihkan url dari leading slash jika ada, agar kita bisa kontrol manual
       final cleanPath = url.startsWith('/') ? url.substring(1) : url;
       return '$base/$cleanPath';
    }

    // Paksa tambahkan /img/client/ jika belum ada
    // Dan bersihkan input url dari leading slash agar tidak merusak struktur
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$base/img/client/$cleanUrl';
  }

  @override
  String toString() => 'Client(id: $id, clientName: $clientName, slug: $slug)';
}
