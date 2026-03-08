import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../pages/list_survey_page.dart'; // ✅ tambah import

class ProjectListPage extends StatefulWidget {
  final Client client; // ✅ client diteruskan dari luar, tidak rely pada project.client

  const ProjectListPage({super.key, required this.client});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  static const _green    = Color(0xFF4CAF50);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);
  static const _bgPage   = Color(0xFFF4F6F8);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Project> get _projects => widget.client.projects ?? [];

  List<Project> get _filtered => _projects
      .where((p) =>
          p.projectName.toLowerCase().contains(_searchQuery.toLowerCase()))
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
          _ClientCard(client: widget.client),
          const SizedBox(height: 24),
          _ProjectsSection(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearch: (v) => setState(() => _searchQuery = v),
            projects: _filtered,
            client: widget.client, // ✅ teruskan client ke section
          ),
        ],
      ),
    );
  }
}

// ── Client Card ───────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final Client client;

  static const _green    = Color(0xFF4CAF50);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  const _ClientCard({required this.client});

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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: client.image != null
                ? Image.network(
                    client.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.business,
                      size: 36,
                      color: Color(0xFFBDBDBD),
                    ),
                  )
                : const Icon(
                    Icons.business,
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
                if (client.desc != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    client.desc!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (client.alamat != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: _textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.alamat!,
                          style: const TextStyle(
                              fontSize: 12, color: _textGrey, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
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
  static const _green    = Color(0xFF4CAF50);
  static const _textDark = Color(0xFF1A2340);
  static const _textGrey = Color(0xFF7A869A);

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final List<Project> projects;
  final Client client; // ✅ terima client

  const _ProjectsSection({
    required this.searchController,
    required this.searchQuery,
    required this.onSearch,
    required this.projects,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  '${projects.length} project found',
                  style: const TextStyle(fontSize: 12, color: _textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Search ──
        Container(
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
              hintText: 'Search projects...',
              hintStyle: TextStyle(color: _textGrey, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 18, color: _textGrey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
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
                Container(
                  color: _green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      SizedBox(width: 28),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                            icon: Icons.assignment_outlined,
                            label: 'PROJECT NAME'),
                      ),
                      Expanded(
                        flex: 5,
                        child: _HeaderCell(
                            icon: Icons.notes_outlined,
                            label: 'DESCRIPTION'),
                      ),
                      SizedBox(
                        width: 80,
                        child: _HeaderCell(
                            icon: Icons.list_alt_outlined,
                            label: 'SURVEYS'),
                      ),
                    ],
                  ),
                ),
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
                      index: idx + 1,
                      project: project,
                      client: client, // ✅ teruskan client ke row
                      isLast: idx == projects.length - 1,
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
  static const _green    = Color(0xFF4CAF50);

  final int index;
  final Project project;
  final Client client; // ✅ client dari parent, bukan project.client
  final bool isLast;

  const _ProjectRow({
    required this.index,
    required this.project,
    required this.client,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textGrey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              project.projectName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                project.desc ?? '-',
                style: const TextStyle(
                    fontSize: 12, color: _textGrey, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ✅ Navigasi pakai client dari parent, bukan project.client
          SizedBox(
            width: 80,
            child: Center(
              child: Material(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _navigateToSurveys(context),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_outlined,
                            size: 13, color: _green),
                        SizedBox(width: 4),
                        Text(
                          'Surveys',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSurveys(BuildContext context) {
    if (project.slug == null || client.slug == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurveyListPage(
          clientSlug: client.slug!,       // ✅ dari client parent
          clientName: client.clientName,  // ✅ dari client parent
          projectSlug: project.slug!,
          projectTitle: project.projectName,
        ),
      ),
    );
  }
}