import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/survey_response_detail_model.dart';
import '../service/survey_service.dart';   // ← pakai SurveyService untuk load
import '../service/edit_answer_service.dart'; // ← pakai EditAnswerService untuk save

class CekEditMonitorPage extends StatefulWidget {
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;
  final int responseId; // ← dipakai untuk GET report/{responseId} dan POST change-answer/{responseId}

  const CekEditMonitorPage({
    super.key,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
    required this.responseId,
  });

  @override
  State<CekEditMonitorPage> createState() => _CekEditMonitorPageState();
}

class _CekEditMonitorPageState extends State<CekEditMonitorPage>
    with SingleTickerProviderStateMixin {
  final SurveyService _surveyService = SurveyService();       // untuk load
  final EditAnswerService _editService = EditAnswerService(); // untuk save

  bool isLoading = true;
  SurveyResponseDetail? surveyData;

  Map<int, dynamic> answers = {};
  Map<int, dynamic> originalAnswers = {};

  bool isSaving = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadData();
  }

  // ── LOAD: pakai GET report/{responseId} ──────────────────
  Future<void> _loadData() async {
    if (widget.responseId == 0) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await _surveyService.getSurveyResponseDetail(
        widget.clientSlug,
        widget.projectSlug,
        widget.surveySlug,
        widget.responseId,
      );

      if (data != null) {
        surveyData = data;

        final parsed = _editService.parseExistingAnswers(
          answers: data.answers,
          pages: data.pages,
        );
        answers = Map<int, dynamic>.from(parsed);
        originalAnswers = Map<int, dynamic>.from(parsed);
      }
    } catch (e) {
      debugPrint("Error loading monitor data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (widget.responseId == 0) {
      return _scaffold(
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "ID Responden tidak valid. Silakan kembali dan pilih responden lagi.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (surveyData == null || surveyData!.pages.isEmpty) {
      return _scaffold(body: const Center(child: Text("Data tidak ditemukan")));
    }

    final allQuestions = [
      for (final page in surveyData!.pages) ...page.questions,
    ];

    return _scaffold(
      showFab: true,
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOut,
        ),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          itemCount: allQuestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) =>
              _buildQuestionCard(allQuestions[index], index),
        ),
      ),
    );
  }

  Widget _scaffold({required Widget body, bool showFab = false}) {
    return Scaffold(
      backgroundColor: AppTheme.monBgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.monGreenMid,
        centerTitle: true,
        title: const Text(
          "Cek / Edit Monitor",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: showFab ? _buildSaveButton() : null,
      body: body,
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.monGreenMid,
            elevation: 4,
            shadowColor: AppTheme.monGreenMid.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Update Monitor",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── QUESTION CARD ─────────────────────────────────────────

  Widget _buildQuestionCard(SurveyQuestionData q, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.monBorderColor.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.monGreenPale.withOpacity(0.5),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.monBorderColor.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.monGreenMid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.plainText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.monTextDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAnswerInput(q),
            ),
          ],
        ),
      ),
    );
  }

  // ── ANSWER INPUT ──────────────────────────────────────────

  Widget _buildAnswerInput(SurveyQuestionData q) {
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

  Widget _buildRadio(SurveyQuestionData q) {
    return Column(
      children: q.choices.map((opt) {
        final isSelected = answers[q.id]?.toString() == opt.id.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => answers[q.id] = opt.id.toString()),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.monGreenPale : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.monGreenMid : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppTheme.monGreenMid
                        : Colors.grey.shade400,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.value,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.monTextDark
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckbox(SurveyQuestionData q) {
    final List<String> selected = answers[q.id] is List
        ? List<String>.from((answers[q.id] as List).map((e) => e.toString()))
        : [];

    return Column(
      children: q.choices.map((opt) {
        final optId = opt.id.toString();
        final isChecked = selected.contains(optId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                final updated = List<String>.from(selected);
                isChecked ? updated.remove(optId) : updated.add(optId);
                answers[q.id] = updated;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isChecked ? AppTheme.monGreenPale : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isChecked ? AppTheme.monGreenMid : Colors.grey.shade300,
                  width: isChecked ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isChecked
                          ? AppTheme.monGreenMid
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isChecked
                            ? AppTheme.monGreenMid
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.value,
                      style: TextStyle(
                        color: isChecked
                            ? AppTheme.monTextDark
                            : Colors.grey.shade700,
                        fontWeight:
                            isChecked ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown(SurveyQuestionData q) {
    return DropdownButtonFormField<String>(
      value: answers[q.id]?.toString(),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
      ),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.monGreenMid, width: 1.5),
        ),
      ),
      hint: const Text("Pilih salah satu..."),
      items: q.choices
          .map((opt) => DropdownMenuItem(
                value: opt.id.toString(),
                child: Text(opt.value),
              ))
          .toList(),
      onChanged: (val) => setState(() => answers[q.id] = val),
    );
  }

  Widget _buildTextField(SurveyQuestionData q) {
    return TextFormField(
      initialValue: answers[q.id]?.toString() ?? '',
      keyboardType: q.typeString == 'number'
          ? TextInputType.number
          : TextInputType.multiline,
      maxLines: q.typeString == 'paragraph' ? 4 : 1,
      onChanged: (val) => answers[q.id] = val,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.monGreenMid, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMatrix(SurveyQuestionData q) {
    if (q.matrixRows.isEmpty || q.matrixColumns.isEmpty) {
      return const Text('Data matrix tidak tersedia');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          AppTheme.monGreenPale.withOpacity(0.4),
        ),
        columns: [
          const DataColumn(label: Text('')),
          ...q.matrixColumns.map((col) => DataColumn(label: Text(col.label))),
        ],
        rows: q.matrixRows.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          final row = rowEntry.value;
          final currentMap = answers[q.id] is Map
              ? Map<int, dynamic>.from(answers[q.id] as Map)
              : <int, dynamic>{};

          return DataRow(cells: [
            DataCell(Text(
              row.label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            )),
            ...q.matrixColumns.asMap().entries.map((colEntry) {
              final colIndex = colEntry.key;

              if (q.matrixType == 'radio') {
                return DataCell(Radio<int>(
                  value: colIndex,
                  groupValue: currentMap[rowIndex] as int?,
                  activeColor: AppTheme.monGreenMid,
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
                  activeColor: AppTheme.monGreenMid,
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
    );
  }

  // ── SAVE: pakai POST change-answer/{responseId} ───────────
  Future<void> _handleSave() async {
    if (surveyData == null) return;

    setState(() => isSaving = true);

    try {
      final success = await _editService.submitChanges(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        responseId: widget.responseId,
        pages: surveyData!.pages,
        currentAnswers: answers,
      );

      if (!mounted) return;

      if (success) {
        originalAnswers = Map<int, dynamic>.from(answers);
        _showSnackbar("Jawaban berhasil disimpan", isSuccess: true);
      } else {
        _showSnackbar("Gagal menyimpan jawaban", isSuccess: false);
      }
    } catch (e) {
      debugPrint("Error submit: $e");
      if (mounted) _showSnackbar("Terjadi kesalahan: $e", isSuccess: false);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.monGreenMid : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
}