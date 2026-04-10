import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_surveys/client_card.dart';
import '../widgets/dashboard_surveys/project_card.dart';
import 'login_page.dart';

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

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);

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
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
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
                        animDelay:
                            Duration(milliseconds: 100 + i * 150),
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
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.surface.withOpacity(0.8),
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          icon: const Icon(Icons.logout_rounded,
              color: AppTheme.primary),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
            );
          },
        )
      ],
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
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 GRID FIX OVERFLOW DI SINI
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.filteredClients.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 230, // 🔥 KUNCI FIX OVERFLOW
          ),
          itemBuilder: (context, index) {
            return ClientCard(
              client: provider.filteredClients[index],
            );
          },
        ),
      ],
    );
  }
}