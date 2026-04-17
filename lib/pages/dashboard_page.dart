import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_surveys/client_card.dart';
import '../widgets/dashboard_surveys/project_card.dart';
import 'login_page.dart';
import 'settings_page.dart';
import '../providers/auth_provider.dart';

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

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  int _selectedIndex = 0;

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
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // 🔥 PROJECT LIST (FIX animDelay)
                  if (provider.filteredProjects.isNotEmpty)
                    ...provider.filteredProjects.asMap().entries.map((entry) {
                      final i = entry.key;
                      final project = entry.value;

                      return ProjectCard(
                        project: project,
                        animDelay: Duration(milliseconds: 100 + i * 150),
                      );
                    }),

                  const SizedBox(height: 20),

                  // 🔥 CLIENT SECTION
                  _ClientsSection(provider: provider),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.surface.withOpacity(0.8),
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: Row(
              children: [
                Image.asset(
                  'assets/images/SIS-WDU-logo.png',
                  height: 32,
                  errorBuilder: (_, __, ___) => const Text('SIS-WDU'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppTheme.primary),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Keluar'),
                content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      final authProvider = context.read<AuthProvider>();
                      authProvider.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.onSurface.withOpacity(0.08),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  isActive: true,
                  onTap: () {},
                ),
                _navItem(
                  Icons.settings_rounded,
                  'Settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF006A36), Color(0xFF71F69D)],
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppTheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isActive ? AppTheme.primary : AppTheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= CLIENT SECTION =================

class _ClientsSection extends StatelessWidget {
  final DashboardProvider provider;

  const _ClientsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Clients',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 12),

        // 🔥 SEARCH BAR
        TextField(
          onChanged: provider.updateSearch,
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search clients or projects...',
            hintStyle: GoogleFonts.inter(color: AppTheme.outline.withOpacity(0.8), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline, size: 20),
            filled: true,
            fillColor: AppTheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 GRID FIX OVERFLOW DI SINI
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.filteredClients.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 255,
          ),
          itemBuilder: (context, index) {
            return ClientCard(client: provider.filteredClients[index]);
          },
        ),
      ],
    );
  }
}
