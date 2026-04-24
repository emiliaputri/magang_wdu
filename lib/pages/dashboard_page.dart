import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../providers/dashboard_provider.dart';
import '../providers/font_size_provider.dart';
import '../widgets/dashboard_surveys/client_card.dart';
import '../widgets/dashboard_surveys/project_card.dart';
import 'login_page.dart';
import 'settings_page.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/ringing_bell_icon.dart';

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

                  /*
                  const SizedBox(height: 20),

                  // 🔥 CLIENT SECTION
                  _ClientsSection(provider: provider),
                  */
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
        _buildFontSizeButton(context),
        const RingingBellIcon(),
        _buildSettingsButton(context),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.settings_rounded, color: AppTheme.primary),
      tooltip: 'Settings',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
      },
    );
  }

  Widget _buildFontSizeButton(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, provider, _) {
        return IconButton(
          icon: Icon(Icons.format_size_rounded, color: AppTheme.primary),
          tooltip: 'Ukuran Font',
          onPressed: () => _showFontSizeDialog(context),
        );
      },
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<FontSizeProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.format_size_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ukuran Font',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFontSizeOption(context, provider, 'Kecil', 0.85),
                  _buildFontSizeOption(
                    context,
                    provider,
                    'Sedang (Normal)',
                    1.0,
                  ),
                  _buildFontSizeOption(context, provider, 'Besar', 1.2),
                  _buildFontSizeOption(context, provider, 'Sangat Besar', 1.4),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.manrope(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFontSizeOption(
    BuildContext context,
    FontSizeProvider provider,
    String label,
    double scale,
  ) {
    final isSelected = provider.fontSizeScale == scale;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          Icons.text_fields_rounded,
          color: isSelected ? AppTheme.primary : AppTheme.outline,
          size: 20,
        ),
        title: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14 * scale,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.onSurface,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 22,
              )
            : null,
        onTap: () {
          provider.setFontSizeScale(scale);
        },
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
            hintStyle: GoogleFonts.inter(
              color: AppTheme.outline.withOpacity(0.8),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.outline,
              size: 20,
            ),
            filled: true,
            fillColor: AppTheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.outlineVariant.withOpacity(0.3),
              ),
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
