import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../models/submission_model.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class SubmissionService {
  final _api = ApiClient();

  Future<SurveySubmissionData?> getSubmission({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.surveySubmission(clientSlug, projectSlug, surveySlug),
      );

      print(
        "DEBUG getSubmission: response.data keys: ${response.data?.keys.toList()}",
      );
      print(
        "DEBUG getSubmission: survey key exists: ${response.data?.containsKey('survey')}",
      );

      if (response.data != null) {
        final result = SurveySubmissionData.fromJson(response.data!);
        print(
          "DEBUG: provinceTargets count in service: ${result.provinceTargets.length}",
        );
        return result;
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e, st) {
      print("getSubmission ERROR: $e\n$st");
      throw Exception("Gagal mengambil data submission: $e");
    }
  }

  Future<bool> submitSurvey({
    required String clientSlug,
    required String projectSlug,
    required int surveyId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      debugPrint('🚀 [SUBMIT] Starting submission for surveyId: $surveyId');

      // Wrap payload dalam field "data" sesuai format backend
      final wrappedPayload = {'data': jsonEncode(answers)};

      // ── DEBUG LOGGING ──
      const encoder = JsonEncoder.withIndent('  ');
      final prettyPayload = encoder.convert(answers);
      debugPrint('📦 [SUBMIT] PAYLOAD TO SEND:\n$prettyPayload');
      debugPrint('🔗 [SUBMIT] ENDPOINT: ${Endpoints.submitAnswer(clientSlug, projectSlug, surveyId)}');

      final response = await _api.post(
        Endpoints.submitAnswer(clientSlug, projectSlug, surveyId),
        body: wrappedPayload,
      );

      if (response.success) {
        debugPrint('✅ [SUBMIT] SUCCESS: ${response.message}');
        return true;
      }
      return false;
    } catch (e, st) {
      debugPrint('🚨 [SUBMIT] FATAL ERROR: $e');
      debugPrint('StackTrace: $st');
      return false;
    }
  }
}

class SurveySubmissionData {
  final SurveyInfo? survey;
  final ProjectInfo? project;
  final ClientInfo? client;
  final List<SurveyPageData> pages;
  final List<ProvinceTarget> provinceTargets;

  SurveySubmissionData({
    this.survey,
    this.project,
    this.client,
    this.pages = const [],
    this.provinceTargets = const [],
  });

