import 'package:flutter/material.dart';
import '../models/survey_model.dart';
import '../service/survey_service.dart';

class ListSurveyProvider extends ChangeNotifier {
  final SurveyService _surveyService = SurveyService();

  List<SurveyModel> surveys      = [];
  bool              loading      = true;
  String?           errorMessage;
  String            searchQuery  = '';

  // ── FILTERED SURVEYS ──
  List<SurveyModel> get filteredSurveys {
    if (searchQuery.isEmpty) return surveys;
    return surveys.where((s) {
      final q = searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          (s.desc?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── FETCH ──
  Future<void> fetchSurveys(String clientSlug, String projectSlug) async {
    try {
      loading      = true;
      errorMessage = null;
      notifyListeners();

      surveys = await _surveyService.getSurveys(clientSlug, projectSlug);
    } catch (e) {
      errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ── SEARCH ──
  void updateSearch(String val) {
    searchQuery = val;
    notifyListeners();
  }

  // ── DELETE (frontend only) ────────────────────────────────
  // Menghapus dari list lokal tanpa call API
  // Ganti dengan API call jika route DELETE sudah tersedia di Laravel
  void deleteSurveyLocal(String surveySlug) {
    surveys.removeWhere((s) => s.slug == surveySlug);
    notifyListeners();
  }
}