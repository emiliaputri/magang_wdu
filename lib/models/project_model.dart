import 'client_model.dart';
import 'survey_model.dart';

class Project {
  final int? id;
  final String projectName;
  final int? clientId;
  final String? slug;
  final String? desc;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Client? client;
  final List<SurveyModel>? surveys;

  Project({
    this.id,
    required this.projectName,
    this.clientId,
    this.slug,
    this.desc,
    this.createdAt,
    this.updatedAt,
    this.client,
    this.surveys,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      projectName: json['project_name'] ?? '',
      clientId: json['client_id'],
      slug: json['slug'],
      desc: json['desc'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      client: json['client'] != null
          ? Client.fromJson(json['client'])
          : null,
      surveys: (json['survey'] as List?)
          ?.map((e) => SurveyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_name': projectName,
      'client_id': clientId,
      'slug': slug,
      'desc': desc,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'client': client?.toJson(),
      'survey': surveys?.map((e) => e.toJson()).toList(),
    };
  }

  Project copyWith({
    int? id,
    String? projectName,
    int? clientId,
    String? slug,
    String? desc,
    DateTime? createdAt,
    DateTime? updatedAt,
    Client? client,
    List<SurveyModel>? surveys,
  }) {
    return Project(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      clientId: clientId ?? this.clientId,
      slug: slug ?? this.slug,
      desc: desc ?? this.desc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      surveys: surveys ?? this.surveys,
    );
  }

  @override
  String toString() =>
      'Project(id: $id, projectName: $projectName, slug: $slug)';
}