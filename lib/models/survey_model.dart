import '../models/provinsi_model.dart';

class SurveyModel {
  final int? id;
  final String title;
  final String? desc;
  final String slug;
  final String? publicToken;
  final String status;
  final int? projectId;
  final int? cityId;
  final int? regencyId;
  final List<ProvinceTarget> provinceTargets;
  final String? spreadsheetUrl;
  final DateTime? spreadsheetUpdatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // computed dari API (bukan fillable, tapi sering di-append)
  final int responseCount;

  SurveyModel({
    this.id,
    required this.title,
    this.desc,
    required this.slug,
    this.publicToken,
    required this.status,
    this.projectId,
    this.cityId,
    this.regencyId,
    required this.provinceTargets,
    this.spreadsheetUrl,
    this.spreadsheetUpdatedAt,
    this.createdAt,
    this.updatedAt,
    this.responseCount = 0,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    final rawProvinces = json['province_targets'] as List? ?? [];
    final provinces =
        rawProvinces.map((e) => ProvinceTarget.fromJson(e)).toList();

    return SurveyModel(
      id: json['id'],
      title: json['title'] ?? '',
      desc: json['desc'],
      slug: json['slug'] ?? '',
      publicToken: json['public_token'],
      status: (json['status'] ?? '').toString().toUpperCase(),
      projectId: json['project_id'],
      cityId: json['city_id'],
      regencyId: json['regency_id'],
      provinceTargets: provinces,
      spreadsheetUrl: json['spreadsheet_url'],
      spreadsheetUpdatedAt: json['spreadsheet_updated_at'] != null
          ? DateTime.parse(json['spreadsheet_updated_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      responseCount: json['response_count'] ?? json['responses_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      'slug': slug,
      'public_token': publicToken,
      'status': status,
      'project_id': projectId,
      'city_id': cityId,
      'regency_id': regencyId,
      'province_targets': provinceTargets.map((e) => e.toJson()).toList(),
      'spreadsheet_url': spreadsheetUrl,
      'spreadsheet_updated_at': spreadsheetUpdatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // helper: target lokasi sebagai string
  String get targetLocation => provinceTargets.isNotEmpty
      ? provinceTargets.map((e) => e.name).join(', ')
      : '-';

  // helper: status open
  bool get isOpen =>
      status == 'DIBUKA' || status == 'OPEN' || status == '1';
}