import 'package:flutter/material.dart';
import '../models/survey_page_model.dart';

class SurveyBuilderProvider extends ChangeNotifier {
  List<SurveyPageModel> pages = [];
  int currentPageIndex = 0;

  // controller = STATE UI → boleh di provider
  final List<List<TextEditingController>> titleControllers = [];
  final List<List<TextEditingController>> questionControllers = [];
  final List<List<List<TextEditingController>>> optionControllers = [];

  SurveyBuilderProvider() {
    _init();
  }

  void _init() {
    addPage();
  }

  SurveyPageModel get currentPage => pages[currentPageIndex];

  // ── ADD PAGE ──
  void addPage() {
    pages.add(SurveyPageModel(
      namaHalaman: "Halaman ${pages.length + 1}",
    ));

    titleControllers.add([]);
    questionControllers.add([]);
    optionControllers.add([]);

    currentPageIndex = pages.length - 1;
    notifyListeners();
  }

  // ── DELETE PAGE ──
  void deletePage(int index) {
    if (pages.length == 1) return;

    for (var c in titleControllers[index]) c.dispose();
    for (var c in questionControllers[index]) c.dispose();
    for (var list in optionControllers[index]) {
      for (var c in list) c.dispose();
    }

    pages.removeAt(index);
    titleControllers.removeAt(index);
    questionControllers.removeAt(index);
    optionControllers.removeAt(index);

    if (currentPageIndex >= pages.length) {
      currentPageIndex = pages.length - 1;
    }

    notifyListeners();
  }

  // ── ADD QUESTION ──
  void addQuestion(String tipe) {
    final page = currentPage;
    page.daftarPertanyaan.add(tipe);

    titleControllers[currentPageIndex]
        .add(TextEditingController(text: "title"));
    questionControllers[currentPageIndex].add(TextEditingController());

    optionControllers[currentPageIndex]
        .add(_hasOptions(tipe) ? [TextEditingController()] : []);

    notifyListeners();
  }

  // ── DELETE QUESTION ──
  void deleteQuestion(int index) {
    pages[currentPageIndex].daftarPertanyaan.removeAt(index);

    titleControllers[currentPageIndex][index].dispose();
    questionControllers[currentPageIndex][index].dispose();
    for (var c in optionControllers[currentPageIndex][index]) {
      c.dispose();
    }

    titleControllers[currentPageIndex].removeAt(index);
    questionControllers[currentPageIndex].removeAt(index);
    optionControllers[currentPageIndex].removeAt(index);

    notifyListeners();
  }

  bool _hasOptions(String tipe) {
    return ["Single Choice", "Multiple Choice", "Dropdown"].contains(tipe);
  }

  @override
  void dispose() {
    for (var page in titleControllers) {
      for (var c in page) c.dispose();
    }
    for (var page in questionControllers) {
      for (var c in page) c.dispose();
    }
    for (var page in optionControllers) {
      for (var list in page) {
        for (var c in list) c.dispose();
      }
    }
    super.dispose();
  }
}