  factory SurveySubmissionData.fromJson(Map<String, dynamic> json) {
    List<SurveyPageData> pages = [];
    if (json.containsKey('pages') && json['pages'] is List) {
      pages = (json['pages'] as List)
          .map((e) => SurveyPageData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<ProvinceTarget> provinceTargets = [];
    if (json.containsKey('survey') && json['survey'] is Map) {
      final survey = json['survey'] as Map<String, dynamic>;
      debugPrint(
        'DEBUG: Survey has province_targets key: ${survey.containsKey('province_targets')}',
      );
      debugPrint(
        'DEBUG: province_targets value: ${survey['province_targets']}',
      );

      if (survey.containsKey('province_targets')) {
        try {
          final targetsRaw = survey['province_targets'];
          if (targetsRaw == null) {
            debugPrint('DEBUG: province_targets is NULL');
          } else if (targetsRaw is String && targetsRaw.isNotEmpty) {
            debugPrint(
              'DEBUG: province_targets is String with length: ${targetsRaw.length}',
            );
            final decoded = jsonDecode(targetsRaw) as List;
            debugPrint('DEBUG: decoded list length: ${decoded.length}');
            provinceTargets = decoded
                .map((e) => ProvinceTarget.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (targetsRaw is List) {
            debugPrint('DEBUG: province_targets is List, processing...');
            provinceTargets = targetsRaw
                .map((e) => ProvinceTarget.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            debugPrint(
              'DEBUG: province_targets type: ${targetsRaw.runtimeType}',
            );
          }
        } catch (e) {
          print("Error parsing province_targets: $e");
        }
      }
    } else {
      debugPrint('DEBUG: survey key not found or not a Map');
    }

    debugPrint('DEBUG: Final provinceTargets count: ${provinceTargets.length}');
    return SurveySubmissionData(
      survey: json.containsKey('survey') && json['survey'] != null
          ? SurveyInfo.fromJson(json['survey'] as Map<String, dynamic>)
          : null,
      project: json.containsKey('project') && json['project'] != null
          ? ProjectInfo.fromJson(json['project'] as Map<String, dynamic>)
          : null,
      client: json.containsKey('client') && json['client'] != null
          ? ClientInfo.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      pages: pages,
      provinceTargets: provinceTargets,
    );
  }
}

class SurveyInfo {
  final int id;
  final String title;
  final String? desc;
  final String slug;
  final int projectId;
  final bool status;
  final String? spreadsheetUrl;

  SurveyInfo({
    required this.id,
    required this.title,
    this.desc,
    required this.slug,
    required this.projectId,
    required this.status,
    this.spreadsheetUrl,
  });

  factory SurveyInfo.fromJson(Map<String, dynamic> json) {
    return SurveyInfo(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      desc: json['desc'],
      slug: json['slug'] ?? '',
      projectId: _parseInt(json['project_id']),
      status: json['status'] ?? false,
      spreadsheetUrl: json['spreadsheet_url'],
    );
  }
}

class ProjectInfo {
  final int id;
  final String projectName;
  final String slug;
  final int clientId;

  ProjectInfo({
    required this.id,
    required this.projectName,
    required this.slug,
    required this.clientId,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      id: _parseInt(json['id']),
      projectName: json['project_name'] ?? '',
      slug: json['slug'] ?? '',
      clientId: _parseInt(json['client_id']),
    );
  }
}

class ClientInfo {
  final int id;
  final String clientName;
  final String? image;
  final String? alamat;
  final String? phone;
  final String slug;

  ClientInfo({
    required this.id,
    required this.clientName,
    this.image,
    this.alamat,
    this.phone,
    required this.slug,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: _parseInt(json['id']),
      clientName: json['client_name'] ?? '',
      image: json['image'],
      alamat: json['alamat'],
      phone: json['phone'],
      slug: json['slug'] ?? '',
    );
  }
}

class SurveyPageData {
  final int id;
  final String pageName;
  final int surveyId;
  final int order;
  final List<SurveyQuestionData> questions;

  SurveyPageData({
    required this.id,
    required this.pageName,
    required this.surveyId,
    required this.order,
    this.questions = const [],
  });

  factory SurveyPageData.fromJson(Map<String, dynamic> json) {
    List<SurveyQuestionData> questions = [];
    if (json.containsKey('question') && json['question'] is List) {
      questions = (json['question'] as List)
          .map((e) => SurveyQuestionData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SurveyPageData(
      id: _parseInt(json['id']),
      pageName: json['page_name'] ?? '',
      surveyId: _parseInt(json['survey_id']),
      order: _parseInt(json['order']),
      questions: questions,
    );
  }
}

class SurveyQuestionData {
  final int id;
  final String questionText;
  final int questionTypeId;
  final int surveyId;
  final int order;
  final bool required;
  final int? questionChoiceId;
  final String logicType;
  final String logicName;
  final List<QuestionChoice> choice;
  final List<MatrixRow> matrixRows;
  final List<MatrixColumn> matrixColumns;
  final String matrixType;

  SurveyQuestionData({
    required this.id,
    required this.questionText,
    required this.questionTypeId,
    required this.surveyId,
    required this.order,
    required this.required,
    this.questionChoiceId,
    required this.logicType,
    required this.logicName,
    this.choice = const [],
    this.matrixRows = const [],
    this.matrixColumns = const [],
    this.matrixType = 'radio',
  });

  factory SurveyQuestionData.fromJson(Map<String, dynamic> json) {
    List<QuestionChoice> choice = [];
    if (json.containsKey('choice') && json['choice'] is List) {
      choice = (json['choice'] as List)
          .map((e) => QuestionChoice.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<MatrixRow> matrixRows = [];
    if (json.containsKey('matrix_rows') && json['matrix_rows'] is List) {
      matrixRows = (json['matrix_rows'] as List)
          .map((e) => MatrixRow.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<MatrixColumn> matrixColumns = [];
    if (json.containsKey('matrix_columns') && json['matrix_columns'] is List) {
      matrixColumns = (json['matrix_columns'] as List)
          .map((e) => MatrixColumn.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SurveyQuestionData(
      id: _parseInt(json['id']),
      questionText: json['question_text'] ?? '',
      questionTypeId: _parseInt(json['question_type_id']),
      surveyId: _parseInt(json['survey_id']),
      order: _parseInt(json['order']),
      required: json['required'] ?? false,
      questionChoiceId: _parseIntNullable(json['question_choice_id']),
      logicType: json['logic_type'] ?? '1',
      logicName: json['logic_name'] ?? 'Always Display',
      choice: choice,
      matrixRows: matrixRows,
      matrixColumns: matrixColumns,
      matrixType: json['matrix_type'] ?? 'radio',
    );
  }

  String get plainText {
    final temp = questionText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
    return temp;
  }

  String get typeString {
    switch (questionTypeId) {
      case 1:
        return 'text';
      case 2:
        return 'radio';
      case 3:
        return 'checkbox';
      case 4:
        return 'number';
      case 5:
        return 'info';
      case 6:
        return 'rating';
      case 7:
        return 'dropdown';
      case 8:
        return 'paragraph';
      case 9:
        return 'matrix';
      default:
        return 'unknown';
    }
  }

  bool get isMatrix => questionTypeId == 9;
}

class QuestionChoice {
  final int id;
  final int questionId;
  final int order;
  final String value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuestionChoice({
    required this.id,
    required this.questionId,
    required this.order,
    required this.value,
    this.createdAt,
    this.updatedAt,
  });

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      id: _parseInt(json['id']),
      questionId: _parseInt(json['question_id']),
      order: _parseInt(json['order']),
      value: json['value'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}

class MatrixRow {
  final String label;

  MatrixRow({required this.label});

  factory MatrixRow.fromJson(Map<String, dynamic> json) {
    return MatrixRow(label: json['label'] ?? '');
  }
}

class MatrixColumn {
  final String label;

  MatrixColumn({required this.label});

  factory MatrixColumn.fromJson(Map<String, dynamic> json) {
    return MatrixColumn(label: json['label'] ?? '');
  }
}
