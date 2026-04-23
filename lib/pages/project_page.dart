import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/client_model.dart';
import '../models/project_model.dart';
import '../models/survey_model.dart';
import '../core/theme/app_theme.dart';
import '../widgets/project_list/survey_bento_card.dart';

class ProjectListPage extends StatefulWidget {
  final Client client;

  const ProjectListPage({super.key, required this.client});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Project> get _projects => widget.client.projects ?? [];

  List<SurveyModel> get _allSurveys {
    final List<SurveyModel> flattened = [];
    for (var p in _projects) {
      if (p.surveys != null) {
        flattened.addAll(p.surveys!);
      }
    }
    return flattened;
  }

  List<SurveyModel> get _filteredSurveys => _allSurveys
      .where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSearchSection(),
            ),
          ),
          _buildSurveyGrid(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.surface.withOpacity(0.8),
      elevation: 0,
      pinned: true,
      centerTitle: true,
      expandedHeight: 60,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(vertical: 12),
            centerTitle: true,
            title: Text(
              'Surveys',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          child: _buildUserAvatar(),
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryContainer, width: 2),
        image: const DecorationImage(
          image: NetworkImage(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCv34DsqRUZUqKv_NeyCEHI-lhaJDfRIEpGZijfDE-F5WTMy15De2vE2F2U0Tq93p1SgLypDPorL5H6k-2FMPdVtmABiCYFymqzl_Fw9Ce1l4DVRVXkCdAYs5CSIk8HuoBjlBqdd9uiF6yPnhA-m3sAUuNNu_XHQVaNowOjD-z9xFxZRPxYrcMDKpodMPz-0yAshllWST4n8mpc3w0H2K7qZ8nxOXWvQwXv7pwymmdxFFiprjvKqvklL0gebux8nCdyX2O8Tim18Cwx',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.onSurface.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Cari kuisioner...',
          hintStyle: GoogleFonts.inter(
            color: AppTheme.outline.withOpacity(0.6),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
        ),
      ),
    );
  }

  Widget _buildSurveyGrid() {
    final surveys = _filteredSurveys;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 2 : 1,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          mainAxisExtent: 180,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          // Placeholder/Create Card
          if (index == surveys.length) return _buildNewPlaceholder();

          final survey = surveys[index];
          // Find parent project slug for survey context
          final parentProject = _projects.firstWhere(
            (p) => p.surveys?.any((s) => s.id == survey.id) ?? false,
            orElse: () => _projects.isNotEmpty
                ? _projects.first
                : Project(projectName: 'Unknown'),
          );

          return SurveyBentoCard(
            survey: survey,
            clientSlug: widget.client.slug ?? '',
            projectSlug: parentProject.slug ?? '',
          );
        }, childCount: surveys.length + 1),
      ),
    );
  }

  Widget _buildNewPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
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
              Icons.add_task_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Buat Kuisioner Baru',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Mulai proyek survey baru dengan builder cerdas kami.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
