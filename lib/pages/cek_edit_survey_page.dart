import 'package:flutter/material.dart';
import '../models/survey_response_detail_model.dart';
import '../service/edit_answer_service.dart';
import '../service/auth_service.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../core/utils/storage.dart';
import '../core/theme/app_theme.dart';

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

class _CekEditSurveyPageState extends State<CekEditSurveyPage>
    with WidgetsBindingObserver {
  final EditAnswerService _editService = EditAnswerService();
  final ApiClient _api = ApiClient();

  bool isLoading = true;
  SurveyResponseDetail? surveyData;
  String? loadError;

  Map<int, dynamic> answers = {};
  Map<int, dynamic> originalAnswers = {};

  bool isSaving = false;
  int? _activeResponseId; // ID respons yang akan digunakan untuk PATCH
  bool isNewSurvey = false; // Deteksi apakah ini jawaban baru

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<String?> _fetchCurrentUserId() async {
    try {
      final response = await _api.get(Endpoints.me);
      if (response.data != null) {
        // Handle root 'id' or nested 'data.id'
        final id = response.data!['id'] ?? 
                   (response.data!['data'] is Map ? response.data!['data']['id'] : null);
        return id?.toString();
      }
    } catch (e) {
      debugPrint("Error fetch current user: $e");
    }
    return null;
  }

  // ── LOAD ─────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    int userId = 0;
    try {
      // Ambil userId dari API /user untuksinkron dengan token Bearer yang aktif
      String? userIdStr = await _fetchCurrentUserId();

      // Fallback ke storage jika API gagal
      userIdStr ??= await StorageHelper.getUserId();
      userId = int.tryParse(userIdStr ?? '') ?? 0;
      print("DEBUG _loadData - userId: $userId");

      if (userId == 0) {
        debugPrint("userId tidak ditemukan di storage");
        await _loadEmptyForm();
        return;
      }

      final data = await _editService.getEditAnswerData(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        userId: userId,
      );

      print("DEBUG _loadData - data returned: ${data != null}");
      if (data != null) {
        print(
          "DEBUG _loadData - pages: ${data.pages.length}, answers: ${data.answers.length}, responseId: ${data.responseId}",
        );
        for (var i = 0; i < data.answers.length; i++) {
          print("DEBUG Answer[$i]: QID=${data.answers[i].questionId}, Ans=${data.answers[i].answer}");
        }
        surveyData = data;

        // Ambil responseId dari top-level atau cari dari jawaban yang ada
        _activeResponseId = (data.responseId != null && data.responseId! > 0)
            ? data.responseId
            : null;

        if ((_activeResponseId == null || _activeResponseId == 0) &&
            data.answers.isNotEmpty) {
          // Cari jawaban pertama yang punya responseId > 0
          try {
            _activeResponseId = data.answers
                .firstWhere((a) => a.responseId > 0)
                .responseId;
          } catch (_) {
            _activeResponseId = data.answers.first.responseId;
          }
        }

        final parsed = _editService.parseExistingAnswers(
          answers: data.answers,
          pages: data.pages,
        );
        answers = Map<int, dynamic>.from(parsed);
        originalAnswers = Map<int, dynamic>.from(parsed);
      } else {
        // Data null - berarti belum pernah mengisi kuisioner
        // Langsung coba ambil form kosong untuk dialihkan ke halaman isi kuisioner
        await _loadEmptyForm();
      }
    } on ApiException catch (e) {
      debugPrint("API Error: ${e.message}");

      if (e.statusCode == 404 && mounted) {
        // 404 = belum pernah isi kuisioner, coba ambil form kosong
        await _loadEmptyForm();
      } else if (mounted) {
        setState(() => loadError = e.message);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint("Error loading survey data: $e");
      // Kalau gagal ambil data, coba ambil form kosong untuk isi baru
      await _loadEmptyForm();
    } finally {
      if (mounted && isLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadEmptyForm() async {
    try {
      final formData = await _editService.getSurveyFormKosong(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
      );

      if (formData != null && mounted) {
        setState(() {
          surveyData = formData;
          isNewSurvey = true;
        });
      } else if (mounted) {
        setState(() => loadError = "Form kuisioner tidak ditemukan");
      }
    } catch (e) {
      debugPrint("Gagal mengambil form kosong: $e");
      if (mounted) {
        setState(() => loadError = "Gagal memuat form kuisioner");
      }
    }
  }

  // ── SAVE ─────────────────────────────────────────────────
  Future<void> _submitChanges() async {
    if (surveyData == null) return;
    setState(() => isSaving = true);

    if (isNewSurvey) {
      final surveyId =
          surveyData!.survey?.id ??
          (surveyData!.pages.isNotEmpty
              ? surveyData!.pages.first.surveyId
              : null);

      if (surveyId == null || surveyId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data ID Survey tidak lengkap")),
        );
        setState(() => isSaving = false);
        return;
      }

      try {
        final success = await _editService.submitNewAnswer(
          clientSlug: widget.clientSlug,
          projectSlug: widget.projectSlug,
          surveyId: surveyId,
          pages: surveyData!.pages,
          currentAnswers: answers,
        );

        if (!mounted) return;

        if (success) {
          originalAnswers = Map<int, dynamic>.from(answers);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Kuisioner berhasil dikirim")),
          );
          setState(() => isNewSurvey = false);
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mengirim kuisioner")),
          );
        }
      } catch (e) {
        debugPrint("Error submit new: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
        }
      } finally {
        setState(() => isSaving = false);
      }
    } else {
      // GUNAKAN PATCH / EDIT
      final targetResponseId = widget.responseId > 0
          ? widget.responseId
          : (_activeResponseId ?? 0);

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
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal menyimpan jawaban")),
          );
        }
      } catch (e) {
        debugPrint("Error submit edit: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
        }
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Cek / Edit Survey",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.monGreenMid),
          ),
        ),
      );
    }

    if (surveyData == null || surveyData!.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Cek / Edit Survey",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  loadError ?? "Data tidak ditemukan",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allQuestions = [
      for (final page in surveyData!.pages) ...page.questions,
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isNewSurvey ? "Isi Kuisioner" : "Cek / Edit Survey",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.monGreenMid,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: allQuestions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _buildQuestionItem(allQuestions[index]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isSaving ? null : _submitChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.monGreenMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isNewSurvey ? "Kirim Jawaban" : "Simpan Jawaban",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── ANSWER INPUT ──────────────────────────────────────────

  Widget _buildQuestionItem(SurveyQuestionData q) {
    Widget content;
    switch (q.typeString) {
      case 'radio':
        content = _buildRadio(q);
        break;
      case 'checkbox':
        content = _buildCheckbox(q);
        break;
      case 'dropdown':
        content = _buildDropdown(q);
        break;
      case 'text':
      case 'number':
      case 'paragraph':
        content = _buildTextField(q);
        break;
      case 'matrix':
        content = _buildMatrix(q);
        break;
      default:
        content = const SizedBox();
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      color: Colors.white,
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }

  Widget _buildLabel(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q.plainText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRadio(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        ...q.choices.map((opt) {
          final isSelected = answers[q.id]?.toString() == opt.id.toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? AppTheme.monGreenMid.withOpacity(0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppTheme.monGreenMid : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: RadioListTile<String>(
              value: opt.id.toString(),
              groupValue: answers[q.id]?.toString(),
              onChanged: (val) => setState(() => answers[q.id] = val),
              title: Text(opt.value, style: const TextStyle(fontSize: 12)),
              activeColor: AppTheme.monGreenMid,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
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
          final isSelected = selected.contains(optId);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? AppTheme.monGreenMid.withOpacity(0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppTheme.monGreenMid : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  final updated = List<String>.from(selected);
                  val == true ? updated.add(optId) : updated.remove(optId);
                  answers[q.id] = updated;
                });
              },
              title: Text(opt.value, style: const TextStyle(fontSize: 12)),
              activeColor: AppTheme.monGreenMid,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              controlAffinity: ListTileControlAffinity.trailing,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDropdown(SurveyQuestionData q) {
    final dropdownItems = q.choices
        .map(
          (opt) => DropdownMenuItem(
            value: opt.id.toString(),
            child: Text(opt.value, style: const TextStyle(fontSize: 12)),
          ),
        )
        .toList();

    // Safety Check: Pastikan 'value' yang diberikan ada di dalam list 'items'.
    // Jika tidak ada, paksa 'value' jadi null supaya tidak crash (Assertion Error).
    final String? currentValue = answers[q.id]?.toString();
    final bool valueExists = dropdownItems.any(
      (item) => item.value == currentValue,
    );
    final String? safeValue = valueExists ? currentValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        DropdownButtonFormField<String>(
          value: safeValue,
          items: dropdownItems,
          onChanged: (val) => setState(() => answers[q.id] = val),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.monGreenMid,
          ),
          dropdownColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildTextField(SurveyQuestionData q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        TextFormField(
          initialValue: answers[q.id]?.toString() ?? '',
          keyboardType: q.typeString == 'number'
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: q.typeString == 'paragraph' ? 5 : 1,
          onChanged: (val) => answers[q.id] = val,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: "Masukkan jawaban Anda disini...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.monGreenMid,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrix(SurveyQuestionData q) {
    if (q.matrixRows.isEmpty || q.matrixColumns.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(q),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Data matrix tidak tersedia',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(q),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            columnWidths: {
              0: const FlexColumnWidth(2), // Row labels
              for (int i = 0; i < q.matrixColumns.length; i++)
                i + 1: const FlexColumnWidth(1),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey[100]!, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[50]),
                children: [
                  const Padding(padding: EdgeInsets.all(12), child: SizedBox()),
                  ...q.matrixColumns.map(
                    (col) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        col.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Data Rows
              ...q.matrixRows.asMap().entries.map((rowEntry) {
                final rowIndex = rowEntry.key;
                final row = rowEntry.value;
                final currentMap = answers[q.id] is Map
                    ? Map<int, dynamic>.from(answers[q.id] as Map)
                    : <int, dynamic>{};

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ...q.matrixColumns.asMap().entries.map((colEntry) {
                      final colIndex = colEntry.key;
                      Widget input;

                      if (q.matrixType == 'radio') {
                        input = Radio<int>(
                          value: colIndex,
                          groupValue: currentMap[rowIndex] as int?,
                          activeColor: AppTheme.monGreenMid,
                          onChanged: (_) => setState(() {
                            currentMap[rowIndex] = colIndex;
                            answers[q.id] = Map<int, dynamic>.from(currentMap);
                          }),
                        );
                      } else {
                        final rowCols = currentMap[rowIndex] is List
                            ? List<int>.from(currentMap[rowIndex] as List)
                            : <int>[];
                        input = Checkbox(
                          value: rowCols.contains(colIndex),
                          activeColor: AppTheme.monGreenMid,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (checked) => setState(() {
                            if (checked == true) {
                              if (!rowCols.contains(colIndex))
                                rowCols.add(colIndex);
                            } else {
                              rowCols.remove(colIndex);
                            }
                            currentMap[rowIndex] = rowCols;
                            answers[q.id] = Map<int, dynamic>.from(currentMap);
                          }),
                        );
                      }
                      return Center(child: input);
                    }),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
