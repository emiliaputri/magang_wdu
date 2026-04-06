import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage.dart';
import '../../service/submission_service.dart';

class SubmissionPage extends StatefulWidget {
  final String surveySlug;
  final String clientSlug;
  final String projectSlug;
  final Map<String, dynamic>? biodata;
  final String surveyTitle;

  const SubmissionPage({
    super.key,
    required this.surveySlug,
    required this.clientSlug,
    required this.projectSlug,
    this.biodata,
    this.surveyTitle = '',
  });

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final SubmissionService _service = SubmissionService();

  bool _isLoading = true;
  String? _errorMessage;
  SurveySubmissionData? _data;

  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _answers = {};

  int _currentPageIndex = 0;
  bool _hasDraft = false;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _loadDraftIfExists());
  }

  Future<void> _loadDraftIfExists() async {
    final draft = await StorageHelper.getDraftSurvey(widget.surveySlug);
    if (draft != null && mounted) {
      final answersRaw = draft['answers'];
      if (answersRaw is Map) {
        final converted = <int, dynamic>{};
        answersRaw.forEach((key, value) {
          final intKey = int.tryParse(key.toString()) ?? 0;
          converted[intKey] = value;
        });
        setState(() {
          _answers.clear();
          _answers.addAll(converted);
          _currentPageIndex = draft['currentPageIndex'] ?? 0;
          _hasDraft = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ditemukan draft sebelumnya. Jawaban Anda telah dipulihkan.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveDraft() async {
    await StorageHelper.saveDraftSurvey(
      surveySlug: widget.surveySlug,
      answers: _answers.map((key, value) => MapEntry(key.toString(), value)),
      biodata: widget.biodata ?? {},
      currentPageIndex: _currentPageIndex,
    );
  }

  Future<void> _clearDraft() async {
    await StorageHelper.deleteDraftSurvey(widget.surveySlug);
    setState(() => _hasDraft = false);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getSubmission(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
      );

      if (data != null) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Data tidak ditemukan";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.monBgColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.monGreenMid,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorUI()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final surveyTitle = _data?.survey?.title ?? 'Survey';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.monGreenDark, AppTheme.monGreenMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Text(
                'Isi Kuisioner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surveyTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _data?.project?.projectName ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage ?? "Terjadi kesalahan"),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text("Coba Lagi")),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null || _data!.pages.isEmpty) {
      return const Center(child: Text("Tidak ada pertanyaan"));
    }

    return Column(
      children: [
        _buildPageIndicator(),
        Expanded(child: _buildQuestionPages()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    final totalPages = _data!.pages.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Halaman ${_currentPageIndex + 1} dari $totalPages',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.monTextMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPages() {
    final pages = _data!.pages;

    return PageView.builder(
      itemCount: pages.length,
      onPageChanged: (index) {
        setState(() => _currentPageIndex = index);
      },
      itemBuilder: (context, pageIndex) {
        final page = pages[pageIndex];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (page.pageName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    page.pageName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.monTextDark,
                    ),
                  ),
                ),
              ...page.questions.map((q) => _buildQuestionItem(q)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionItem(SurveyQuestionData q) {
    if (q.typeString == 'info') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.plainText,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.monTextDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.plainText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.monTextDark,
                  ),
                ),
              ),
              if (q.required)
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnswerInput(q),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestionData q) {
    switch (q.typeString) {
      case 'radio':
        return _buildRadioInput(q);
      case 'checkbox':
        return _buildCheckboxInput(q);
      case 'text':
        return _buildTextInput(q);
      case 'number':
        return _buildNumberInput(q);
      case 'paragraph':
        return _buildParagraphInput(q);
      case 'matrix':
        return _buildMatrixInput(q);
      case 'dropdown':
        return _buildDropdownInput(q);
      default:
        return const SizedBox();
    }
  }

  Widget _buildRadioInput(SurveyQuestionData q) {
    return Column(
      children: q.choice.map((opt) {
        final isSelected = _answers[q.id]?.toString() == opt.id.toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4285F4)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            value: opt.id.toString(),
            groupValue: _answers[q.id]?.toString(),
            onChanged: (val) => setState(() => _answers[q.id] = val),
            title: Text(
              opt.value,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? const Color(0xFF202124)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            activeColor: const Color(0xFF4285F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxInput(SurveyQuestionData q) {
    final selected = _answers[q.id] is List
        ? List<String>.from(_answers[q.id])
        : <String>[];

    return Column(
      children: q.choice.map((opt) {
        final isSelected = selected.contains(opt.id.toString());
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4285F4)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                final updated = List<String>.from(selected);
                if (val == true) {
                  updated.add(opt.id.toString());
                } else {
                  updated.remove(opt.id.toString());
                }
                _answers[q.id] = updated;
              });
            },
            title: Text(
              opt.value,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? const Color(0xFF202124)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            activeColor: const Color(0xFF4285F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      onChanged: (val) => _answers[q.id] = val,
      decoration: InputDecoration(
        hintText: "Masukkan jawaban...",
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
          borderSide: const BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
    );
  }

  Widget _buildNumberInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      keyboardType: TextInputType.number,
      onChanged: (val) => _answers[q.id] = val,
      decoration: InputDecoration(
        hintText: "Masukkan angka...",
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
          borderSide: const BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
    );
  }

  Widget _buildParagraphInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      maxLines: 4,
      onChanged: (val) => _answers[q.id] = val,
      decoration: InputDecoration(
        hintText: "Masukkan jawaban...",
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
          borderSide: const BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
    );
  }

  Widget _buildDropdownInput(SurveyQuestionData q) {
    final items = q.choice
        .map(
          (opt) => DropdownMenuItem(
            value: opt.id.toString(),
            child: Text(opt.value),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: items,
      onChanged: (val) => setState(() => _answers[q.id] = val),
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
          borderSide: const BorderSide(color: Color(0xFF4285F4)),
        ),
      ),
    );
  }

  Widget _buildMatrixInput(SurveyQuestionData q) {
    if (q.matrixRows.isEmpty || q.matrixColumns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text("Data matrix tidak tersedia"),
      );
    }

    final currentMap = _answers[q.id] is Map
        ? Map<int, dynamic>.from(_answers[q.id] as Map)
        : <int, dynamic>{};

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(2),
          for (int i = 0; i < q.matrixColumns.length; i++)
            i + 1: const FlexColumnWidth(1),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade50),
            children: [
              const Padding(padding: EdgeInsets.all(12), child: SizedBox()),
              ...q.matrixColumns.map(
                (col) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    col.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...q.matrixRows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(row.label, style: const TextStyle(fontSize: 12)),
                ),
                ...q.matrixColumns.asMap().entries.map((colEntry) {
                  final colIndex = colEntry.key;

                  if (q.matrixType == 'radio') {
                    return Center(
                      child: Radio<int>(
                        value: colIndex,
                        groupValue: currentMap[rowIndex] as int?,
                        activeColor: const Color(0xFF4285F4),
                        onChanged: (val) {
                          setState(() {
                            currentMap[rowIndex] = val;
                            _answers[q.id] = Map<int, dynamic>.from(currentMap);
                          });
                        },
                      ),
                    );
                  } else {
                    final rowCols = currentMap[rowIndex] is List
                        ? List<int>.from(currentMap[rowIndex] as List)
                        : <int>[];

                    return Center(
                      child: Checkbox(
                        value: rowCols.contains(colIndex),
                        activeColor: const Color(0xFF4285F4),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (!rowCols.contains(colIndex))
                                rowCols.add(colIndex);
                            } else {
                              rowCols.remove(colIndex);
                            }
                            currentMap[rowIndex] = rowCols;
                            _answers[q.id] = Map<int, dynamic>.from(currentMap);
                          });
                        },
                      ),
                    );
                  }
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalPages = _data!.pages.length;
    final isFirstPage = _currentPageIndex == 0;
    final isLastPage = _currentPageIndex == totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!isFirstPage)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _currentPageIndex--);
                      _saveDraft();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sebelumnya',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              if (!isFirstPage) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      _submitSurvey();
                    } else {
                      setState(() => _currentPageIndex++);
                      _saveDraft();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.monGreenMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? 'Kirim Jawaban' : 'Selanjutnya',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: _saveDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade700,
                side: BorderSide(color: Colors.orange.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Simpan Draft',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSurvey() async {
    final surveyId = _data?.survey?.id;
    if (surveyId == null || surveyId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ID Survey tidak ditemukan")),
        );
      }
      return;
    }

    try {
      final payload = _buildPayload();

      final success = await _service.submitSurvey(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveyId: surveyId,
        answers: payload,
      );

      if (mounted) {
        if (success) {
          await _clearDraft();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kuisioner berhasil dikirim!"),
              backgroundColor: Colors.green,
            ),
          );
          // Pop with result true so previous pages can refresh status
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal mengirim kuisioner"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {};

    // Tambahkan biodata jika ada
    if (widget.biodata != null && widget.biodata!.isNotEmpty) {
      payload['biodata'] = widget.biodata;
    }

    // Tambahkan jawaban survey
    payload['page'] = _data!.pages.map((page) {
      return {
        'question': page.questions.map((q) {
          return {
            'id': q.id,
            'question_type_id': q.questionTypeId,
            'ans': _buildAnswerValue(q, _answers[q.id]),
          };
        }).toList(),
      };
    }).toList();

    return payload;
  }

  Map<String, dynamic> _buildAnswerValue(SurveyQuestionData q, dynamic answer) {
    if (answer == null) return {'texts': ''};

    switch (q.questionTypeId) {
      case 1: // Text
      case 8: // Paragraph
        return {'texts': answer.toString()};
      case 2: // Radio
      case 7: // Dropdown
        return {'radios': answer.toString()};
      case 3: // Checkbox
        if (answer is List) {
          return {'checkboxes': answer.map((e) => e.toString()).toList()};
        }
        return {'checkboxes': []};
      case 9: // Matrix
        return {'matrix': _buildMatrixValue(q.matrixType, answer)};
      default:
        return {'texts': answer.toString()};
    }
  }

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
}
