import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_surveys/client_card.dart';
import '../widgets/dashboard_surveys/project_card.dart';
import '../widgets/dashboard_surveys/section_header.dart';
import '../providers/auth_provider.dart';

// ── ENTRY POINT ───────────────────────────────────────────────
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..init(),
      child: const _DashboardView(),
    );
  }
}

// ── VIEW ──────────────────────────────────────────────────────
class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    final provider = context.read<DashboardProvider>();
    if (!provider.loading) {
      _animController.forward();
    } else {
      provider.addListener(_onLoadingDone);
    }
  }

  void _onLoadingDone() {
    final provider = context.read<DashboardProvider>();
    if (!provider.loading) {
      _animController.forward();
      provider.removeListener(_onLoadingDone);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    if (provider.loading) {
      return const Scaffold(
        backgroundColor: AppTheme.dashSage50,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.dashSage500),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.dashSage50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── ACTIVE PROJECTS ──
                    if (provider.projects.isNotEmpty) ...[
                      const SectionHeader(
                        icon: Icons.folder_open_rounded,
                        title: 'Active Projects',
                        subtitle: 'Overview of latest projects',
                      ),
                      const SizedBox(height: 14),
                      ...provider.projects.asMap().entries.map((entry) {
                        final i = entry.key;
                        final project = entry.value;
                        return ProjectCard(
                          project: project,
                          animDelay: Duration(milliseconds: 100 + i * 150),
                        );
                      }),
                      const SizedBox(height: 6),
                    ],

                    // ── CLIENTS ──
                    _ClientsSection(provider: provider),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      leadingWidth: 200,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Image.asset(
          'assets/images/SIS-WDU-logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: AppTheme.dashSage500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'SIS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(context),
          icon: const Icon(Icons.logout_rounded, color: AppTheme.dashSage500),
          tooltip: 'Logout',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.dashSage100),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.dashTextMid)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} // ✅ kurung tutup _DashboardViewState

// ── CLIENTS SECTION ───────────────────────────────────────────
class _ClientsSection extends StatelessWidget {
  final DashboardProvider provider;

  const _ClientsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dashSage100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.dashSage500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clients',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.dashTextDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage your client portfolio',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.dashTextLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.dashSage100,
                      foregroundColor: AppTheme.dashSage500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppTheme.dashSage200),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: provider.updateSearch,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.dashTextDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  hintStyle: const TextStyle(
                    color: AppTheme.dashSage200,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.dashTextLight,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppTheme.dashSage50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(color: AppTheme.dashSage100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: const BorderSide(
                      color: AppTheme.dashSage500,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── CLIENT LIST ──
        if (provider.clientsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: CircularProgressIndicator(color: AppTheme.dashSage500),
            ),
          )
        else if (provider.filteredClients.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dashSage100),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppTheme.dashSage200,
                ),
                SizedBox(height: 10),
                Text(
                  'No clients found',
                  style: TextStyle(fontSize: 13, color: AppTheme.dashTextLight),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  0.68, // Adjust childAspectRatio directly if needed
            ),
            itemCount: provider.filteredClients.length,
            itemBuilder: (context, index) =>
                ClientCard(client: provider.filteredClients[index]),
          ),
      ],
    );
  }
}
