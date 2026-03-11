import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../service/dummy_survey.dart';
import '../models/survey_question.dart';

class CekEditMonitorPage extends StatefulWidget {
  final String surveyId;
  final String clientSlug;
  final String projectSlug;

  const CekEditMonitorPage({
    super.key,
    required this.surveyId,
    required this.clientSlug,
    required this.projectSlug,
  });

  @override
  State<CekEditMonitorPage> createState() => _CekEditMonitorPageState();
}

class _CekEditMonitorPageState extends State<CekEditMonitorPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> answers = {};
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOut,
        ),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          itemCount: dummySurvey.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            SurveyQuestion q = dummySurvey[index];
            return _buildQuestionCard(q, index);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.monGreenMid,
              elevation: 4,
              shadowColor: AppTheme.monGreenMid.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
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
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion q, int index) {
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
            // Header Pertanyaan
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
                      q.title,
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

            // Body Jawaban
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAnswerInput(q),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestion q) {
    if (q.type == "radio") {
      return Column(
        children: q.options.map((opt) {
          bool isSelected = answers[q.id] == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => answers[q.id] = opt),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.monGreenPale
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.monGreenMid
                        : Colors.grey.shade300,
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
                        opt,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.monTextDark
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
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

    if (q.type == "dropdown") {
      return DropdownButtonFormField<String>(
        value: answers[q.id],
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppTheme.monGreenMid,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
            borderSide: const BorderSide(
              color: AppTheme.monGreenMid,
              width: 1.5,
            ),
          ),
        ),
        hint: const Text("Pilih salah satu..."),
        items: q.options.map((opt) {
          return DropdownMenuItem(value: opt, child: Text(opt));
        }).toList(),
        onChanged: (val) {
          setState(() {
            answers[q.id] = val;
          });
        },
      );
    }

    if (q.type == "checkbox") {
      answers[q.id] ??= [];
      List<String> selected = List<String>.from(answers[q.id] ?? []);

      return Column(
        children: q.options.map((opt) {
          bool isChecked = selected.contains(opt);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isChecked) {
                    selected.remove(opt);
                  } else {
                    selected.add(opt);
                  }
                  answers[q.id] = selected;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isChecked ? AppTheme.monGreenPale : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isChecked
                        ? AppTheme.monGreenMid
                        : Colors.grey.shade300,
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
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isChecked
                              ? AppTheme.monTextDark
                              : Colors.grey.shade700,
                          fontWeight: isChecked
                              ? FontWeight.w500
                              : FontWeight.normal,
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

    return const SizedBox();
  }

  void _handleSave() {
    print(answers);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Perubahan berhasil disimpan!"),
          ],
        ),
        backgroundColor: AppTheme.monGreenMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }
}
