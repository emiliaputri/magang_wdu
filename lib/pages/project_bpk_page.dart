import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

import '../models/client_model.dart';
import '../models/project_model.dart';
import 'list_survey_page.dart';

// ── Page ─────────────────────────────────────────────────────────────────────

class ProjectBpkPage extends StatefulWidget {
  final Client client;
  const ProjectBpkPage({super.key, required this.client});

  @override
  State<ProjectBpkPage> createState() => _ProjectBpkPageState();
}

class _ProjectBpkPageState extends State<ProjectBpkPage> {
  static const _green = AppTheme.ijoTerang;
  static const _greenDark = AppTheme.ijoGelap;
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);
  static const _bgPage = Color(0xFFF4F6F8);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late List<Project> _projects;

  @override
  void initState() {
    super.initState();
    _projects = widget.client.projects != null
        ? List.from(widget.client.projects!)
        : [];
  }

  List<Project> get _filtered => _projects
      .where(
        (p) => p.projectName.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: _textDark),
        title: const Text(
          'Detail Klien',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _ClientCard(client: widget.client),
          const SizedBox(height: 24),
          _ProjectsSection(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearch: (v) => setState(() => _searchQuery = v),
            projects: _filtered,
            onProjectTap: (p) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurveyListPage(
                    clientSlug: widget.client.slug ?? '',
                    clientName: widget.client.clientName,
                    projectSlug: p.slug ?? '',
                    projectTitle: p.projectName,
                    clientLogoUrl:
                        widget.client.imageUrl ?? widget.client.image,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        title: 'Tambah Project',
        onSave: (title, desc) {
          setState(() {
            _projects.add(
              Project(id: _projects.length + 1, projectName: title, desc: desc),
            );
          });
        },
      ),
    );
  }

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (_) => _ProjectDialog(
        title: 'Edit Project',
        initialTitle: project.projectName,
        initialDesc: project.desc ?? '',
        onSave: (title, desc) {
          setState(() {
            final idx = _projects.indexOf(project);
            if (idx != -1) {
              _projects[idx] = project.copyWith(projectName: title, desc: desc);
            }
          });
        },
      ),
    );
  }

  void _showDeleteConfirm(Project project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Project?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Project "${project.projectName}" akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() => _projects.remove(project));
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Client Card ───────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  static const _green = AppTheme.ijoTerang;
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  final Client client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final url = client.imageUrl ?? client.image;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Logo placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: url != null && url.isNotEmpty
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.account_balance,
                      size: 36,
                      color: Color(0xFFBDBDBD),
                    ),
                  )
                : const Icon(
                    Icons.account_balance,
                    size: 36,
                    color: Color(0xFFBDBDBD),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.clientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  client.alamat ?? 'No address available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Projects Section ──────────────────────────────────────────────────────────

class _ProjectsSection extends StatelessWidget {
  static const _green = AppTheme.ijoTerang;
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final List<Project> projects;
  final void Function(Project) onProjectTap;

  const _ProjectsSection({
    required this.searchController,
    required this.searchQuery,
    required this.onSearch,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                Text(
                  '${projects.length} project ditemukan',
                  style: const TextStyle(fontSize: 11, color: _textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Search + Add ──
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Cari project...',
                    hintStyle: TextStyle(color: _textGrey, fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 18, color: _textGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Table ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                // Table header
                Container(
                  color: _green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: const [
                      SizedBox(width: 28),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                          icon: Icons.assignment_outlined,
                          label: 'JUDUL PROJECT',
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                          icon: Icons.notes_outlined,
                          label: 'DESKRIPSI',
                        ),
                      ),
                    ],
                  ),
                ),

                // Rows
                if (projects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Tidak ada project ditemukan.',
                        style: TextStyle(color: _textGrey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...projects.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final project = entry.value;
                    return _ProjectRow(
                      project: project,
                      index: idx,
                      isLast: idx == projects.length - 1,
                      onTap: () => onProjectTap(project),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header Cell ───────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderCell({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Project Row ───────────────────────────────────────────────────────────────

class _ProjectRow extends StatelessWidget {
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  final Project project;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.project,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${project.id ?? index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _textGrey,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Title
              Expanded(
                flex: 5,
                child: Text(
                  project.projectName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    height: 1.4,
                  ),
                ),
              ),

              // Description
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    project.desc ?? '-',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textGrey,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Project Dialog ────────────────────────────────────────────────────────────

class _ProjectDialog extends StatefulWidget {
  final String title;
  final String initialTitle;
  final String initialDesc;
  final void Function(String title, String desc) onSave;

  const _ProjectDialog({
    required this.title,
    this.initialTitle = '',
    this.initialDesc = '',
    required this.onSave,
  });

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descCtrl = TextEditingController(text: widget.initialDesc);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogField(controller: _titleCtrl, label: 'Judul Project'),
          const SizedBox(height: 12),
          _DialogField(controller: _descCtrl, label: 'Deskripsi', maxLines: 3),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ijoTerang,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            if (_titleCtrl.text.trim().isNotEmpty) {
              widget.onSave(_titleCtrl.text.trim(), _descCtrl.text.trim());
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _DialogField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.ijoTerang, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProjectBpkPage(client: Client(clientName: 'Demo Client')),
    ),
  );
}
