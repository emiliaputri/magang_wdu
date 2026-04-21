import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage.dart';
import '../../service/submission_service.dart';
import 'dart:convert';
import 'dart:io';

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
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;
  SurveySubmissionData? _data;

  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _answers = {};

  int _currentPageIndex = 0;
  bool _hasDraft = false;

  String? _voiceNotePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _loadDraftIfExists());
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
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

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan untuk merekam'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _voiceNotePath = filePath;
        _recordingDuration = Duration.zero;
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
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      setState(() {
        _isRecording = false;
      });
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
      if (_isPlaying) {
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
          _recordingDuration = Duration.zero;
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

  Widget _buildVoiceNoteSection() {
    return Container(
      margin: const EdgeInsets.all(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.monGreenMid.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: AppTheme.monGreenMid,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Voice Note',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.monTextDark,
                  ),
                ),
              ),
              if (_voiceNotePath != null && !_isRecording)
                IconButton(
                  onPressed: _deleteVoiceNote,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rekam suara jika malas mengetik',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (_voiceNotePath != null && !_isRecording)
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
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
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
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_isRecording)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Merekam...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          _formatDuration(_recordingDuration),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _stopRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            )
          else
            Center(
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.monGreenMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.mic),
                label: const Text('Mulai Rekam'),
              ),
            ),
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
            onPressed: () => Navigator.pop(context, true),
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
      child: Scaffold(
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
        _buildVoiceNoteSection(),
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
              fontSize: 12,
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
                      fontSize: 12,
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
                fontSize: 12,
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
                    fontSize: 12,
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
                fontSize: 12,
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
                fontSize: 12,
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
              if (!isFirstPage && !isLastPage)
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
              if (!isFirstPage && !isLastPage) const SizedBox(width: 12),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    try {
      final payload = _buildPayload();

      final success = await _service.submitSurvey(
        clientSlug: widget.clientSlug,
        projectSlug: widget.projectSlug,
        surveySlug: widget.surveySlug,
        answers: payload,
      );

      if (mounted) {
        if (success) {
          await _clearDraft();
          await StorageHelper.deleteDraftPhoto(widget.surveySlug);
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

    if (widget.biodata != null && widget.biodata!.isNotEmpty) {
      payload['biodata'] = widget.biodata;
    }

    if (_voiceNotePath != null) {
      payload['voice_note'] = _voiceNotePath;
    }

    payload['page'] = _data!.pages.map((page) {
      return {
        'question': page.questions.map((q) => {'id': q.id}).toList(),
        'answer': page.questions
            .map((q) => _buildAnswerValue(q, _answers[q.id]))
            .toList(),
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
        return {'answe': _buildMatrixValue(q.matrixType, answer)};
      default:
        return {'texts': answer.toString()};
    }
  }

  dynamic _buildMatrixValue(String matrixType, dynamic answer) {
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
}
