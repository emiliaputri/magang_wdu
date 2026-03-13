import 'dart:convert';

/// Model untuk REQUEST body ke endpoint:
/// POST /clients/{clientSlug}/projects/{projectSlug}/surveys/{survey}/change-answer/{responseId}
///
/// Laravel menerima struktur:
/// {
///   "page": [
///     {
///       "question": [{"id": 1, ...}],
///       "answer": [{"texts": "...", "radios": "...", "checkboxes": [...]}]
///     }
///   ]
/// }
class ChangeAnswerRequest {
  final List<ChangeAnswerPagePayload> pages;

  ChangeAnswerRequest({required this.pages});

  Map<String, dynamic> toJson() {
    return {
      'page': pages.map((p) => p.toJson()).toList(),
    };
  }
}

class ChangeAnswerPagePayload {
  final List<ChangeAnswerQuestionPayload> questions;
  final List<ChangeAnswerValuePayload> answers;

  ChangeAnswerPagePayload({
    required this.questions,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': questions.map((q) => q.toJson()).toList(),
      'answer': answers.map((a) => a.toJson()).toList(),
    };
  }
}

class ChangeAnswerQuestionPayload {
  final int id;

  ChangeAnswerQuestionPayload({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

/// Payload jawaban per pertanyaan.
/// Hanya satu field yang diisi sesuai tipe pertanyaan:
/// - texts     → untuk tipe text/essay (type_id: 1, 8)
/// - radios    → untuk single choice (type_id: 2, 6)
/// - checkboxes → untuk multiple choice (type_id: 3) — berupa List<String>
/// - dropdowns → untuk dropdown (type_id: 7) — berupa choice id
/// - matrix    → untuk matrix (type_id: 9) — berupa Map
class ChangeAnswerValuePayload {
  final String? texts;
  final String? radios;
  final List<String>? checkboxes;
  final String? dropdowns;
  final Map<String, dynamic>? matrix;

  ChangeAnswerValuePayload({
    this.texts,
    this.radios,
    this.checkboxes,
    this.dropdowns,
    this.matrix,
  });

  /// Factory untuk tipe text / essay (type_id: 1, 8)
  factory ChangeAnswerValuePayload.text(String value) {
    return ChangeAnswerValuePayload(texts: value);
  }

  /// Factory untuk single choice / radio (type_id: 2, 6)
  factory ChangeAnswerValuePayload.radio(String value) {
    return ChangeAnswerValuePayload(radios: value);
  }

  /// Factory untuk multiple choice / checkbox (type_id: 3)
  factory ChangeAnswerValuePayload.checkbox(List<String> values) {
    return ChangeAnswerValuePayload(checkboxes: values);
  }

  /// Factory untuk dropdown (type_id: 7) — kirim choice id sebagai string
  factory ChangeAnswerValuePayload.dropdown(String choiceId) {
    return ChangeAnswerValuePayload(dropdowns: choiceId);
  }

  /// Factory untuk matrix (type_id: 9)
  /// [matrixAnswer] contoh format:
  ///   radio  → {"0": 1, "1": 2}         (row_index: col_index)
  ///   checkbox → {"0": [0,1], "1": [2]} (row_index: [col_indexes])
  factory ChangeAnswerValuePayload.matrix(Map<String, dynamic> matrixAnswer) {
    return ChangeAnswerValuePayload(matrix: matrixAnswer);
  }

  /// Factory kosong — untuk pertanyaan yang tidak dijawab
  factory ChangeAnswerValuePayload.empty() {
    return ChangeAnswerValuePayload(texts: '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (texts != null) json['texts'] = texts;
    if (radios != null) json['radios'] = radios;
    if (checkboxes != null) json['checkboxes'] = checkboxes;
    if (dropdowns != null) json['dropdowns'] = dropdowns;
    if (matrix != null) json['matrix'] = matrix;

    return json;
  }
}

// ---------------------------------------------------------------------------
// RESPONSE dari POST changeAnswer
// ---------------------------------------------------------------------------

/// Model untuk RESPONSE dari endpoint POST change-answer
class ChangeAnswerResponse {
  final String message;
  final bool success;

  ChangeAnswerResponse({
    required this.message,
    required this.success,
  });

  factory ChangeAnswerResponse.fromJson(Map<String, dynamic> json) {
    return ChangeAnswerResponse(
      message: json['message']?.toString() ?? '',
      success: json['message'] != null,
    );
  }

  factory ChangeAnswerResponse.error(String errorMessage) {
    return ChangeAnswerResponse(
      message: errorMessage,
      success: false,
    );
  }
}