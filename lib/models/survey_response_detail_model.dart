import 'survey_model.dart';
import 'project_model.dart';
import 'client_model.dart';

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

/// Model utama untuk response dari endpoint:
/// GET /clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/edit-answer/{userId}
class SurveyResponseDetail {
  final SurveyModel? survey;
  final Project? project;
  final Client? client;
  final List<SurveyPageData> pages;
  final List<SurveyAnswerData> answers;
  final DateTime? editedAt;
  final int? responseId; // ← ID respons dari level top JSON

  SurveyResponseDetail({
    this.survey,
    this.project,
    this.client,
    required this.pages,
    required this.answers,
    this.editedAt,
    this.responseId,
  });

  factory SurveyResponseDetail.fromJson(Map<String, dynamic> json) {
    return SurveyResponseDetail(
      // Handle key singular & plural (surveys/survey, projects/project, clients/client)
      survey: json['surveys'] != null
          ? SurveyModel.fromJson(json['surveys'])
          : (json['survey'] != null
                ? SurveyModel.fromJson(json['survey'])
                : null),
      project: json['projects'] != null
          ? Project.fromJson(json['projects'])
          : (json['project'] != null
                ? Project.fromJson(json['project'])
                : null),
      client: json['clients'] != null
          ? Client.fromJson(json['clients'])
          : (json['client'] != null ? Client.fromJson(json['client']) : null),

      // Handle key 'page' atau 'pages'
      pages:
          (json['pages'] as List? ?? json['page'] as List?)
              ?.map((e) => SurveyPageData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      // Handle key 'answer' atau 'answers' (EnumEditAnswer return 'answer')
      answers:
          (json['answer'] as List? ?? json['answers'] as List?)
              ?.map((e) => SurveyAnswerData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],

      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'].toString())
          : null,
      responseId: _toInt(json['response_id'] ??
          json['id'] ??
          json['responseId'] ??
          json['id_response'] ??
          json['responses']?['id'] ??
          json['response']?['id']),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE
// ---------------------------------------------------------------------------

class SurveyPageData {
  final int id;
  final String pageName;
  final int order;
  final int surveyId;
  final List<SurveyQuestionData> questions;

  SurveyPageData({
    required this.id,
    required this.pageName,
    required this.order,
    required this.surveyId,
    required this.questions,
  });

  factory SurveyPageData.fromJson(Map<String, dynamic> json) {
    return SurveyPageData(
      id: json['id'] ?? 0,
      pageName: json['page_name'] ?? '',
      order: json['order'] ?? 0,
      surveyId: json['survey_id'] ?? 0,
      // Handle key 'question' atau 'questions'
      questions:
          (json['questions'] as List? ?? json['question'] as List?)
              ?.map(
                (e) => SurveyQuestionData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// QUESTION
// ---------------------------------------------------------------------------

class SurveyQuestionData {
  final int id;
  final String questionText;
  final int questionTypeId;
  final int order;
  final int required;
  final List<QuestionChoiceData> choices;

  // Field tambahan dari EnumEditAnswer
  final int? questionChoiceId;
  final int? questionLogicTypeId;
  final String? choiceType;
  final String? value;

  // Matrix fields (question_type_id == 9)
  final List<MatrixRowData> matrixRows;
  final List<MatrixColumnData> matrixColumns;
  final String matrixType; // 'radio' atau 'checkbox'

  SurveyQuestionData({
    required this.id,
    required this.questionText,
    required this.questionTypeId,
    required this.order,
    required this.required,
    required this.choices,
    this.questionChoiceId,
    this.questionLogicTypeId,
    this.choiceType,
    this.value,
    this.matrixRows = const [],
    this.matrixColumns = const [],
    this.matrixType = 'radio',
  });

  factory SurveyQuestionData.fromJson(Map<String, dynamic> json) {
    // Parse matrix_rows — bisa berupa List atau null
    List<MatrixRowData> parsedRows = [];
    final rawRows = json['matrix_rows'];
    if (rawRows is List) {
      parsedRows = rawRows
          .map((e) => MatrixRowData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse matrix_columns — bisa berupa List atau null
    List<MatrixColumnData> parsedCols = [];
    final rawCols = json['matrix_columns'];
    if (rawCols is List) {
      parsedCols = rawCols
          .map((e) => MatrixColumnData.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SurveyQuestionData(
      id: json['id'] ?? 0,
      questionText: json['question_text'] ?? '',
      questionTypeId: json['question_type_id'] ?? 1,
      order: json['order'] ?? 0,
      required: json['required'] ?? 0,

      // Handle key 'choice' atau 'choices'
      choices:
          (json['choices'] as List? ?? json['choice'] as List?)
              ?.map(
                (e) => QuestionChoiceData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],

      questionChoiceId: json['question_choice_id'],
      questionLogicTypeId: json['question_logic_type_id'] ?? json['logic_type'],
      choiceType: json['choice_type'],
      value: json['value']?.toString(),
      matrixRows: parsedRows,
      matrixColumns: parsedCols,
      matrixType: json['matrix_type'] ?? 'radio',
    );
  }

  /// Apakah pertanyaan ini tipe matrix
  bool get isMatrix => questionTypeId == 9;

  /// Mapping question_type_id ke string UI
  String get typeString {
    switch (questionTypeId) {
      case 1:
        return 'text';
      case 2:
        return 'radio';
      case 3:
        return 'checkbox';
      case 6:
        return 'number';
      case 7:
        return 'dropdown';
      case 8:
        return 'paragraph';
      case 9:
        return 'matrix';
      case 10:
        return 'document';
      default:
        return 'text';
    }
  }

  /// Bersihkan tag HTML dari question_text
  String get plainText {
    return questionText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
  }
}

// ---------------------------------------------------------------------------
// MATRIX
// ---------------------------------------------------------------------------

class MatrixRowData {
  final String label;

  MatrixRowData({required this.label});

  factory MatrixRowData.fromJson(Map<String, dynamic> json) {
    return MatrixRowData(label: json['label']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'label': label};
}

class MatrixColumnData {
  final String label;

  MatrixColumnData({required this.label});

  factory MatrixColumnData.fromJson(Map<String, dynamic> json) {
    return MatrixColumnData(label: json['label']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'label': label};
}

// ---------------------------------------------------------------------------
// CHOICE
// ---------------------------------------------------------------------------

class QuestionChoiceData {
  final int id;
  final int questionId;
  final String value;
  final int order;
  final int? scale;

  QuestionChoiceData({
    required this.id,
    required this.questionId,
    required this.value,
    required this.order,
    this.scale,
  });

  factory QuestionChoiceData.fromJson(Map<String, dynamic> json) {
    return QuestionChoiceData(
      id: json['id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      value: json['value'] ?? '',
      order: json['order'] ?? 0,
      scale: json['scale'],
    );
  }
}

// ---------------------------------------------------------------------------
// ANSWER
// ---------------------------------------------------------------------------

class SurveyAnswerData {
  final int id;
  final int responseId;
  final int questionId;
  final String answer;

  SurveyAnswerData({
    required this.id,
    required this.responseId,
    required this.questionId,
    required this.answer,
  });

  factory SurveyAnswerData.fromJson(Map<String, dynamic> json) {
    return SurveyAnswerData(
      id: _toInt(json['id']) ?? 0,
      responseId: _toInt(json['response_id'] ??
              json['responseId'] ??
              json['id_response'] ??
              json['res_id']) ??
          0,
      questionId: _toInt(json['question_id'] ?? json['questionId']) ?? 0,
      answer: json['answer']?.toString() ?? '',
    );
  }

  /// Decode answer JSON untuk tipe matrix/checkbox
  dynamic get parsedAnswer {
    try {
      // Jika answer berupa JSON string (matrix/checkbox menyimpan sebagai JSON)
      if (answer.startsWith('[') || answer.startsWith('{')) {
        // ignore: avoid_dynamic_calls
        return _decodeJson(answer);
      }
    } catch (_) {}
    return answer;
  }

  dynamic _decodeJson(String raw) {
    // Simple JSON decode tanpa dart:convert untuk menghindari import circular
    // Gunakan dart:convert di layer service
    return raw;
  }
}
