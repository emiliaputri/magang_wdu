import 'dart:convert';

import 'survey_model.dart';
import 'project_model.dart';
import 'client_model.dart';

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  return null;
}

Map<String, dynamic>? _extractMap(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
    return data.first as Map<String, dynamic>;
  }
  return null;
}

/// Model utama untuk response dari endpoint:
/// GET /clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/report/{responseId}
class SurveyResponseDetail {
  final SurveyModel? survey;
  final Project? project;
  final Client? client;
  final List<SurveyPageData> pages;
  final List<SurveyAnswerData> answers;
  final DateTime? editedAt;
  final int? responseId;
  final Map<String, dynamic>? responses;
  final Map<String, dynamic>? location;

  SurveyResponseDetail({
    this.survey,
    this.project,
    this.client,
    required this.pages,
    required this.answers,
    this.editedAt,
    this.responseId,
    this.responses,
    this.location,
  });

  factory SurveyResponseDetail.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? responsesMap =
        _extractMap(json['responses']) ??
        (json['responses'] is List && (json['responses'] as List).isNotEmpty
            ? _extractMap((json['responses'] as List).first)
            : null) ??
        _extractMap(json['response']);

    // ── PARSE SUPERVISION NOTES (FLAGGING) ────────────────────
    final Map<int, String> questionNotesMap = {};
    final rawNotes = json['supervision_notes'] ?? responsesMap?['supervision_notes'];
    if (rawNotes is List) {
      for (var noteObj in rawNotes) {
        if (noteObj is Map) {
          final qId = _toInt(noteObj['question_id']);
          final noteText = noteObj['note']?.toString();
          if (qId != null && noteText != null && noteText.isNotEmpty) {
            questionNotesMap[qId] = noteText;
          }
        }
      }
    }

    // ── PARSE PAGES ──────────────────────────────────────────
    final List<dynamic> rawPages = 
        json['pages'] as List? ?? 
        json['page'] as List? ?? 
        json['detail_pages'] as List? ?? 
        [];
    
    List<SurveyPageData> parsedPages = rawPages
        .whereType<Map<String, dynamic>>()
        .map((e) => SurveyPageData.fromJson(e, questionNotesMap))
        .toList();
    
    // Sort pages by order
    parsedPages.sort((a, b) => a.order.compareTo(b.order));

    // ── FALLBACK: VIRTUAL PAGE IF NO PAGES BUT QUESTIONS EXIST ─
    if (parsedPages.isEmpty) {
      final List<dynamic> rawQuestions = 
          json['questions'] as List? ?? 
          json['question'] as List? ?? 
          json['detail_questions'] as List? ?? 
          [];
      
      if (rawQuestions.isNotEmpty) {
        final List<SurveyQuestionData> questions = rawQuestions
            .whereType<Map<String, dynamic>>()
            .map((e) => SurveyQuestionData.fromJson(e, questionNotesMap))
            .toList();
        
        // Sort questions by order
        questions.sort((a, b) => a.order.compareTo(b.order));

        parsedPages = [
          SurveyPageData(
            id: 0,
            pageName: 'Kuesioner',
            order: 1,
            surveyId: 0,
            questions: questions,
          )
        ];
      }
    }

    // ── PARSE ANSWERS ─────────────────────────────────────────
    final List<SurveyAnswerData> parsedAnswers = (() {
      final List<dynamic> rawAnswers = [
        ...(json['answer'] as List? ?? []),
        ...(json['answers'] as List? ?? []),
      ];

      if (responsesMap != null) {
        // Cek 'answer' dan 'answers' langsung di responsesMap
        rawAnswers.addAll(responsesMap['answer'] as List? ?? []);
        rawAnswers.addAll(responsesMap['answers'] as List? ?? []);
        
        // Cek di dalam 'data' (Laravel often wraps results in 'data')
        final dataObj = responsesMap['data'];
        if (dataObj is Map) {
          rawAnswers.addAll(dataObj['answer'] as List? ?? []);
          rawAnswers.addAll(dataObj['answers'] as List? ?? []);
        } else if (dataObj is List) {
          for (var item in dataObj) {
            if (item is Map) {
              rawAnswers.addAll(item['answer'] as List? ?? []);
              rawAnswers.addAll(item['answers'] as List? ?? []);
            }
          }
        }
      }

      final targetResponseId = _toInt(
        json['response_id'] ?? 
        json['id'] ?? 
        responsesMap?['id']
      ) ?? 0;

      return rawAnswers
          .whereType<Map<String, dynamic>>()
          .map((e) => SurveyAnswerData.fromJson(e))
          // Hanya ambil jawaban yang punya questionId valid
          .where((a) => a.questionId > 0)
          // KRITIKAL: Pastikan jawaban memang milik response ini (jika ada data ID tertukar dari all-report)
          .where((a) => a.responseId == 0 || a.responseId == targetResponseId)
          .toList();
    })();

