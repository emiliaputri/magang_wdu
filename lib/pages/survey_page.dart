import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/survey_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/project_list/survey_bento_card.dart';

class SurveyBpkPage extends StatefulWidget {
  final String clientSlug;
  final String projectSlug;
  final String clientName;
  final String projectName;
  final String? clientLogoUrl;

  const SurveyBpkPage({
    super.key,
    required this.clientSlug,
    required this.projectSlug,
    required this.clientName,
    required this.projectName,
    this.clientLogoUrl,
  });

  @override
  State<SurveyBpkPage> createState() => _SurveyBpkPageState();
}

class _SurveyBpkPageState extends State<SurveyBpkPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<SurveyProvider>()
          .loadSurveys(widget.clientSlug, widget.projectSlug)
          .then((_) {
            context.read<SurveyProvider>().loadUserAnswerStatus(
              widget.clientSlug,
              widget.projectSlug,
            );
          });
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  Future<bool> _onWillPop() async {
    final result = await Navigator.maybePop(context);
    if (result == true) {
      // Refresh status when coming back
      context.read<SurveyProvider>().loadUserAnswerStatus(
        widget.clientSlug,
        widget.projectSlug,
      );
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          context.read<SurveyProvider>().loadUserAnswerStatus(
            widget.clientSlug,
            widget.projectSlug,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Consumer<SurveyProvider>(
          builder: (context, provider, _) {
            final filtered = provider.surveys
                .where(
                  (s) =>
                      s.title.toLowerCase().contains(_query) ||
                      (s.desc ?? '').toLowerCase().contains(_query),
                )
                .toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildOldStyleHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildSearchSection(),
                  ),
                ),
                _buildSurveyGrid(filtered, provider),
              ],
            );
          },
        ),
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

  Widget _buildSurveyGrid(List filtered, SurveyProvider provider) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (provider.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppTheme.outline.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada kuisioner.',
                style: TextStyle(color: AppTheme.outline.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 2 : 1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 290,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final survey = filtered[index];
          return SurveyBentoCard(
            survey: survey,
            clientSlug: widget.clientSlug,
            projectSlug: widget.projectSlug,
            hasAnswered: provider.hasUserAnswered(survey.slug),
          );
        }, childCount: filtered.length),
      ),
    );
  }

  Widget _buildOldStyleHeader() {
    return Column(
      children: [
        // ══════════════ GRADIENT HEADER ══════════════
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffe8faf4), Color(0xffc8f0e2), Color(0xffb2e8d6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 44, 32, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientLogo(),
                const SizedBox(height: 20),
                Text(
                  widget.clientName,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xff1a7a5e),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _clientDescription(widget.clientName),
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.75,
                    color: const Color(0xff374151),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ══════════════ PROJECT INFO ══════════════
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff1a7a5e).withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xff1a7a5e).withOpacity(0.25),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 14,
                      color: Color(0xff1a7a5e),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PROJECT NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xff1a7a5e),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xfff9fafb),
                  border: Border.all(
                    color: const Color(0xffe5e7eb),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.projectName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff1a7a5e),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClientLogo() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1a7a5e).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.clientLogoUrl != null && widget.clientLogoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                widget.clientLogoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, url, error) => _buildFallbackLogo(),
              ),
            )
          : _buildFallbackLogo(),
    );
  }

  Widget _buildFallbackLogo() {
    String nameLower = widget.clientName.toLowerCase();
    if (nameLower.contains('transjakarta') || nameLower.contains('trans jakarta')) {
      return ClipOval(child: Image.asset('assets/images/logo_trans.jpeg', fit: BoxFit.cover));
    } else if (nameLower.contains('bpk') || nameLower.contains('badan pemeriksa keuangan')) {
      return ClipOval(child: Image.asset('assets/images/logo_bpk.png', fit: BoxFit.cover));
    } else {
      return _defaultLogoIcon(widget.clientName);
    }
  }

  Widget _defaultLogoIcon(String name) {
    String initials = '';
    if (name.isNotEmpty) {
      List<String> words = name.split(' ');
      if (words.length > 1) {
        initials = (words[0][0] + words[1][0]).toUpperCase();
      } else {
        initials = words[0][0].toUpperCase();
      }
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.1), AppTheme.primary.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  String _clientDescription(String name) {
    if (name.toLowerCase().contains('bpk') ||
        name.toLowerCase().contains('badan pemeriksa')) {
      return 'Badan Pemeriksa Keuangan (BPK) adalah lembaga negara yang bebas dan mandiri, bertugas memeriksa pengelolaan dan tanggung jawab keuangan negara, berdasarkan UUD 1945 dan UU terkait. BPK berperan memastikan transparansi dan akuntabilitas publik.';
    }
    return name;
  }
}
