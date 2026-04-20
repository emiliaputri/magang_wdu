import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../models/survey_response_detail_model.dart';

class EditAnswerService {
  final _api = ApiClient();

  // ── CEK APAKAH USER SUDAH MENJAWAB ───────────────────────────
  Future<bool> hasUserAnswered({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required int userId,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.editAnswer(clientSlug, projectSlug, surveySlug, userId),
      );
      return response.data != null && response.data!.isNotEmpty;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    } catch (e) {
      return false;
    }
  }

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

      print("DEBUG getEditAnswerData - Response: ${response.data}");
      print("DEBUG getEditAnswerData - Status: ${response.statusCode}");

      if (response.data != null) {
        final dynamic data = response.data;

        // Handle common wrapper keys 'data', 'responses', 'survey'
        if (data is Map<String, dynamic>) {
          print("DEBUG getEditAnswerData - Map keys: ${data.keys.toList()}");
          print(
            "DEBUG getEditAnswerData - Has 'answer' key: ${data.containsKey('answer')}",
          );
          print(
            "DEBUG getEditAnswerData - Has 'answers' key: ${data.containsKey('answers')}",
          );
          print(
            "DEBUG getEditAnswerData - Has 'response' key: ${data.containsKey('response')}",
          );
          print(
            "DEBUG getEditAnswerData - Has 'responses' key: ${data.containsKey('responses')}",
          );

          // Debug answers content
          final answerKey = data.containsKey('answer')
              ? 'answer'
              : (data.containsKey('answers') ? 'answers' : null);
          if (answerKey != null) {
            print(
              "DEBUG getEditAnswerData - Answer content: ${data[answerKey]}",
            );
          }

          final responseKey = data.containsKey('response')
              ? 'response'
              : (data.containsKey('responses') ? 'responses' : null);
          if (responseKey != null) {
            print(
              "DEBUG getEditAnswerData - Response content: ${data[responseKey]}",
            );
          }

          // Check if answer is empty - try fallback to report endpoint
          final answerList =
              data['answer'] as List? ?? data['answers'] as List? ?? [];
          final isAnswerEmpty = answerList.isEmpty;
          final responseIdFromApi = data['response_id'] as int?;

          if (isAnswerEmpty &&
              responseIdFromApi != null &&
              responseIdFromApi > 0) {
            print(
              "DEBUG getEditAnswerData - Answer is empty, trying fallback report endpoint",
            );
            try {
              final fallbackResponse = await _api.get(
                Endpoints.surveyReport(
                  clientSlug,
                  projectSlug,
                  surveySlug,
                  responseIdFromApi,
                ),
              );
              if (fallbackResponse.data != null) {
                print(
                  "DEBUG getEditAnswerData - Fallback report response keys: ${(fallbackResponse.data as Map).keys.toList()}",
                );
                final fallbackData =
                    fallbackResponse.data as Map<String, dynamic>;
                // Merge answer from fallback
                final mergedData = Map<String, dynamic>.from(data);
                if (fallbackData.containsKey('answer') &&
                    (fallbackData['answer'] as List?)?.isNotEmpty == true) {
                  mergedData['answer'] = fallbackData['answer'];
                  print(
                    "DEBUG getEditAnswerData - Using answers from fallback",
                  );
                  return SurveyResponseDetail.fromJson(mergedData);
                } else if (fallbackData.containsKey('answers') &&
                    (fallbackData['answers'] as List?)?.isNotEmpty == true) {
                  mergedData['answers'] = fallbackData['answers'];
                  print(
                    "DEBUG getEditAnswerData - Using answers from fallback (answers key)",
                  );
                  return SurveyResponseDetail.fromJson(mergedData);
                }
              }
            } catch (e) {
              print("DEBUG getEditAnswerData - Fallback error: $e");
            }

            // Note: /responses/{responseId} endpoint tidak tersedia di backend
            // Commented out until backend fix
          }

          if (data.containsKey('data') &&
              data['data'] is Map<String, dynamic>) {
            print("DEBUG getEditAnswerData - Using data['data'] as Map");
            debugPrint("DEBUG RAW DATA: ${jsonEncode(data['data'])}");
            return SurveyResponseDetail.fromJson(
              data['data'] as Map<String, dynamic>,
            );
          } else if (data.containsKey('data') && data['data'] is List) {
            final list = data['data'] as List;
            print(
              "DEBUG getEditAnswerData - Using data['data'] as List, length: ${list.length}",
            );
            if (list.isNotEmpty && list.first is Map<String, dynamic>) {
              debugPrint(
                "DEBUG RAW LIST FIRST ITEM: ${jsonEncode(list.first)}",
              );
              return SurveyResponseDetail.fromJson(
                list.first as Map<String, dynamic>,
              );
            }
          }
          print("DEBUG getEditAnswerData - Using raw Map");
          debugPrint("DEBUG RAW MAP: ${jsonEncode(data)}");
          return SurveyResponseDetail.fromJson(data);
        } else if (data is List && data.isNotEmpty) {
          print("DEBUG getEditAnswerData - Raw List, length: ${data.length}");
          final firstItem = data.first;
          if (firstItem is Map<String, dynamic>) {
            debugPrint("DEBUG RAW FIRST ITEM: ${jsonEncode(firstItem)}");
            return SurveyResponseDetail.fromJson(firstItem);
          }
        }
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e, st) {
      print("getEditAnswerData ERROR: $e\n$st");
      // Jika error, coba fallback ke form kosong agar tidak stuck blank
      return await getSurveyFormKosong(
        clientSlug: clientSlug,
        projectSlug: projectSlug,
        surveySlug: surveySlug,
      );
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
      // Debug: Print pages structure
      debugPrint(
        '[EditAnswerService] submitChanges - pages count: ${pages.length}',
      );
      for (var i = 0; i < pages.length; i++) {
        debugPrint(
          '[EditAnswerService] Page $i - questions count: ${pages[i].questions.length}',
        );
        for (var j = 0; j < pages[i].questions.length; j++) {
          final q = pages[i].questions[j];
          debugPrint(
            '[EditAnswerService]   Question $j - id: ${q.id}, type: ${q.questionTypeId}',
          );
        }
      }

      final payload = _buildPayload(pages, currentAnswers);

      debugPrint('[EditAnswerService] === FINAL PAYLOAD ===');
      debugPrint('[EditAnswerService] Payload: ${jsonEncode(payload)}');
      debugPrint('[EditAnswerService] ======================');

      final response = await _api.patch(
        Endpoints.changeAnswer(clientSlug, projectSlug, surveySlug, responseId),
        body: payload,
      );
      debugPrint('[EditAnswerService] Response: ${response.data}');
      return true;
    } catch (e) {
      print("Error submitChanges: $e");
      return false;
    }
  }

  // ── AMBIL SURVEI KOSONG JIKA BELUM ADA JAWABAN (404) ──────
  Future<SurveyResponseDetail?> getSurveyFormKosong({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.surveyDetail(clientSlug, projectSlug, surveySlug),
      );

      if (response.data != null) {
        final data = response.data!;
        // Jika endpoint detail membungkus halaman dalam "data" berupa List
        if (data.containsKey('data') && data['data'] is List) {
          final pagesList = data['data'] as List;
          final List<SurveyPageData> parsedPages = pagesList
              .map((e) => SurveyPageData.fromJson(e as Map<String, dynamic>))
              .toList();
          return SurveyResponseDetail(pages: parsedPages, answers: []);
        }
        return SurveyResponseDetail.fromJson(data);
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e, st) {
      print("getSurveyFormKosong ERROR: $e\n$st");
      throw Exception("Format JSON form kosong tidak valid: $e");
    }
  }

  // ── KIRIM JAWABAN BARU (PERTAMA KALI) ───────────────────────
  // POST /api/clients/{clientSlug}/projects/{projectSlug}/surveys/{surveyId}/submit
  Future<bool> submitNewAnswer({
    required String clientSlug,
    required String projectSlug,
    required String surveySlug,
    required List<SurveyPageData> pages,
    required Map<int, dynamic> currentAnswers,
  }) async {
    try {
      final payload = _buildPayload(pages, currentAnswers);

      // Wrap payload dalam field "data" sesuai format backend
      final wrappedPayload = {'data': jsonEncode(payload)};

      await _api.post(
        Endpoints.submitAnswer(clientSlug, projectSlug, surveySlug),
        body: wrappedPayload,
      );
      return true;
    } catch (e) {
      print("Error submitNewAnswer: $e");
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
    // Filter pages that have at least one valid question
    final validPages = pages.where((page) {
      return page.questions.any(
        (q) =>
            q.id != null &&
            q.questionTypeId != null &&
            q.questionTypeId != 5, // Must have at least one non-info question
      );
    }).toList();

    final payload = {
      'page': validPages.map((page) {
        // Filter questions that have valid id and questionTypeId
        final validQuestions = page.questions
            .where(
              (q) =>
                  q.id != null &&
                  q.questionTypeId != null &&
                  q.questionTypeId != 5,
            ) // Skip Instructions/Petunjuk
            .toList();

        return {
          'question': validQuestions.map((q) {
            return {
              'id': q.id,
              'question_type_id': q.questionTypeId,
              'ans': _buildAnswerValue(q, currentAnswers[q.id]),
            };
          }).toList(),
        };
      }).toList(),
    };

    // Debug: Print payload yang akan dikirim
    debugPrint(
      '[EditAnswerService] Payload yang dikirim: ${jsonEncode(payload)}',
    );

    return payload;
  }

  /// Konversi jawaban UI ke format key yang diterima Laravel
  /// Return: List<Map> dengan key 'answe' sesuai format AnswerService::processQuestion
  List<Map<String, dynamic>> _buildAnswerValue(
    SurveyQuestionData question,
    dynamic answer,
  ) {
    if (answer == null)
      return [
        {'answe': ''},
      ];

    switch (question.questionTypeId) {
      case 1: // Text
      case 8: // Paragraph
        return [
          {'answe': answer.toString()},
        ];

      case 2: // Radio
        return [
          {'answe': answer.toString()},
        ];

      case 3: // Checkbox → List<String>
        debugPrint(
          '[EditAnswerService] CHECKBOX questionId=${question.id}, answer=$answer (type: ${answer.runtimeType})',
        );
        if (answer is List && answer.isNotEmpty) {
          final uniqueAnswers = answer
              .map((e) => e.toString())
              .toSet()
              .toList();
          debugPrint(
            '[EditAnswerService] CHECKBOX uniqueAnswers: $uniqueAnswers',
          );
          return [
            {'answe': uniqueAnswers},
          ];
        }
        debugPrint('[EditAnswerService] CHECKBOX empty - return []');
        return [
          {'answe': []},
        ];

      case 6: // Rating/Number
        return [
          {'answe': answer.toString()},
        ];

      case 7: // Dropdown
        return [
          {'answe': answer.toString()},
        ];

      case 9: // Matrix
        final matrixJson = _buildMatrixValue(question.matrixType, answer);
        return [
          {'answe': matrixJson},
        ];

      default:
        return [
          {'answe': answer.toString()},
        ];
    }
  }

  /// Konversi jawaban matrix dari UI ke JSON string yang diterima Laravel
  ///   radio    → '{"0": 1, "1": 2}'
  ///   checkbox → '{"0": [0,1], "1": [2]}'
  String _buildMatrixValue(String matrixType, dynamic answer) {
    if (answer is! Map || answer.isEmpty) return '{}';

    final Map<String, dynamic> result = {};
    answer.forEach((key, value) {
      if (matrixType == 'radio') {
        result[key.toString()] = value;
      } else {
        result[key.toString()] = value is List ? value : [];
      }
    });

    return jsonEncode(result);
  }

  // ---------------------------------------------------------------------------
  // HELPER — parse existing answers dari API ke Map untuk initial state UI
  // ---------------------------------------------------------------------------

  /// Mengubah List<SurveyAnswerData> ke Map<questionId, dynamic>
  /// supaya bisa langsung dipakai sebagai initial value di form
  Map<int, dynamic> parseExistingAnswers({
    required List<SurveyAnswerData> answers,
    required List<SurveyPageData> pages,
    required int responseId,
  }) {
    // Lookup questionId → question (untuk cek tipe)
    final Map<int, SurveyQuestionData> questionMap = {
      for (final page in pages)
        for (final q in page.questions) q.id: q,
    };

    // Filter jawaban berdasarkan responseId - seperti lihat_monitor_page
    final filteredAnswers = answers
        .where((a) => a.responseId == responseId)
        .toList();

    // Kelompokkan answers per questionId
    // (checkbox bisa punya lebih dari 1 row answer untuk 1 question)
    final Map<int, List<String>> grouped = {};
    for (final ans in filteredAnswers) {
      grouped.putIfAbsent(ans.questionId, () => []).add(ans.answer);
    }

    final Map<int, dynamic> result = {};

    grouped.forEach((questionId, answerList) {
      final question = questionMap[questionId];
      if (question == null) return;

      switch (question.questionTypeId) {
        case 3: // Checkbox → List<String>
          // Untuk checkbox, cari jawaban valid (bisa string biasa ATAU JSON array)
          String? latestValidAnswer;
          for (int i = answerList.length - 1; i >= 0; i--) {
            final ans = answerList[i];
            if (ans != null && ans.isNotEmpty && ans != 'Unknown') {
              latestValidAnswer = ans;
              break;
            }
          }
          // Parse JSON array jika ada
          if (latestValidAnswer != null && latestValidAnswer.startsWith('[')) {
            try {
              final decoded = jsonDecode(latestValidAnswer);
              if (decoded is List) {
                final cleanList = decoded
                    .where((e) => e.toString().isNotEmpty)
                    .map((e) => e.toString())
                    .toSet()
                    .toList();
                result[questionId] = cleanList;
              } else {
                result[questionId] = [latestValidAnswer];
              }
            } catch (_) {
              result[questionId] = [latestValidAnswer];
            }
          } else if (latestValidAnswer != null &&
              latestValidAnswer.isNotEmpty) {
            result[questionId] = [latestValidAnswer];
          } else {
            result[questionId] = [];
          }
          break;

        case 9: // Matrix → decode JSON string ke Map
          // Untuk matrix, cari jawaban valid (bisa string biasa ATAU JSON object)
          String? matrixAnswer;
          for (int i = answerList.length - 1; i >= 0; i--) {
            final ans = answerList[i];
            if (ans != null && ans.isNotEmpty && ans != 'Unknown') {
              matrixAnswer = ans;
              break;
            }
          }
          result[questionId] = _decodeMatrixAnswer(
            matrixAnswer ?? '',
            question.matrixType,
          );
          break;

        default: // Radio, Text, Dropdown, dll
          String? latestValidAnswer;
          for (int i = answerList.length - 1; i >= 0; i--) {
            final ans = answerList[i];
            if (ans != null && ans.isNotEmpty && ans != 'Unknown') {
              if (ans.startsWith('[') || ans.startsWith('{')) {
                continue;
              }
              latestValidAnswer = ans;
              break;
            }
          }

          if (question.questionTypeId == 2 || question.questionTypeId == 7) {
            // Radio/Dropdown
            if (latestValidAnswer != null && latestValidAnswer.isNotEmpty) {
              final rawAns = latestValidAnswer;
              final existsAsId = question.choices.any(
                (c) => c.id.toString() == rawAns,
              );
              if (existsAsId) {
                result[questionId] = rawAns;
              } else {
                try {
                  final matchedChoice = question.choices.firstWhere(
                    (c) => c.value.toLowerCase() == rawAns.toLowerCase(),
                  );
                  result[questionId] = matchedChoice.id.toString();
                } catch (_) {
                  result[questionId] = rawAns;
                }
              }
            } else {
              result[questionId] = '';
            }
          } else {
            // Text, Paragraph, dll
            result[questionId] = latestValidAnswer ?? '';
          }
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
