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
  name: 'Badan Pemeriksa Keuangan',
  address: 'Jl. Jenderal Gatot Subroto Kav. 31 Jakarta Pusat 10210',
  about: 'Badan Pemeriksa Keuangan (BPK) adalah lembaga negara yang bebas dan mandiri, bertugas memeriksa pengelolaan dan tanggung jawab keuangan negara, mencakup penerimaan, pengeluaran, penyimpanan, serta penggunaan uang dan barang milik negara, berdasarkan UUD 1945 dan UU terkait. BPK berperan memastikan transparansi dan akuntabilitas dalam pengelolaan keuangan publik di semua tingkatan pemerintah dan lembaga terkait.',
  institution: 'Badan Pemeriksa Keuangan',
  contact: '02125549000',
  tenderDate: '01/19/2026',
  projects: [
    ProjectModel(
      number: 1,
      title: 'BPK 2026',
      description: 'Proyek BPK di tahun 2026',
      createdDate: '01/19/2026',
    ),
  ],
);

// ============================================================
// CLIENT DETAIL PAGE
// ============================================================

class ClientDetailPage extends StatelessWidget {
  final ClientModel client;

  const ClientDetailPage({super.key, required this.client});

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

  // ─── Header with back button + banner + logo ───────────────
  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Green banner
        Container(
          height: 120,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFD8EDD8),
          ),
        ),
        // Back button
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2D7A2D)),
            ),
          ),
        ),
        // Logo circle
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
              child: Icon(Icons.directions_bus_rounded, size: 36, color: Color(0xFF4CAF50)),
            ),
          ),
        ),
        // Spacer so the stack has enough height
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
              fontSize: 13,
              color: Color(0xFF757575),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── About Client ─────────────────────────────────────────
  Widget _buildAboutSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.description_outlined, label: 'About Client'),
          const SizedBox(height: 10),
          Text(
            client.about,
            style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
          ),
        ],
      ),
    );
  }

  // ─── Client Information ────────────────────────────────────
  Widget _buildClientInfoSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.info_outline_rounded, label: 'Client Information'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoField(label: 'Institution', value: client.institution),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoField(label: 'Address', value: client.address),
              ),
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              const Text(
                'Projects',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${client.projects.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...client.projects.map(
            (project) => _ProjectCard(
              project: project,
              onTap: () {
                // ──────────────────────────────────────────────────
                // NAVIGASI KE HALAMAN PROJECT
                // Ganti ProjectDetailPage() dengan halaman project
                // yang sudah kamu buat, dan kirim data project jika perlu.
                // Contoh:
                //   Navigator.push(context, MaterialPageRoute(
                //     builder: (_) => ProjectDetailPage(project: project),
                //   ));
                // ──────────────────────────────────────────────────
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PlaceholderProjectPage(project: project),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

  const _InfoField({required this.label, required this.value, this.icon});

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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
          ),
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

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${project.number}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 4),
                      Text(
                        'Created: ${project.createdDate}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER — Ganti dengan ProjectDetailPage kamu
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
              const Icon(Icons.folder_open_rounded, size: 64, color: Color(0xFF4CAF50)),
              const SizedBox(height: 16),
              Text(
                project.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
// ENTRY POINT (untuk testing standalone)
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
      home: ClientDetailPage(client: sampleClient),
    ),
  );
}