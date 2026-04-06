import 'package:flutter/foundation.dart';
import '../models/survey_model.dart';
import '../service/survey_service.dart';
import '../service/edit_answer_service.dart';
import '../core/utils/storage.dart';

class SurveyProvider extends ChangeNotifier {
  final _service = SurveyService();
  final _editService = EditAnswerService();

  // ── STATE ─────────────────────────────────────────────────
  List<SurveyModel> _surveys = [];
  SurveyModel? _selectedSurvey;
  Map<String, dynamic> _surveyDetail = {};
  Map<String, dynamic> _allReport = {};
  Map<String, dynamic> _surveyResponse = {};

  // Map untuk menyimpan status jawaban user per survey slug
  Map<String, bool> _userAnswerStatus = {};

  bool _isLoading = false;
  bool _isLoadingDetail = false;
  bool _isLoadingReport = false;
  bool _isLoadingResponse = false;
  String? _errorMessage;

  // ── GETTERS ───────────────────────────────────────────────
  List<SurveyModel> get surveys => _surveys;
  SurveyModel? get selectedSurvey => _selectedSurvey;
  Map<String, dynamic> get surveyDetail => _surveyDetail;
  Map<String, dynamic> get allReport => _allReport;
  Map<String, dynamic> get surveyResponse => _surveyResponse;

  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingReport => _isLoadingReport;
  bool get isLoadingResponse => _isLoadingResponse;
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;
  bool get isEmpty => _surveys.isEmpty && !_isLoading;

  // Getter untuk status jawaban user per survey
  bool hasUserAnswered(String surveySlug) =>
      _userAnswerStatus[surveySlug] ?? false;

  // ── LOAD SURVEYS ──────────────────────────────────────────
  Future<void> loadSurveys(
    String clientSlug,
    String projectSlug, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _surveys = await _service.getSurveys(clientSlug, projectSlug);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── CEK STATUS JAWABAN USER PER SURVEY ───────────────────────
  Future<void> loadUserAnswerStatus(
    String clientSlug,
    String projectSlug,
  ) async {
    try {
      final userIdStr = await StorageHelper.getUserId();
      final userId = int.tryParse(userIdStr ?? '') ?? 0;

      if (userId == 0) return;

      for (final survey in _surveys) {
        try {
          final hasAnswered = await _editService.hasUserAnswered(
            clientSlug: clientSlug,
            projectSlug: projectSlug,
            surveySlug: survey.slug,
            userId: userId,
          );
          _userAnswerStatus[survey.slug] = hasAnswered;
        } catch (e) {
          _userAnswerStatus[survey.slug] = false;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user answer status: $e');
    }
  }

  // ── UPDATE STATUS SETELAH SUBMIT ──────────────────────────────
  void updateAnswerStatus(String surveySlug, bool hasAnswered) {
    _userAnswerStatus[surveySlug] = hasAnswered;
    notifyListeners();
  }

  // ── LOAD SURVEY DETAIL ────────────────────────────────────
  Future<void> loadSurveyDetail(
    String clientSlug,
    String projectSlug,
    String surveySlug,
  ) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _surveyDetail = await _service.getSurveyDetail(
        clientSlug,
        projectSlug,
        surveySlug,
      );
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // ── LOAD ALL REPORT ───────────────────────────────────────
  Future<void> loadAllReport(
    String clientSlug,
    String projectSlug,
    String surveySlug,
  ) async {
    _isLoadingReport = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allReport = await _service.getSurveyAllReport(
        clientSlug,
        projectSlug,
        surveySlug,
      );
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingReport = false;
      notifyListeners();
    }
  }

  // ── LOAD SURVEY RESPONSE ──────────────────────────────────
  Future<void> loadSurveyResponse(
    String clientSlug,
    String projectSlug,
    String surveySlug,
    int responseId,
  ) async {
    _isLoadingResponse = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _surveyResponse = await _service.getSurveyResponse(
        clientSlug,
        projectSlug,
        surveySlug,
        responseId,
      );
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoadingResponse = false;
      notifyListeners();
    }
  }

  // ── SELECT SURVEY ─────────────────────────────────────────
  void selectSurvey(SurveyModel survey) {
    _selectedSurvey = survey;
    notifyListeners();
  }

  // ── CLEAR / RESET ─────────────────────────────────────────
  void clearSurveys() {
    _surveys = [];
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── HELPER ────────────────────────────────────────────────
  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('NetworkException')) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    }
    if (msg.contains('401')) return 'Sesi habis. Silakan login ulang.';
    if (msg.contains('403')) return 'Anda tidak memiliki akses.';
    if (msg.contains('404')) return 'Data tidak ditemukan.';
    if (msg.contains('500')) return 'Terjadi kesalahan pada server.';
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
