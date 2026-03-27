import 'dart:convert';

import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../models/survey_response_detail_model.dart';

class EditAnswerService {
  final _api = ApiClient();

  // ── AMBIL DATA UNTUK FORM EDIT ────────────────────────────
  // GET /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/edit-answer/{userId}
  Future<SurveyResponseDetail?> getEditAnswerData({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required int userId,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.editAnswer(clientSlug, projectSlug, surveySlug, userId),
      );

      if (response.data != null) {
        return SurveyResponseDetail.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── SIMPAN PERUBAHAN JAWABAN ──────────────────────────────
  // PATCH /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{slug}/change-answer/{responseId}
  Future<bool> submitChanges({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required int responseId,
    required List<SurveyPageData> pages,
    required Map<int, dynamic> currentAnswers,
  }) async {
    try {
      final payload = _buildPayload(pages, currentAnswers);

      await _api.patch(
        Endpoints.changeAnswer(clientSlug, projectSlug, surveySlug, responseId),
        body: payload,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER — bangun payload sesuai format Laravel ChangeAnswerRequest
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildPayload(
    List<SurveyPageData> pages,
    Map<int, dynamic> currentAnswers,
  ) {
    return {
      'page': pages.map((page) {
        return {
          'question': page.questions.map((q) {
            return {
              'id': q.id,
              'question_type_id': q.questionTypeId,
              'ans': _buildAnswerValue(q, currentAnswers[q.id]),
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  /// Konversi jawaban UI ke format key yang diterima Laravel
  Map<String, dynamic> _buildAnswerValue(
    SurveyQuestionData question,
    dynamic answer,
  ) {
    if (answer == null) return {'texts': ''};

    switch (question.questionTypeId) {
      case 1: // Text
      case 8: // Paragraph
        return {'texts': answer.toString()};

      case 2: // Radio
        return {'radios': answer.toString()};

      case 3: // Checkbox
        if (answer is List) {
          return {'checkboxes': answer.map((e) => e.toString()).toList()};
        }
        return {'checkboxes': []};

      case 6: // Rating/Number
        return {'radios': answer.toString()};

      case 7: // Dropdown
        return {'dropdowns': answer.toString()};

      case 9: // Matrix
        return {'matrix': _buildMatrixValue(question.matrixType, answer)};

      default:
        return {'texts': answer.toString()};
    }
  }

  /// Konversi jawaban matrix dari UI ke format JSON yang diterima Laravel
  ///   radio    → {"0": 1, "1": 2}
  ///   checkbox → {"0": [0,1], "1": [2]}
  Map<String, dynamic> _buildMatrixValue(String matrixType, dynamic answer) {
    if (answer is! Map) return {};

    final Map<String, dynamic> result = {};
    answer.forEach((key, value) {
      if (matrixType == 'radio') {
        result[key.toString()] = value;
      } else {
        result[key.toString()] = value is List ? value : [];
      }
    });

    return result;
  }

  // ---------------------------------------------------------------------------
  // HELPER — parse existing answers dari API ke Map untuk initial state UI
  // ---------------------------------------------------------------------------

  /// Mengubah List<SurveyAnswerData> ke Map<questionId, dynamic>
  /// supaya bisa langsung dipakai sebagai initial value di form
  Map<int, dynamic> parseExistingAnswers({
    required List<SurveyAnswerData> answers,
    required List<SurveyPageData> pages,
  }) {
    // Lookup questionId → question (untuk cek tipe)
    final Map<int, SurveyQuestionData> questionMap = {
      for (final page in pages)
        for (final q in page.questions) q.id: q,
    };

    // Kelompokkan answers per questionId
    // (checkbox bisa punya lebih dari 1 row answer untuk 1 question)
    final Map<int, List<String>> grouped = {};
    for (final ans in answers) {
      grouped.putIfAbsent(ans.questionId, () => []).add(ans.answer);
    }

    final Map<int, dynamic> result = {};

    grouped.forEach((questionId, answerList) {
      final question = questionMap[questionId];
      if (question == null) return;

      switch (question.questionTypeId) {
        case 3: // Checkbox → List<String>
          result[questionId] = answerList;
          break;

        case 9: // Matrix → decode JSON string ke Map
          final raw = answerList.isNotEmpty ? answerList.first : '';
          result[questionId] = _decodeMatrixAnswer(raw, question.matrixType);
          break;

        case 2: // Radio
        case 7: // Dropdown
          if (answerList.isNotEmpty) {
            final rawAns = answerList.first;
            // Cek apakah rawAns adalah salah satu ID dari choices
            final existsAsId =
                question.choices.any((c) => c.id.toString() == rawAns);

            if (existsAsId) {
              result[questionId] = rawAns;
            } else {
              // Jika tidak ada ID yang cocok, coba cari berdasarkan label (case-insensitive)
              try {
                final matchedChoice = question.choices.firstWhere(
                  (c) => c.value.toLowerCase() == rawAns.toLowerCase(),
                );
                result[questionId] = matchedChoice.id.toString();
              } catch (_) {
                // Jika tidak ada yang cocok sama sekali, biarkan apa adanya
                result[questionId] = rawAns;
              }
            }
          } else {
            result[questionId] = '';
          }
          break;

        default: // Semua tipe lain (Text, Paragraph, etc.)
          result[questionId] = answerList.isNotEmpty ? answerList.first : '';
          break;
      }
    });

    return result;
  }

  /// Decode JSON string matrix dari API ke Map yang dipakai UI
  dynamic _decodeMatrixAnswer(String raw, String matrixType) {
    if (raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};

      if (matrixType == 'radio') {
        // Map<int, int> → rowIndex: colIndex
        return decoded.map(
          (k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v as int),
        );
      } else {
        // Map<int, List<int>> → rowIndex: [colIndexes]
        return decoded.map((k, v) {
          final rowIdx = int.tryParse(k.toString()) ?? 0;
          final cols = (v as List).map((e) => e as int).toList();
          return MapEntry(rowIdx, cols);
        });
      }
    } catch (_) {
      return {};
    }
  }
}