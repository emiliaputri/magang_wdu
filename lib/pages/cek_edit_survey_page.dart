import 'package:flutter/material.dart';
import '../models/survey_response_detail_model.dart';
import '../service/edit_answer_service.dart';
import '../core/api/api_client.dart';
import '../core/utils/storage.dart'; // ← untuk ambil userId

class CekEditSurveyPage extends StatefulWidget {
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;
  final int responseId;
  // ← userId TIDAK perlu di-passing dari luar, diambil otomatis dari storage

  const CekEditSurveyPage({
    super.key,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
    required this.responseId,
  });

  @override
  State<CekEditSurveyPage> createState() => _CekEditSurveyPageState();
}

class _CekEditSurveyPageState extends State<CekEditSurveyPage> {
  final EditAnswerService _editService = EditAnswerService();

  bool isLoading = true;
  SurveyResponseDetail? surveyData;

  Map<int, dynamic> answers = {};
  Map<int, dynamic> originalAnswers = {};

  bool isSaving = false;
  int? _activeResponseId; // ID respons yang akan digunakan untuk PATCH

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── LOAD ─────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    int userId = 0;
    try {
      // Ambil userId langsung dari storage — tidak perlu passing dari luar
      final userIdStr = await StorageHelper.getUserId();
      userId = int.tryParse(userIdStr ?? '') ?? 0;

      if (userId == 0) {
        debugPrint("userId tidak ditemukan di storage");
        setState(() => isLoading = false);
        return;
      }

      final data = await _editService.getEditAnswerData(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        userId: userId,
      );

      if (data != null) {
        surveyData = data;

        // Ambil responseId dari data jawaban pertama jika ada
        if (data.answers.isNotEmpty) {
          _activeResponseId = data.answers.first.responseId;
        }

        final parsed = _editService.parseExistingAnswers(
          answers: data.answers,
          pages: data.pages,
        );
        answers = Map<int, dynamic>.from(parsed);
        originalAnswers = Map<int, dynamic>.from(parsed);
      }
    } on ApiException catch (e) {
      debugPrint("API Error: ${e.message}");
      if (mounted) {
        String errorMsg = e.message;
        if (e.statusCode == 404) {
          errorMsg = "Data jawaban tidak ditemukan. Pastikan Anda (User ID $userId) sudah mengisi survey ini.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      debugPrint("Error loading survey data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ── SAVE ─────────────────────────────────────────────────
  Future<void> _submitChanges() async {
    if (surveyData == null) return;
    setState(() => isSaving = true);

    // Gunakan responseId dari widget (jika ada) atau hasil fetch
    final targetResponseId = widget.responseId > 0 ? widget.responseId : (_activeResponseId ?? 0);

    if (targetResponseId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID Respons tidak ditemukan")),
      );
      setState(() => isSaving = false);
      return;
    }

    try {
      final success = await _editService.submitChanges(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        responseId: targetResponseId,
        pages: surveyData!.pages,
        currentAnswers: answers,
      );

      if (!mounted) return;

      if (success) {
        originalAnswers = Map<int, dynamic>.from(answers);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Jawaban berhasil disimpan")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan jawaban")),
        );
      }
    } catch (e) {
      debugPrint("Error submit: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
      appBar: AppBar(
        title: const Text("Cek / Edit Survey"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (surveyData == null || surveyData!.pages.isEmpty) {
      return Scaffold(
      appBar: AppBar(
        title: const Text("Cek / Edit Survey"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: Text("Data tidak ditemukan")),
      );
    }

    final allQuestions = [
      for (final page in surveyData!.pages) ...page.questions,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cek / Edit Survey"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allQuestions.length,
        itemBuilder: (context, index) => _buildQuestionItem(allQuestions[index]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: isSaving ? null : _submitChanges,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Submit Survey"),
        ),
      ),
    );
  }

  // ── ANSWER INPUT ──────────────────────────────────────────

  Widget _buildQuestionItem(SurveyQuestionData q) {
    switch (q.typeString) {
      case 'radio':     return _buildRadio(q);
      case 'checkbox':  return _buildCheckbox(q);
      case 'dropdown':  return _buildDropdown(q);
      case 'text':
      case 'number':
      case 'paragraph': return _buildTextField(q);
      case 'matrix':    return _buildMatrix(q);
      default:          return const SizedBox();
    }
  }

  Widget _buildLabel(SurveyQuestionData q) {
    return Text(
      q.plainText,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRadio(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        ...q.choices.map((opt) => RadioListTile<String>(
              value: opt.id.toString(),
              groupValue: answers[q.id]?.toString(),
              onChanged: (val) => setState(() => answers[q.id] = val),
              title: Text(opt.value),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCheckbox(SurveyQuestionData q) {
    final List<String> selected = answers[q.id] is List
        ? List<String>.from((answers[q.id] as List).map((e) => e.toString()))
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        ...q.choices.map((opt) {
          final optId = opt.id.toString();
          return CheckboxListTile(
            value: selected.contains(optId),
            onChanged: (val) {
              setState(() {
                final updated = List<String>.from(selected);
                val == true ? updated.add(optId) : updated.remove(optId);
                answers[q.id] = updated;
              });
            },
            title: Text(opt.value),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdown(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: answers[q.id]?.toString(),
          items: q.choices
              .map((opt) => DropdownMenuItem(
                    value: opt.id.toString(),
                    child: Text(opt.value),
                  ))
              .toList(),
          onChanged: (val) => setState(() => answers[q.id] = val),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: answers[q.id]?.toString() ?? '',
          keyboardType: q.typeString == 'number'
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: q.typeString == 'paragraph' ? 4 : 1,
          onChanged: (val) => answers[q.id] = val,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMatrix(SurveyQuestionData q) {
    if (q.matrixRows.isEmpty || q.matrixColumns.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(q),
          const Text('Data matrix tidak tersedia'),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('')),
              ...q.matrixColumns
                  .map((col) => DataColumn(label: Text(col.label))),
            ],
            rows: q.matrixRows.asMap().entries.map((rowEntry) {
              final rowIndex = rowEntry.key;
              final row = rowEntry.value;
              final currentMap = answers[q.id] is Map
                  ? Map<int, dynamic>.from(answers[q.id] as Map)
                  : <int, dynamic>{};

              return DataRow(cells: [
                DataCell(Text(row.label)),
                ...q.matrixColumns.asMap().entries.map((colEntry) {
                  final colIndex = colEntry.key;

                  if (q.matrixType == 'radio') {
                    return DataCell(Radio<int>(
                      value: colIndex,
                      groupValue: currentMap[rowIndex] as int?,
                      onChanged: (_) => setState(() {
                        currentMap[rowIndex] = colIndex;
                        answers[q.id] = Map<int, dynamic>.from(currentMap);
                      }),
                    ));
                  } else {
                    final rowCols = currentMap[rowIndex] is List
                        ? List<int>.from(currentMap[rowIndex] as List)
                        : <int>[];
                    return DataCell(Checkbox(
                      value: rowCols.contains(colIndex),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          if (!rowCols.contains(colIndex)) rowCols.add(colIndex);
                        } else {
                          rowCols.remove(colIndex);
                        }
                        currentMap[rowIndex] = rowCols;
                        answers[q.id] = Map<int, dynamic>.from(currentMap);
                      }),
                    ));
                  }
                }),
              ]);
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}