    return SurveyResponseDetail(
      survey: _extractMap(json['surveys']) != null
          ? SurveyModel.fromJson(_extractMap(json['surveys'])!)
          : (_extractMap(json['survey']) != null
                ? SurveyModel.fromJson(_extractMap(json['survey'])!)
                : null),
      project: _extractMap(json['projects']) != null
          ? Project.fromJson(_extractMap(json['projects'])!)
          : (_extractMap(json['project']) != null
                ? Project.fromJson(_extractMap(json['project'])!)
                : null),
      client: _extractMap(json['clients']) != null
          ? Client.fromJson(_extractMap(json['clients'])!)
          : (_extractMap(json['client']) != null
                ? Client.fromJson(_extractMap(json['client'])!)
                : null),
      pages: parsedPages,
      answers: parsedAnswers,
      editedAt: json['edited_at'] != null
          ? DateTime.tryParse(json['edited_at'].toString())
          : null,
      responseId: _toInt(
        json['response_id'] ??
            json['id'] ??
            json['responseId'] ??
            json['id_response'] ??
            json['res_id'] ??
            responsesMap?['id'],
      ),
      responses: responsesMap,
      location:
          _extractMap(json['location']) ??
          (json['location'] is List && (json['location'] as List).isNotEmpty
              ? _extractMap((json['location'] as List).first)
              : null),
    );
  }
}

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

  factory SurveyPageData.fromJson(Map<String, dynamic> json, [Map<int, String>? notesMap]) {
    final List<SurveyQuestionData> questions =
          (json['questions'] as List? ?? json['question'] as List?)
              ?.map(
                (e) => SurveyQuestionData.fromJson(e as Map<String, dynamic>, notesMap),
              )
              .toList() ??
          [];
    
    // Sort questions by order
    questions.sort((a, b) => a.order.compareTo(b.order));

    return SurveyPageData(
      id: _toInt(json['id']) ?? 0,
      pageName: json['page_name'] ?? '',
      order: _toInt(json['order']) ?? 0,
      surveyId: _toInt(json['survey_id']) ?? 0,
      questions: questions,
    );
  }
}

