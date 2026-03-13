import 'survey_model.dart';
import 'project_model.dart';
import 'client_model.dart';

class SurveyDetailResponse {
  final SurveyModel survey;
  final Project project;
  final Client client;
  final List<SurveyPage> pages;
  final List<SurveyAnswer> existingAnswers;

  SurveyDetailResponse({
    required this.survey,
    required this.project,
    required this.client,
    required this.pages,
    required this.existingAnswers,
  });

  factory SurveyDetailResponse.fromJson(Map<String, dynamic> json) {
    return SurveyDetailResponse(
      survey: SurveyModel.fromJson(json['surveys']),
      project: Project.fromJson(json['projects']),
      client: Client.fromJson(json['clients']),
      pages: (json['pages'] as List?)
              ?.map((e) => SurveyPage.fromJson(e))
              .toList() ??
          [],
      existingAnswers: (json['answer'] as List?)
              ?.map((e) => SurveyAnswer.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SurveyPage {
  final int id;
  final String pageName;
  final int surveyId;
  final int order;
  final List<SurveyQuestionDetail> questions;

  SurveyPage({
    required this.id,
    required this.pageName,
    required this.surveyId,
    required this.order,
    required this.questions,
  });

  factory SurveyPage.fromJson(Map<String, dynamic> json) {
    return SurveyPage(
      id: json['id'],
      pageName: json['page_name'] ?? '',
      surveyId: json['survey_id'],
      order: json['order'] ?? 0,
      questions: (json['question'] as List?)
              ?.map((e) => SurveyQuestionDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SurveyQuestionDetail {
  final int id;
  final String questionText;
  final int questionTypeId;
  final int surveyId;
  final int order;
  final int required;
  final int? questionChoiceId;
  final int questionLogicTypeId;
  final String? choiceType;
  final dynamic value;
  final List<SurveyChoice> choices;
  final SurveyLogic logic;
  final List<SurveyMatrixItem> matrixRows;
  final List<SurveyMatrixItem> matrixColumns;
  final String? matrixType;

  SurveyQuestionDetail({
    required this.id,
    required this.questionText,
    required this.questionTypeId,
    required this.surveyId,
    required this.order,
    required this.required,
    this.questionChoiceId,
    required this.questionLogicTypeId,
    this.choiceType,
    this.value,
    required this.choices,
    required this.logic,
    required this.matrixRows,
    required this.matrixColumns,
    this.matrixType,
  });

  factory SurveyQuestionDetail.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionDetail(
      id: json['id'],
      questionText: json['question_text'] ?? '',
      questionTypeId: json['question_type_id'] ?? 0,
      surveyId: json['survey_id'],
      order: json['order'] ?? 0,
      required: json['required'] ?? 0,
      questionChoiceId: json['question_choice_id'],
      questionLogicTypeId: json['question_logic_type_id'] ?? 0,
      choiceType: json['choice_type'],
      value: json['value'],
      choices: (json['choice'] as List?)
              ?.map((e) => SurveyChoice.fromJson(e))
              .toList() ??
          [],
      logic: SurveyLogic.fromJson(json['logic'] ?? {}),
      matrixRows: (json['matrix_rows'] as List?)
              ?.map((e) => SurveyMatrixItem.fromJson(e))
              .toList() ??
          [],
      matrixColumns: (json['matrix_columns'] as List?)
              ?.map((e) => SurveyMatrixItem.fromJson(e))
              .toList() ??
          [],
      matrixType: json['matrix_type'],
    );
  }

  String get uiType {
    switch (questionTypeId) {
      case 1: return 'text';
      case 2: return 'radio';
      case 3: return 'checkbox';
      case 4: return 'dropdown';
      case 6: return 'number';
      case 7: return 'radio';
      case 9: return 'matrix';
      default: return 'unknown';
    }
  }
}

class SurveyLogic {
  final int id;
  final String logicType;

  SurveyLogic({required this.id, required this.logicType});

  factory SurveyLogic.fromJson(Map<String, dynamic> json) {
    return SurveyLogic(
      id: json['id'] ?? 0,
      logicType: json['logic_type'] ?? '',
    );
  }
}

class SurveyChoice {
  final int id;
  final int questionId;
  final int order;
  final String value;
  final dynamic scale;

  SurveyChoice({
    required this.id,
    required this.questionId,
    required this.order,
    required this.value,
    this.scale,
  });

  factory SurveyChoice.fromJson(Map<String, dynamic> json) {
    return SurveyChoice(
      id: json['id'],
      questionId: json['question_id'],
      order: json['order'] ?? 0,
      value: json['value'] ?? '',
      scale: json['scale'],
    );
  }
}

class SurveyAnswer {
  final int id;
  final int responseId;
  final int questionId;
  final String answer;

  SurveyAnswer({
    required this.id,
    required this.responseId,
    required this.questionId,
    required this.answer,
  });

  factory SurveyAnswer.fromJson(Map<String, dynamic> json) {
    return SurveyAnswer(
      id: json['id'],
      responseId: json['response_id'],
      questionId: json['question_id'],
      answer: json['answer'] ?? '',
    );
  }
}

class SurveyMatrixItem {
  final String label;

  SurveyMatrixItem({required this.label});

  factory SurveyMatrixItem.fromJson(Map<String, dynamic> json) {
    return SurveyMatrixItem(label: json['label'] ?? '');
  }
}
