import 'package:flutter/material.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class Project {
  final int number;
  final String title;
  final String description;

  const Project({
    required this.number,
    required this.title,
    required this.description,
  });
}

// ── Page ─────────────────────────────────────────────────────────────────────

class ProjectBpkPage extends StatefulWidget {
  const ProjectBpkPage({super.key});

  @override
  State<ProjectBpkPage> createState() => _ProjectBpkPageState();
}

class _ProjectBpkPageState extends State<ProjectBpkPage> {
  static const _green = Color(0xFF4CAF50);
  static const _greenDark = Color(0xFF388E3C);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);
  static const _bgPage = Color(0xFFF4F6F8);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Project> _projects = [
    Project(   
      number: 1,
      title: 'Pemeriksaan Keuangan Negara atas LKPP Tahun Anggaran 2025',
      description:
          'Pemeriksaan atas Laporan Keuangan Pemerintah Pusat (LKPP) untuk menilai kewajaran penyajian laporan keuangan tahun anggaran 2025.',
    ),
    Project(
      number: 2,
      title: 'Pemeriksaan Kinerja Program Pengentasan Kemiskinan Nasional 2025',
      description:
          'Evaluasi efektivitas, efisiensi, dan ekonomisasi program pengentasan kemiskinan yang dikelola oleh Kementerian Sosial.',
    ),
    Project(
      number: 3,
      title: 'Pemeriksaan Dengan Tujuan Tertentu atas Pengelolaan Aset Negara',
      description:
          'PDTT atas pengelolaan dan pemanfaatan Barang Milik Negara (BMN) di lingkungan Kementerian PUPR.',
    ),
  ];

  List<Project> get _filtered => _projects
      .where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
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
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const _ClientCard(),
          const SizedBox(height: 24),
          _ProjectsSection(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearch: (v) => setState(() => _searchQuery = v),
            projects: _filtered,
            onAdd: _showAddProjectDialog,
            onEdit: (p) => _showEditProjectDialog(p),
            onDelete: (p) => _showDeleteConfirm(p),
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
            _projects.add(Project(
              number: _projects.length + 1,
              title: title,
              description: desc,
            ));
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
        initialTitle: project.title,
        initialDesc: project.description,
        onSave: (title, desc) {
          setState(() {
            final idx = _projects.indexOf(project);
            if (idx != -1) {
              _projects[idx] = Project(
                number: project.number,
                title: title,
                description: desc,
              );
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
        content: Text('Project "${project.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
  static const _green = Color(0xFF4CAF50);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  const _ClientCard();

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.account_balance,
                size: 36, color: Color(0xFFBDBDBD)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BPK RI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
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
                const Text(
                  'Badan Pemeriksa Keuangan\nRepublik Indonesia',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
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
  static const _green = Color(0xFF4CAF50);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final List<Project> projects;
  final VoidCallback onAdd;
  final void Function(Project) onEdit;
  final void Function(Project) onDelete;

  const _ProjectsSection({
    required this.searchController,
    required this.searchQuery,
    required this.onSearch,
    required this.projects,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                Text(
                  '${projects.length} project ditemukan',
                  style: const TextStyle(fontSize: 12, color: _textGrey),
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
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari project...',
                    hintStyle: TextStyle(color: _textGrey, fontSize: 13),
                    prefixIcon:
                        Icon(Icons.search, size: 18, color: _textGrey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _green,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onAdd,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Tambah Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: const [
                      SizedBox(width: 28),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                            icon: Icons.assignment_outlined,
                            label: 'JUDUL PROJECT'),
                      ),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                            icon: Icons.notes_outlined, label: 'DESKRIPSI'),
                      ),
                      SizedBox(
                        width: 80,
                        child: _HeaderCell(
                            icon: Icons.settings_outlined, label: 'AKSI'),
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
                        style: TextStyle(color: _textGrey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...projects.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final project = entry.value;
                    return _ProjectRow(
                      project: project,
                      isLast: idx == projects.length - 1,
                      onEdit: () => onEdit(project),
                      onDelete: () => onDelete(project),
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
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectRow({
    required this.project,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0))),
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
              '${project.number}',
              style: const TextStyle(
                fontSize: 12,
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
              project.title,
              style: const TextStyle(
                fontSize: 13,
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
                project.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textGrey,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF1976D2),
                  bgColor: const Color(0xFFE3F2FD),
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFD32F2F),
                  bgColor: const Color(0xFFFFEBEE),
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogField(controller: _titleCtrl, label: 'Judul Project'),
          const SizedBox(height: 12),
          _DialogField(
              controller: _descCtrl, label: 'Deskripsi', maxLines: 3),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_titleCtrl.text.trim().isNotEmpty) {
              widget.onSave(
                  _titleCtrl.text.trim(), _descCtrl.text.trim());
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
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF4CAF50), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ── Entry Point ───────────────────────────────────────────────────────────────

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProjectBpkPage(),
  ));
}