import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage.dart';
import '../../service/submission_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  final SpeechToText _speech = SpeechToText();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isSubmitting = false; // Untuk loading overlay saat submit
  DateTime _startTime = DateTime.now(); // Untuk menghitung lama pengerjaan
  String? _errorMessage;
  SurveySubmissionData? _data;

  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _answers = {};
  final Map<int, Uint8List> _attachmentBytes = {}; // Store bytes for web upload
  final Map<int, String> _attachmentBlobUrls =
      {}; // Store blob URLs for web preview
  final Map<int, int> _pageJumpHistory =
      {}; // Maps: targetPageIndex -> sourcePageIndex
  final Map<int, String?> _errors = {}; // Maps: questionId -> error message

  // ── LOCATION DROPDOWN STATE ──
  final Map<int, List<Map<String, dynamic>>> _citiesData = {};
  final Map<int, List<Map<String, dynamic>>> _districtsData = {};
  final Map<int, List<Map<String, dynamic>>> _villagesData = {};
  final Map<int, bool> _locationLoading = {};
  List<Map<String, dynamic>>? _wilayahProvinces;

  int _currentPageIndex = 0;
  late PageController _pageController;
  bool _hasDraft = false;

  bool _isListening = false;
  String _voiceResult = '';
  String? _voiceNotePath;
  bool _isPlayingVoice = false;
  Duration _voiceDuration = Duration.zero;

  String _normalizeName(String name) {
    if (name.isEmpty) return '';
    return name
        .toLowerCase()
        .replaceFirst(RegExp(r'^kota '), '')
        .replaceFirst(RegExp(r'^kabupaten '), '')
        .replaceFirst(RegExp(r'^kab\. '), '')
        .trim();
  }

  Future<void> _fetchCitiesAndRegencies(
    int questionId,
    dynamic provinceId,
  ) async {
    if (provinceId == null) return;

    // Cari nama provinsi dari list internal kita (_provinces)
    final province = _provinces.find(
      (p) => p['id'].toString() == provinceId.toString(),
    );
    if (province == null) return;

    setState(() => _locationLoading[questionId] = true);
    try {
      // 1. Ambil list provinsi dari emsifa untuk mencocokkan nama dengan ID emsifa
      if (_wilayahProvinces == null || _wilayahProvinces!.isEmpty) {
        _wilayahProvinces = await _service.getWilayahProvinces();
      }

      final normalizedProvince = _normalizeName(province['name']);
      final wProv = _wilayahProvinces?.find(
        (p) => _normalizeName(p['name']) == normalizedProvince,
      );

      if (wProv == null) {
        debugPrint(
          "Provinsi tidak ditemukan di API emsifa: $normalizedProvince",
        );
        return;
      }

      // 2. Fetch kota menggunakan ID emsifa (wProv['id'])
      final cities = await _service.getCitiesAndRegencies(wProv['id']);
      setState(() {
        _citiesData[questionId] = cities;
      });
    } finally {
      setState(() => _locationLoading[questionId] = false);
    }
  }

  Future<void> _fetchDistricts(int questionId, dynamic cityId) async {
    if (cityId == null) return;

    setState(() => _locationLoading[questionId] = true);
    try {
      final districts = await _service.getWilayahDistricts(cityId);
      setState(() {
        _districtsData[questionId] = districts;
      });
    } finally {
      setState(() => _locationLoading[questionId] = false);
    }
  }

  Future<void> _fetchVillages(int questionId, dynamic districtId) async {
    if (districtId == null) return;
    setState(() => _locationLoading[questionId] = true);
    try {
      final villages = await _service.getWilayahVillages(districtId);
      setState(() {
        _villagesData[questionId] = villages;
      });
    } finally {
      setState(() => _locationLoading[questionId] = false);
    }
  }

  List<Map<String, dynamic>> get _provinces {
    // Use API data if available
    if (_data?.provinceTargets != null && _data!.provinceTargets.isNotEmpty) {
      return _data!.provinceTargets
          .map((p) => {'id': p.provinceId.toString(), 'name': p.provinceName})
          .toList();
    }
    return [];
  }

  // ── SKIP LOGIC HELPERS ──

  bool _validateCurrentPage() {
    final currentPage = _visiblePages[_currentPageIndex];
    bool hasAnyError = false;

    // Create a temporary map to hold new errors for this page
    final Map<int, String?> newErrors = {};

    for (var q in currentPage.questions) {
      if (!_isQuestionVisible(q)) continue;

      if (q.required) {
        if (q.typeString == 'info') {
          _errors.remove(q.id);
          continue;
        }

        final answer = _answers[q.id];
        bool isValid = false;

        if (answer != null) {
          if (answer is String) {
            isValid = answer.trim().isNotEmpty;
          } else if (answer is List) {
            isValid = answer.isNotEmpty;
          } else if (answer is Map) {
            if (q.typeString == 'matrix') {
              if (q.matrixRows.isNotEmpty) {
                isValid = answer.keys.length == q.matrixRows.length;
              } else {
                isValid = true;
              }
            } else {
              isValid = answer.isNotEmpty;
            }
          } else {
            isValid = answer.toString().trim().isNotEmpty;
          }
        }

        if (!isValid) {
          newErrors[q.id] = 'Pertanyaan ini wajib diisi';
          hasAnyError = true;
        }
      }
    }

    setState(() {
      // Clear old errors for this page and apply new ones
      for (var q in currentPage.questions) {
        _errors.remove(q.id);
      }
      _errors.addAll(newErrors);
    });

    return !hasAnyError;
  }

  bool _isQuestionVisible(SurveyQuestionData q) {
    // ── HARDCODED CASCADING REGION LOGIC ──
    // Sembunyikan pertanyaan Kota/Kecamatan/Desa jika induknya belum diisi
    if (_isCityQuestion(q)) {
      final prevProv = _findPreviousQuestion(q, _isProvinceQuestion);
      if (prevProv != null &&
          (_answers[prevProv.id] == null ||
              _answers[prevProv.id].toString().isEmpty)) {
        return false;
      }
    } else if (_isDistrictQuestion(q)) {
      final prevCity = _findPreviousQuestion(q, _isCityQuestion);
      if (prevCity != null &&
          (_answers[prevCity.id] == null ||
              _answers[prevCity.id].toString().isEmpty)) {
        return false;
      }
    } else if (_isVillageQuestion(q)) {
      final prevDist = _findPreviousQuestion(q, _isDistrictQuestion);
      if (prevDist != null &&
          (_answers[prevDist.id] == null ||
              _answers[prevDist.id].toString().isEmpty)) {
        return false;
      }
    }

    // 1 = Always Display
    if (q.logicType == '1' || q.logicType.isEmpty) return true;

    // Check if the trigger (parent question) is also visible
    // This handles nested logic where a child should be hidden if its parent is hidden
    if (q.questionChoiceId != null) {
      SurveyQuestionData? parentQuestion;
      try {
        parentQuestion = _data?.pages
            .expand((p) => p.questions)
            .firstWhere(
              (element) =>
                  element.choice.any((c) => c.id == q.questionChoiceId),
            );
      } catch (_) {
        // Parent not found in this survey's pages
      }

      if (parentQuestion != null && !_isQuestionVisible(parentQuestion)) {
        return false;
      }
    }

    final triggerId = q.questionChoiceId;
    if (triggerId == null) return true;

    // Check if triggerId exists in current answers
    bool isTriggered = _answers.values.any((ans) {
      if (ans == null) return false;
      if (ans is List) {
        return ans.contains(triggerId.toString()) || ans.contains(triggerId);
      }
      return ans.toString() == triggerId.toString();
    });

    if (q.logicType == '2') {
      // 2 = Show if triggered
      return isTriggered;
    } else if (q.logicType == '3') {
      // 3 = Hide if triggered
      return !isTriggered;
    }

    return true;
  }

  bool _isPageVisible(SurveyPageData page) {
    // Halaman terlihat jika minimal ada satu pertanyaan yang terlihat
    // Atau jika halaman tersebut tidak punya pertanyaan (tapi ini jarang)
    if (page.questions.isEmpty) return true;
    return page.questions.any((q) => _isQuestionVisible(q));
  }

  bool _isCityQuestion(SurveyQuestionData q) {
    final text = q.questionText.toLowerCase();
    // Harus mengandung kata kota/kabupaten tapi bukan provinsi
    return (text.contains('kota') ||
            text.contains('kabupaten') ||
            text.contains('city') ||
            text.contains('kab.')) &&
        !text.contains('provinsi');
  }

  bool _isDistrictQuestion(SurveyQuestionData q) {
    final text = q.questionText.toLowerCase();
    return text.contains('kecamatan') || text.contains('district');
  }

  bool _isVillageQuestion(SurveyQuestionData q) {
    final text = q.questionText.toLowerCase();
    return text.contains('desa') ||
        text.contains('kelurahan') ||
        text.contains('village');
  }

  SurveyQuestionData? _findPreviousQuestion(
    SurveyQuestionData currentQ,
    bool Function(SurveyQuestionData) test,
  ) {
    if (_data == null) return null;
    SurveyQuestionData? lastMatch;
    for (var page in _data!.pages) {
      for (var q in page.questions) {
        if (q.id == currentQ.id) return lastMatch;
        if (test(q)) lastMatch = q;
      }
    }
    return null;
  }

  SurveyQuestionData? _findNextQuestion(
    SurveyQuestionData currentQ,
    bool Function(SurveyQuestionData) test,
  ) {
    if (_data == null) return null;
    bool found = false;
    for (var page in _data!.pages) {
      for (var q in page.questions) {
        if (found && test(q)) return q;
        if (q.id == currentQ.id) found = true;
      }
    }
    return null;
  }

  void _clearRegionAnswersAfter(SurveyQuestionData currentQ) {
    bool found = false;
    for (var page in _data!.pages) {
      for (var q in page.questions) {
        if (found) {
          if (_isCityQuestion(q) ||
              _isDistrictQuestion(q) ||
              _isVillageQuestion(q)) {
            _answers.remove(q.id);
            _citiesData.remove(q.id);
            _districtsData.remove(q.id);
            _villagesData.remove(q.id);
          }
        }
        if (q.id == currentQ.id) found = true;
      }
    }
  }

  List<SurveyPageData> get _visiblePages {
    if (_data == null) return [];
    return _data!.pages.where(_isPageVisible).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
    _loadData().then((_) => _loadDraftIfExists());
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingVoice = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _loadDraftIfExists() async {
    final draft = await StorageHelper.getDraftSurvey(widget.surveySlug);
    if (draft != null && mounted) {
      final answers = draft['answers'];
      if (answers is Map<int, dynamic>) {
        setState(() {
          _answers.clear();
          _answers.addAll(answers);
          _currentPageIndex = draft['currentPageIndex'] ?? 0;
          _hasDraft = true;
        });

        // Repopulate region data for cascading dropdowns
        _restoreRegionData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ditemukan draft sebelumnya. Jawaban Anda telah dipulihkan.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _restoreRegionData() {
    if (_data == null) return;
    for (var page in _data!.pages) {
      for (var q in page.questions) {
        final val = _answers[q.id];
        if (val == null) continue;

        if (_isProvinceQuestion(q)) {
          final nextCity = _findNextQuestion(q, _isCityQuestion);
          if (nextCity != null) _fetchCitiesAndRegencies(nextCity.id, val);
        } else if (_isCityQuestion(q)) {
          final nextDist = _findNextQuestion(q, _isDistrictQuestion);
          if (nextDist != null) _fetchDistricts(nextDist.id, val);
        } else if (_isDistrictQuestion(q)) {
          final nextVill = _findNextQuestion(q, _isVillageQuestion);
          if (nextVill != null) _fetchVillages(nextVill.id, val);
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

  Widget _buildVoiceNoteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 10),
              const Text(
                "Voice Auto Fill Survey",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Ucapkan jawaban lengkap, sistem akan isi otomatis ke field yang sesuai.",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 15),

          if (_voiceNotePath != null && !_isListening) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _playVoiceNote,
                    icon: Icon(
                      _isPlayingVoice ? Icons.pause_circle : Icons.play_circle,
                      color: AppTheme.monGreenMid,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rekaman Tersimpan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.monTextDark,
                          ),
                        ),
                        Text(
                          _formatDuration(_voiceDuration),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _deleteVoiceNote,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _startVoiceRecording,
                icon: const Icon(Icons.refresh),
                label: const Text('Rekam Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isListening
                    ? _stopVoiceRecording
                    : _startVoiceRecording,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(
                  _isListening
                      ? "Stop Rekam (${_formatDuration(_voiceDuration)})"
                      : "Mulai Rekam",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListening ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          if (_voiceResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Hasil: $_voiceResult",
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _startVoiceAutoFill() async {
    bool available = await _speech.initialize();

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Speech recognition tidak tersedia")),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _voiceResult = '';
    });

    _speech.listen(
      localeId: 'id_ID',
      listenMode: ListenMode.confirmation,
      onResult: (result) {
        setState(() {
          _voiceResult = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopVoiceAutoFill() async {
    await _speech.stop();

    setState(() {
      _isListening = false;
    });

    _autoFillAnswers(_voiceResult);
  }

  void _autoFillAnswers(String text) {
    if (_data == null) return;

    text = text.toLowerCase();

    for (var page in _data!.pages) {
      for (var q in page.questions) {
        final question = q.questionText.toLowerCase();

        if (question.contains("nama")) {
          final nama = _extractAfter(text, "nama");
          if (nama.isNotEmpty) _answers[q.id] = nama;
        } else if (question.contains("umur")) {
          final umur = _extractNumber(text);
          if (umur.isNotEmpty) _answers[q.id] = umur;
        } else if (question.contains("alamat")) {
          final alamat = _extractAfter(text, "alamat");
          if (alamat.isNotEmpty) _answers[q.id] = alamat;
        } else if (question.contains("pekerjaan") ||
            question.contains("kerja")) {
          final kerja = _extractAfter(text, "kerja");
          if (kerja.isNotEmpty) _answers[q.id] = kerja;
        } else if (question.contains("kota")) {
          final kota = _extractAfter(text, "kota");
          if (kota.isNotEmpty) _answers[q.id] = kota;
        }
      }
    }

    setState(() {});
  }

  String _extractAfter(String text, String key) {
    if (!text.contains(key)) return '';

    final split = text.split(key);

    if (split.length < 2) return '';

    return split[1].trim().split(' ').take(3).join(' ');
  }

  String _extractNumber(String text) {
    final reg = RegExp(r'\d+');
    final match = reg.firstMatch(text);

    if (match != null) {
      return match.group(0)!;
    }

    return '';
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startVoiceRecording() async {
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _voiceNotePath = filePath;
        _voiceDuration = Duration.zero;
        _isListening = true;
        _voiceResult = '';
      });

      _updateRecordingDuration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memulai rekaman: $e')));
      }
    }
  }

  void _updateRecordingDuration() async {
    while (_isListening && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isListening && mounted) {
        setState(() {
          _voiceDuration += const Duration(seconds: 1);
        });
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      await _recorder.stop();

      setState(() {
        _isListening = false;
      });

      _autoFillAnswers(_voiceResult);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghentikan rekaman: $e')),
        );
      }
    }
  }

  Future<void> _playVoiceNote() async {
    if (_voiceNotePath == null) return;

    try {
      if (_isPlayingVoice) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(DeviceFileSource(_voiceNotePath!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memutar rekaman: $e')));
      }
    }
  }

  Future<void> _deleteVoiceNote() async {
    if (_voiceNotePath != null) {
      try {
        final file = File(_voiceNotePath!);
        if (await file.exists()) {
          await file.delete();
        }
        await _audioPlayer.stop();
        setState(() {
          _voiceNotePath = null;
          _voiceDuration = Duration.zero;
          _voiceResult = '';
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus rekaman: $e')),
          );
        }
      }
    }
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

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Keluar dari Kuisioner?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda ingin menyimpan jawaban Anda sebagai draft sebelum keluar?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _clearDraft();
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text(
              'Keluar Tanpa Simpan',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveDraft();
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.monGreenMid,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan & Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
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
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.monGreenMid),
                      SizedBox(height: 16),
                      Text(
                        "Sedang Mengirim...",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.monTextDark,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                onTap: () async {
                  if (await _onWillPop()) {
                    if (context.mounted) Navigator.pop(context);
                  }
                },
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
                  fontSize: 12,
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
                        fontSize: 13,
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
                        fontSize: 12,
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
          const Icon(
            Icons.error_outline,
            color: AppTheme.monGreenMid,
            size: 48,
          ),
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
        if (_data?.survey?.isVoiceEnabled == true) _buildVoiceNoteSection(),
        _buildPageIndicator(),
        Expanded(child: _buildQuestionPages()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    final totalPages = _visiblePages.length;
    final progress = totalPages > 0
        ? (_currentPageIndex + 1) / totalPages
        : 0.0;
    final isProgressEnabled = _data?.survey?.isProgressBarEnabled ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Halaman ${_currentPageIndex + 1} dari $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.monTextMid,
                ),
              ),
            ],
          ),
          if (isProgressEnabled) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: AppTheme.monGreenMid,
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionPages() {
    final pages = _data!.pages;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      itemCount: _visiblePages.length,
      itemBuilder: (context, pageIndex) {
        final page = _visiblePages[pageIndex];
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.monTextDark,
                    ),
                  ),
                ),
              ...page.questions.map((q) => _buildQuestionItem(q)),
              const SizedBox(height: 80), // Space for bottom bar
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
                fontSize: 12,
                color: AppTheme.monTextDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final isParagraph = q.typeString == 'paragraph';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isParagraph ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errors[q.id] != null
              ? Colors.red
              : (isParagraph
                    ? AppTheme.monGreenMid.withOpacity(0.3)
                    : Colors.grey.shade200),
          width: _errors[q.id] != null || isParagraph ? 1.5 : 1,
        ),
        boxShadow: isParagraph
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isParagraph ? FontWeight.w700 : FontWeight.w600,
                    color: AppTheme.monTextDark,
                  ),
                ),
              ),
              if (q.required)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (_errors[q.id] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _errors[q.id]!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildAnswerInput(q),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(SurveyQuestionData q) {
    // Prioritaskan tipe 11 (Location Dropdown)
    if (q.questionTypeId == 11) {
      return _buildLocationDropdown(q);
    }

    if (_isProvinceQuestion(q)) {
      return _buildProvinceDropdown(q);
    }
    if (_isCityQuestion(q)) {
      return _buildCityDropdown(q);
    }
    if (_isDistrictQuestion(q)) {
      return _buildDistrictDropdown(q);
    }
    if (_isVillageQuestion(q)) {
      return _buildVillageDropdown(q);
    }
    switch (q.typeString) {
      case 'location_dropdown':
        return _buildLocationDropdown(q);
      case 'phone':
        return _buildPhoneInput(q);
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
      case 'attachment':
        return _buildAttachmentInput(q);
      default:
        return const SizedBox();
    }
  }

  Widget _buildLocationDropdown(SurveyQuestionData q) {
    final Map<String, dynamic> currentAnswer = _answers[q.id] is Map
        ? Map<String, dynamic>.from(_answers[q.id] as Map)
        : {};

    final locationData = currentAnswer['locationDropdown'] is Map
        ? Map<String, dynamic>.from(currentAnswer['locationDropdown'] as Map)
        : {'province': '', 'city': '', 'district': '', 'village': ''};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── PROVINCE ──────────────────────────────────────────
        _buildLocationLabel("Pilih Provinsi"),
        DropdownButtonFormField<String>(
          value: locationData['province']?.toString().isEmpty == true
              ? null
              : locationData['province']?.toString(),
          items: _provinces.map((p) {
            return DropdownMenuItem<String>(
              value: p['id'].toString(),
              child: Text(
                p['name'].toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              locationData['province'] = val ?? '';
              locationData['city'] = '';
              locationData['district'] = '';
              locationData['village'] = '';
              _answers[q.id] = {'locationDropdown': locationData};
              if (val != null && val.isNotEmpty) {
                _fetchCitiesAndRegencies(q.id, val);
                _errors.remove(q.id);
              }
            });
          },
          decoration: _locationInputDecoration("Pilih Provinsi"),
        ),

        // ── CITY / REGENCY ────────────────────────────────────
        if (q.includeCityRegency &&
            locationData['province']?.toString().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildLocationLabel("Pilih Kota/Kabupaten"),
          DropdownButtonFormField<String>(
            value: locationData['city']?.toString().isEmpty == true
                ? null
                : locationData['city']?.toString(),
            items: (_citiesData[q.id] ?? []).map((c) {
              return DropdownMenuItem<String>(
                value: c['id'].toString(),
                child: Text(
                  c['name'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                locationData['city'] = val ?? '';
                locationData['district'] = '';
                locationData['village'] = '';
                _answers[q.id] = {'locationDropdown': locationData};
                if (val != null && val.isNotEmpty) {
                  if (q.includeDistrictVillage) {
                    _fetchDistricts(q.id, val);
                  }
                  _errors.remove(q.id);
                }
              });
            },
            decoration: _locationInputDecoration(
              _locationLoading[q.id] == true
                  ? "Memuat..."
                  : "Pilih Kota/Kabupaten",
            ),
          ),
        ],

        // ── DISTRICT ──────────────────────────────────────────
        if (q.includeDistrictVillage &&
            locationData['city']?.toString().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildLocationLabel("Pilih Kecamatan"),
          DropdownButtonFormField<String>(
            value: locationData['district']?.toString().isEmpty == true
                ? null
                : locationData['district']?.toString(),
            items: (_districtsData[q.id] ?? []).map((d) {
              return DropdownMenuItem<String>(
                value: d['id'].toString(),
                child: Text(
                  d['name'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                locationData['district'] = val ?? '';
                final dist = _districtsData[q.id]?.find(
                  (d) => d['id'].toString() == val.toString(),
                );
                locationData['district_name'] = dist?['name'] ?? '';
                locationData['village'] = '';
                _answers[q.id] = {'locationDropdown': locationData};
                if (val != null && val.isNotEmpty) {
                  _fetchVillages(q.id, val);
                }
              });
            },
            decoration: _locationInputDecoration(
              _locationLoading[q.id] == true ? "Memuat..." : "Pilih Kecamatan",
            ),
          ),
        ],

        // ── VILLAGE ───────────────────────────────────────────
        if (q.includeDistrictVillage &&
            locationData['district']?.toString().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _buildLocationLabel("Pilih Desa/Kelurahan"),
          DropdownButtonFormField<String>(
            value: locationData['village']?.toString().isEmpty == true
                ? null
                : locationData['village']?.toString(),
            items: (_villagesData[q.id] ?? []).map((v) {
              return DropdownMenuItem<String>(
                value: v['name'].toString(),
                child: Text(
                  v['name'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                locationData['village'] = val ?? '';
                _answers[q.id] = {'locationDropdown': locationData};
              });
            },
            decoration: _locationInputDecoration(
              _locationLoading[q.id] == true
                  ? "Memuat..."
                  : "Pilih Desa/Kelurahan",
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppTheme.monTextMid,
        ),
      ),
    );
  }

  InputDecoration _locationInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppTheme.monGreenMid, width: 2),
      ),
    );
  }

  Widget _buildAttachmentInput(SurveyQuestionData q) {
    final filePath = _answers[q.id]?.toString();
    final fileName = filePath != null ? filePath.split('/').last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filePath != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.monGreenPale,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.monGreenMid.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _isAudioFile(filePath)
                      ? Icons.audiotrack
                      : Icons.insert_drive_file,
                  color: AppTheme.monGreenMid,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _answers.remove(q.id);
                    _attachmentBytes.remove(q.id);
                    _attachmentBlobUrls.remove(q.id);
                  }),
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
              ],
            ),
          ),

          // Image Preview
          if (_isImageFile(filePath))
            Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb && _attachmentBytes[q.id] != null
                    ? Image.memory(_attachmentBytes[q.id]!, fit: BoxFit.cover)
                    : Image.file(File(filePath), fit: BoxFit.cover),
              ),
            ),

          // Audio Player for attachment
          if (_isAudioFile(filePath))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _playAttachmentAudio(q.id, filePath),
                    icon: Icon(
                      _isPlayingVoice ? Icons.pause_circle : Icons.play_circle,
                      color: AppTheme.monGreenMid,
                      size: 32,
                    ),
                  ),
                  const Text("Putar Rekaman", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickAttachment(q.id),
            icon: const Icon(Icons.upload_file),
            label: Text(filePath == null ? "Pilih File" : "Ganti File"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.monGreenMid,
              side: const BorderSide(color: AppTheme.monGreenMid),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  bool _isAudioFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp3') ||
        p.endsWith('.wav') ||
        p.endsWith('.m4a') ||
        p.endsWith('.aac') ||
        p.endsWith('.ogg');
  }

  Future<void> _playAttachmentAudio(int qId, String path) async {
    try {
      if (_isPlayingVoice) {
        await _audioPlayer.stop();
      } else {
        if (kIsWeb && _attachmentBlobUrls[qId] != null) {
          await _audioPlayer.play(UrlSource(_attachmentBlobUrls[qId]!));
        } else {
          await _audioPlayer.play(DeviceFileSource(path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memutar audio: $e')));
      }
    }
  }

  Future<void> _pickAttachment(int questionId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? media = await picker.pickMedia();
    if (media != null) {
      setState(() {
        _answers[questionId] = media.path;
        _errors.remove(questionId);
      });
    }
  }

  Widget _buildPhoneInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          if (val.trim().isNotEmpty) _errors.remove(q.id);
        });
      },
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: "Contoh: 08123456789",
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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
          borderSide: const BorderSide(color: AppTheme.monGreenMid, width: 2),
        ),
      ),
    );
  }

  bool _isProvinceQuestion(SurveyQuestionData q) {
    final text = q.questionText.toLowerCase();
    return text.contains('provinsi') || text.contains('province');
  }

  Widget _buildProvinceDropdown(SurveyQuestionData q) {
    // List pilihan bisa dari q.choice (database) atau _provinces (project target)
    final List<DropdownMenuItem<String>> items = q.choice.isNotEmpty
        ? q.choice
              .map(
                (opt) => DropdownMenuItem(
                  value: opt.id.toString(),
                  child: Text(opt.value, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList()
        : _provinces
              .map(
                (p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text(
                    p['name'].toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList();

    if (items.isEmpty) {
      return _buildDropdownInput(q);
    }

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: items,
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          _clearRegionAnswersAfter(q);
          if (val != null) {
            final nextCity = _findNextQuestion(q, _isCityQuestion);
            if (nextCity != null) {
              _fetchCitiesAndRegencies(nextCity.id, val);
            }
          }
          _errors.remove(q.id);
        });
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
        size: 24,
      ),
      elevation: 2,
      dropdownColor: Colors.white,
      decoration: _locationInputDecoration('Pilih provinsi'),
      validator: (val) {
        if (q.required && (val == null || val.isEmpty)) {
          return 'Pilihan ini wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildCityDropdown(SurveyQuestionData q) {
    final cities = _citiesData[q.id] ?? [];

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: cities.map((c) {
        return DropdownMenuItem<String>(
          value: c['id'].toString(),
          child: Text(
            c['name'].toString(),
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          _clearRegionAnswersAfter(q);
          if (val != null) {
            final nextDist = _findNextQuestion(q, _isDistrictQuestion);
            if (nextDist != null) {
              _fetchDistricts(nextDist.id, val);
            }
          }
          _errors.remove(q.id);
        });
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
        size: 24,
      ),
      decoration: _locationInputDecoration(
        _locationLoading[q.id] == true ? "Memuat..." : "Pilih Kota/Kabupaten",
      ),
      validator: (val) {
        if (q.required && (val == null || val.isEmpty)) {
          return 'Pilihan ini wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDistrictDropdown(SurveyQuestionData q) {
    final districts = _districtsData[q.id] ?? [];

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: districts.map((d) {
        return DropdownMenuItem<String>(
          value: d['id'].toString(),
          child: Text(
            d['name'].toString(),
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          _clearRegionAnswersAfter(q);
          if (val != null) {
            final nextVill = _findNextQuestion(q, _isVillageQuestion);
            if (nextVill != null) {
              _fetchVillages(nextVill.id, val);
            }
          }
          _errors.remove(q.id);
        });
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
        size: 24,
      ),
      decoration: _locationInputDecoration(
        _locationLoading[q.id] == true ? "Memuat..." : "Pilih Kecamatan",
      ),
      validator: (val) {
        if (q.required && (val == null || val.isEmpty)) {
          return 'Pilihan ini wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildVillageDropdown(SurveyQuestionData q) {
    final villages = _villagesData[q.id] ?? [];

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: villages.map((v) {
        return DropdownMenuItem<String>(
          value: v['name'].toString(),
          child: Text(
            v['name'].toString(),
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          _errors.remove(q.id);
        });
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
        size: 24,
      ),
      decoration: _locationInputDecoration(
        _locationLoading[q.id] == true ? "Memuat..." : "Pilih Desa/Kelurahan",
      ),
      validator: (val) {
        if (q.required && (val == null || val.isEmpty)) {
          return 'Pilihan ini wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildRadioInput(SurveyQuestionData q) {
    return Column(
      children: q.choice.map((opt) {
        final isSelected = _answers[q.id]?.toString() == opt.id.toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? AppTheme.monGreenPale : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            value: opt.id.toString(),
            groupValue: _answers[q.id]?.toString(),
            onChanged: (val) {
              setState(() {
                _answers[q.id] = val;
                _errors.remove(q.id);
              });
            },
            title: Text(
              opt.value,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF202124)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            activeColor: AppTheme.primary,
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
            color: isSelected ? AppTheme.monGreenPale : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
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
                if (updated.isNotEmpty) {
                  _errors.remove(q.id);
                }
              });
            },
            title: Text(
              opt.value,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF202124)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            activeColor: AppTheme.primary,
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
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          if (val.trim().isNotEmpty) _errors.remove(q.id);
        });
      },
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
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildNumberInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      keyboardType: TextInputType.number,
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          if (val.trim().isNotEmpty) _errors.remove(q.id);
        });
      },
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
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildParagraphInput(SurveyQuestionData q) {
    return TextFormField(
      initialValue: _answers[q.id]?.toString() ?? '',
      maxLines: 4,
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
          if (val.trim().isNotEmpty) _errors.remove(q.id);
        });
      },
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
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildDropdownInput(SurveyQuestionData q) {
    final items = q.choice
        .map(
          (opt) => DropdownMenuItem(
            value: opt.id.toString(),
            child: Text(opt.value, style: const TextStyle(fontSize: 12)),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      value: _answers[q.id]?.toString(),
      items: items,
      onChanged: (val) {
        setState(() {
          _answers[q.id] = val;
        });
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppTheme.monGreenMid,
        size: 24,
      ),
      elevation: 2,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Pilih salah satu',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: BorderSide(color: AppTheme.primary),
        ),
      ),
      validator: (val) {
        if (q.required && (val == null || val.isEmpty)) {
          return 'Pilihan ini wajib diisi';
        }
        return null;
      },
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
        ? Map<String, dynamic>.from(_answers[q.id] as Map)
        : <String, dynamic>{};

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
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...q.matrixRows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            final rowKey = row.id ?? "row-$rowIndex";

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(row.label, style: const TextStyle(fontSize: 11)),
                ),
                ...q.matrixColumns.asMap().entries.map((colEntry) {
                  final colIndex = colEntry.key;

                  if (q.matrixType == 'radio') {
                    return Center(
                      child: Radio<int>(
                        value: colIndex,
                        groupValue: currentMap[rowKey] as int?,
                        activeColor: AppTheme.primary,
                        onChanged: (val) {
                          setState(() {
                            currentMap[rowKey] = val;
                            _answers[q.id] = Map<String, dynamic>.from(
                              currentMap,
                            );
                            if (currentMap.keys.length == q.matrixRows.length) {
                              _errors.remove(q.id);
                            }
                          });
                        },
                      ),
                    );
                  } else {
                    final rowCols = currentMap[rowKey] is List
                        ? List<int>.from(currentMap[rowKey] as List)
                        : <int>[];

                    return Center(
                      child: Checkbox(
                        value: rowCols.contains(colIndex),
                        activeColor: AppTheme.primary,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (!rowCols.contains(colIndex)) {
                                rowCols.add(colIndex);
                              }
                            } else {
                              rowCols.remove(colIndex);
                            }
                            currentMap[rowKey] = rowCols;
                            _answers[q.id] = Map<String, dynamic>.from(
                              currentMap,
                            );
                            if (currentMap.keys.length == q.matrixRows.length) {
                              _errors.remove(q.id);
                            }
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
    final totalPages = _visiblePages.length;
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentPageIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.monGreenMid,
                        side: const BorderSide(color: AppTheme.monGreenMid),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sebelumnya',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                if (_currentPageIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isLastPage ? _submitSurvey : _nextPage,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPageIndex >= _visiblePages.length - 1) {
      return;
    }

    final currentPage = _visiblePages[_currentPageIndex];
    int nextIndx = _currentPageIndex + 1;
    bool flowMatched = false;

    if (currentPage.flow.isNotEmpty) {
      for (var flowData in currentPage.flow) {
        final targetPage = _visiblePages.indexWhere(
          (p) => p.id == flowData.nextPageId,
        );

        if (targetPage == -1) {
          continue;
        }

        bool match = false;
        if (flowData.questionId != null) {
          final answer = _answers[flowData.questionId];

          if (answer != null) {
            if (answer is List) {
              match =
                  answer.contains(flowData.questionChoiceId.toString()) ||
                  answer.contains(flowData.questionChoiceId);
            } else {
              match = answer.toString() == flowData.questionChoiceId.toString();
            }
          }
        } else {
          match = true;
        }

        if (match) {
          nextIndx = targetPage;
          flowMatched = true;
          break;
        }
      }
    }

    if (flowMatched || nextIndx != _currentPageIndex + 1) {
      for (int i = _currentPageIndex + 1; i < nextIndx; i++) {
        final skippedPage = _visiblePages[i];
        for (var q in skippedPage.questions) {
          _answers.remove(q.id);
        }
        _pageJumpHistory.remove(i);
      }
    }

    _pageJumpHistory[nextIndx] = _currentPageIndex;
    setState(() {
      _currentPageIndex = nextIndx;
    });

    if (flowMatched) {
      _pageController.jumpToPage(nextIndx);
    } else {
      _pageController.animateToPage(
        nextIndx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    int prevIndx = _currentPageIndex - 1;
    bool wasJump = false;

    if (_pageJumpHistory.containsKey(_currentPageIndex)) {
      prevIndx = _pageJumpHistory[_currentPageIndex]!;
      wasJump = true;
    }

    if (prevIndx >= 0) {
      setState(() {
        _currentPageIndex = prevIndx;
      });

      if (wasJump) {
        _pageController.jumpToPage(prevIndx);
      } else {
        _pageController.animateToPage(
          prevIndx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> _submitSurvey() async {
    if (!_validateCurrentPage()) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Ambil GPS Location (Optional, timeout 5s)
      double? lat;
      double? lng;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (e) {
        debugPrint("Gagal mengambil GPS: $e");
      }

      final payload = _buildPayload();

      // Hitung durasi pengerjaan
      final duration = DateTime.now().difference(_startTime);

      final success = await _service.submitSurvey(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        answers: payload,
        attachmentBytes: _attachmentBytes,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          await _clearDraft();
          await StorageHelper.deleteDraftPhoto(widget.surveySlug);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kuisioner berhasil dikirim!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal mengirim kuisioner"),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    final Map<String, dynamic> payload = {};

    payload['page'] = _data!.pages.map((page) {
      return {
        'question': page.questions.map((q) => {'id': q.id}).toList(),
        'answer': page.questions.map((q) {
          final answer = _answers[q.id];
          return _buildAnswerValue(q, answer);
        }).toList(),
      };
    }).toList();

    return payload;
  }

  Map<String, dynamic> _buildAnswerValue(SurveyQuestionData q, dynamic answer) {
    // Payload cleansing: If question is hidden by logic, return empty answer
    if (!_isQuestionVisible(q)) {
      switch (q.questionTypeId) {
        case 3: // Checkbox
          return {'checkboxes': []};
        case 9: // Matrix
          return {'matrix': null};
        case 2: // Radio
        case 7: // Dropdown
          return {q.questionTypeId == 2 ? 'radios' : 'dropdowns': ''};
        case 11: // Location Dropdown
          return {'locationDropdown': {}};
        default:
          return {'texts': ''};
      }
    }

    if (answer == null) return {'texts': ''};

    switch (q.questionTypeId) {
      case 1: // Text
      case 8: // Paragraph
        return {'texts': answer.toString()};
      case 2: // Radio
        // Backend menyimpan sebagai integer ID choice
        final radioVal = int.tryParse(answer.toString()) ?? answer;
        return {'radios': radioVal};
      case 7: // Dropdown
        // Backend mencari QuestionChoice berdasarkan ID dan simpan value-nya
        final dropdownVal = int.tryParse(answer.toString()) ?? answer;
        return {'dropdowns': dropdownVal};
      case 3: // Checkbox
        if (answer is List) {
          // Backend simpan setiap checkbox choice_id
          return {
            'checkboxes': answer.map((e) {
              final val = int.tryParse(e.toString());
              return val ?? e;
            }).toList(),
          };
        }
        return {'checkboxes': []};
      case 9: // Matrix
        return {'matrix': _buildMatrixValue(q, answer)};
      case 10: // Attachment
        return {
          'hasFile': true,
          'fileKey': 'file_question_${q.id}',
          'filePath': answer.toString(),
          'fileName': kIsWeb ? answer.toString() : null,
        };
      case 11: // Location Dropdown
        return {
          'locationDropdown': answer is Map
              ? (answer['locationDropdown'] ?? answer)
              : {},
        };
      default:
        return {'texts': answer.toString()};
    }
  }

  dynamic _buildMatrixValue(SurveyQuestionData q, dynamic answer) {
    if (answer is! Map || answer.isEmpty) return null;

    final Map<String, dynamic> result = {};
    answer.forEach((key, value) {
      if (q.matrixType == 'radio') {
        result[key.toString()] = value;
      } else {
        result[key.toString()] = value is List ? value : [];
      }
    });

    return result;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? find(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}