class SurveyQuestionData {
  final int id;
  final String questionText;
  final int questionTypeId;
  final int order;
  final int required;
  final List<QuestionChoiceData> choices;
  final int? questionChoiceId;
  final int? questionLogicTypeId;
  final String? choiceType;
  final String? value;
  final List<MatrixRowData> matrixRows;
  final List<MatrixColumnData> matrixColumns;
  final String matrixType;
  final List<Map<String, dynamic>> embeddedAnswers;
  final String? supervisionNote;

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
    this.embeddedAnswers = const [],
    this.supervisionNote,
  });

  factory SurveyQuestionData.fromJson(Map<String, dynamic> json, [Map<int, String>? notesMap]) {
    final qId = _toInt(json['id']) ?? 0;
    
    List<MatrixRowData> parsedRows = [];
    final rawRows = json['matrix_rows'];
    if (rawRows != null) {
      if (rawRows is List) {
        parsedRows = rawRows.map((e) => MatrixRowData.fromJson(e as Map<String, dynamic>)).toList();
      } else if (rawRows is String && rawRows.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawRows);
          if (decoded is List) {
            parsedRows = decoded.map((e) => MatrixRowData.fromJson(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}
      }
    }

    List<MatrixColumnData> parsedCols = [];
    final rawCols = json['matrix_columns'];
    if (rawCols != null) {
      if (rawCols is List) {
        parsedCols = rawCols.map((e) => MatrixColumnData.fromJson(e as Map<String, dynamic>)).toList();
      } else if (rawCols is String && rawCols.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawCols);
          if (decoded is List) {
            parsedCols = decoded.map((e) => MatrixColumnData.fromJson(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}
      }
    }

    return SurveyQuestionData(
      id: qId,
      questionText: json['question_text'] ?? '',
      questionTypeId: _toInt(json['question_type_id']) ?? 1,
      order: _toInt(json['order']) ?? 0,
      required: _toInt(json['required']) ?? 0,
      choices: (json['choices'] as List? ?? json['choice'] as List?)
              ?.map((e) => QuestionChoiceData.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      questionChoiceId: _toInt(json['question_choice_id']),
      questionLogicTypeId: _toInt(json['question_logic_type_id'] ?? json['logic_type']),
      choiceType: json['choice_type'],
      value: json['value']?.toString(),
      matrixRows: parsedRows,
      matrixColumns: parsedCols,
      matrixType: json['matrix_type'] ?? 'radio',
      embeddedAnswers: (json['answer'] as List? ?? json['answers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ?? [],
      supervisionNote: notesMap?[qId],
    );
  }

  bool get isMatrix => questionTypeId == 9;
  String get typeString {
    switch (questionTypeId) {
      case 1: return 'text';
      case 2: return 'radio';
      case 3: return 'checkbox';
      case 4: return 'number';
      case 5: return 'info';
      case 6: return 'number';
      case 7: return 'dropdown';
      case 8: return 'paragraph';
      case 9: return 'matrix';
      case 10: return 'document';
      default: return 'text';
    }
  }

  String get plainText => questionText.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
}

class MatrixRowData {
  final String label;
  final int? id;
  MatrixRowData({required this.label, this.id});
  factory MatrixRowData.fromJson(Map<String, dynamic> json) {
    final label = json['label']?.toString() ?? json['text']?.toString() ?? json['value']?.toString() ?? '';
    final id = json['id'] != null ? _toInt(json['id']) : null;
    return MatrixRowData(label: label, id: id);
  }
}

class MatrixColumnData {
  final String label;
  final int? id;
  MatrixColumnData({required this.label, this.id});
  factory MatrixColumnData.fromJson(Map<String, dynamic> json) {
    final label = json['label']?.toString() ?? json['text']?.toString() ?? json['value']?.toString() ?? '';
    final id = json['id'] != null ? _toInt(json['id']) : null;
    return MatrixColumnData(label: label, id: id);
  }
}

class QuestionChoiceData {
  final int id;
  final int questionId;
  final String value;
  final int order;
  final int? scale;
  QuestionChoiceData({required this.id, required this.questionId, required this.value, required this.order, this.scale});
  factory QuestionChoiceData.fromJson(Map<String, dynamic> json) {
    return QuestionChoiceData(
      id: _toInt(json['id']) ?? 0,
      questionId: _toInt(json['question_id']) ?? 0,
      value: json['value'] ?? '',
      order: _toInt(json['order']) ?? 0,
      scale: _toInt(json['scale']),
    );
  }
}

class SurveyAnswerData {
  final int id;
  final int responseId;
  final int questionId;
  final String answer;
  SurveyAnswerData({required this.id, required this.responseId, required this.questionId, required this.answer});
  factory SurveyAnswerData.fromJson(Map<String, dynamic> json) {
    return SurveyAnswerData(
      id: _toInt(json['id'] ?? json['id_answer']) ?? 0,
      responseId: _toInt(json['response_id'] ?? json['responseId'] ?? json['id_response'] ?? json['res_id'] ?? json['id_report']) ?? 0,
      questionId: _toInt(json['question_id'] ?? json['questionId'] ?? json['id_pertanyaan']) ?? 0,
      answer: (json['answer'] ?? json['ans'] ?? json['value'] ?? json['texts'] ?? json['radios'] ?? json['checkboxes'] ?? json['dropdowns'])?.toString() ?? '',
    );
  }
}
