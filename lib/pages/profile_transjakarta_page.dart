import 'package:flutter/material.dart';


class ClientModel {
  final String name;
  final String address;
  final String about;
  final String institution;
  final String contact;
  final String tenderDate;
  final List<ProjectModel> projects;

  const ClientModel({
    required this.name,
    required this.address,
    required this.about,
    required this.institution,
    required this.contact,
    required this.tenderDate,
    required this.projects,
  });
}

class ProjectModel {
  final int number;
  final String title;
  final String description;
  final String createdDate;

  const ProjectModel({
    required this.number,
    required this.title,
    required this.description,
    required this.createdDate,
  });
}

// ============================================================
// SAMPLE DATA
// ============================================================

final sampleClient = ClientModel(
  name: 'TransJakarta',
  address: 'Jalan Mayjen Sutoyo No. 1, Cawang, Kecamatan Makasar, Jakarta Timur, 13650',
  about: 'PT Transportasi Jakarta',
  institution: 'TransJakarta',
  contact: '02180879449',
  tenderDate: '01/05/2026',
  projects: [
    ProjectModel(
      number: 1,
      title: 'Survei Pengukuran Capaian SPM Penyelenggaraan PT Transportasi Jakarta Tahun 2026',
      description: 'Survei Pengukuran Capaian SPM Penyelenggaraan PT Transportasi Jakarta Tahun 2026',
      createdDate: '01/05/2026',
    ),
  ],
);

// ============================================================
// CLIENT DETAIL PAGE
// ============================================================

class ClientDetailTransjakartaPage extends StatelessWidget {
  final ClientModel client;

  const ClientDetailTransjakartaPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientName(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                    const SizedBox(height: 20),
                    _buildClientInfoSection(),
                    const SizedBox(height: 20),
                    _buildProjectsSection(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFD8EDD8)),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF2D7A2D)),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: 20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.directions_bus_rounded,
                  size: 36, color: Color(0xFF4CAF50)),
            ),
          ),
        ),
        const SizedBox(height: 160),
      ],
    );
  }

  // ─── Client Name & Address ─────────────────────────────────
  Widget _buildClientName() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            client.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            client.address,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF757575), height: 1.4),
          ),
        ],
      ),
    );
  }

  // ─── About ────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.description_outlined, label: 'About Client'),
          const SizedBox(height: 10),
          Text(client.about,
              style: const TextStyle(fontSize: 14, color: Color(0xFF424242))),
        ],
      ),
    );
  }

  // ─── Client Info ───────────────────────────────────────────
  Widget _buildClientInfoSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.info_outline_rounded, label: 'Client Information'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _InfoField(
                      label: 'Institution', value: client.institution)),
              const SizedBox(width: 12),
              Expanded(
                  child:
                      _InfoField(label: 'Address', value: client.address)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoField(
                  label: 'Contact',
                  value: client.contact,
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoField(
                  label: 'Tender Date',
                  value: client.tenderDate,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Projects ─────────────────────────────────────────────
  Widget _buildProjectsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Row(
          children: [
            const Icon(Icons.grid_view_rounded,
                size: 18, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${client.projects.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Cards ──
        if (client.projects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: const Column(
              children: [
                Icon(Icons.folder_open_outlined,
                    size: 36, color: Color(0xFFBDBDBD)),
                SizedBox(height: 8),
                Text(
                  'Tidak ada project.',
                  style:
                      TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...client.projects.map(
            (project) => _ProjectCard(
              project: project,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _PlaceholderProjectPage(project: project),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ============================================================
// REUSABLE WIDGETS
// ============================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _InfoField(
      {required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Project Card (NEW DESIGN sesuai screenshot) ───────────────

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDEEDD), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Number badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${project.number}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2340),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A869A),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 11, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${project.createdDate}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Arrow button
              Material(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onTap,
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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

// ============================================================
// PLACEHOLDER
// ============================================================

class _PlaceholderProjectPage extends StatelessWidget {
  final ProjectModel project;
  const _PlaceholderProjectPage({required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Detail'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open_rounded,
                  size: 64, color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              Text(
                project.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '← Hubungkan ke ProjectDetailPage kamu di sini',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ENTRY POINT
// ============================================================

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Client Detail',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4CAF50),
        useMaterial3: true,
      ),
      home: ClientDetailTransjakartaPage(client: sampleClient),
    ),
  );
}