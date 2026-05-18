import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import 'submission_page.dart';
import 'biodata_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => ArchivePageState();
}

class ArchivePageState extends State<ArchivePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void reloadDrafts() => _loadDrafts();

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final List<Map<String, dynamic>> loadedDrafts = [];

    for (String key in keys) {
      if (key.startsWith('draft_survey_')) {
        final surveySlug = key.replaceFirst('draft_survey_', '');
        final raw = prefs.getString(key);
        String? clientSlug;
        String? projectSlug;
        if (raw != null) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            clientSlug = data['clientSlug'] as String?;
            projectSlug = data['projectSlug'] as String?;
          } catch (_) {}
        }
        loadedDrafts.add({
          'key': key,
          'type': 'survey',
          'slug': surveySlug,
          'clientSlug': clientSlug,
          'projectSlug': projectSlug,
          'title': 'Draf Kuisioner | $surveySlug',
          'description': 'Draf pengisian jawaban kuisioner tersimpan.',
          'icon': Icons.assignment_late_rounded,
        });
      } else if (key.startsWith('draft_biodata_')) {
        final surveySlug = key.replaceFirst('draft_biodata_', '');
        final raw = prefs.getString(key);
        String? clientSlug;
        String? projectSlug;
        if (raw != null) {
          try {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            clientSlug = data['clientSlug'] as String?;
            projectSlug = data['projectSlug'] as String?;
          } catch (_) {}
        }
        loadedDrafts.add({
          'key': key,
          'type': 'biodata',
          'slug': surveySlug,
          'clientSlug': clientSlug,
          'projectSlug': projectSlug,
          'title': 'Draf Biodata | $surveySlug',
          'description': 'Draf pengisian profil / biodata responden.',
          'icon': Icons.person_pin_rounded,
        });
      }
    }

    setState(() {
      _drafts = loadedDrafts;
      _isLoading = false;
    });
  }

  void _openDraft(Map<String, dynamic> draft) {
    final slug = draft['slug'] as String;
    final clientSlug = draft['clientSlug'] as String?;
    final projectSlug = draft['projectSlug'] as String?;

    if (clientSlug == null || projectSlug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data draft tidak lengkap'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (draft['type'] == 'survey') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubmissionPage(
            surveySlug: slug,
            clientSlug: clientSlug,
            projectSlug: projectSlug,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BiodataPage(
            surveySlug: slug,
            clientSlug: clientSlug,
            projectSlug: projectSlug,
          ),
        ),
      );
    }
  }

  Future<void> _deleteDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    _loadDrafts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draf berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.ijoGelap, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 28,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.archive_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arsip',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Draf yang tersimpan',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _drafts.isEmpty
                ? _buildEmptyState()
                : _buildDraftList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Draf',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum memiliki draf biodata atau kuisioner.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: _drafts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.onSurface.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _openDraft(draft),
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: draft['type'] == 'survey'
                    ? const Color(0xFF006A36).withOpacity(0.1)
                    : const Color(0xFF00838F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                draft['icon'],
                color: draft['type'] == 'survey'
                    ? const Color(0xFF006A36)
                    : const Color(0xFF00838F),
              ),
            ),
            title: Text(
              draft['title'],
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            subtitle: Text(
              draft['description'],
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppTheme.outline,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteDraft(draft['key']);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Hapus Draf', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
