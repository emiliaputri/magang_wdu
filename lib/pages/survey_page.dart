import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/survey_provider.dart';
import '../widgets/view_surveys/viewsurvey_card.dart';

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

  void _refresh() {
    context.read<SurveyProvider>().loadSurveys(
      widget.clientSlug,
      widget.projectSlug,
      silent: true,
    );
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
        backgroundColor: const Color(0xfff5f7fa),
        body: Consumer<SurveyProvider>(
          builder: (context, provider, _) {
            final filtered = provider.surveys
                .where(
                  (s) =>
                      s.title.toLowerCase().contains(_query) ||
                      (s.desc ?? '').toLowerCase().contains(_query),
                )
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  // ══════════════ HEADER ══════════════
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xffe8faf4),
                          Color(0xffc8f0e2),
                          Color(0xffb2e8d6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 44, 32, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo circle saja, tanpa button Tambah Kuisioner
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xff1a7a5e,
                                  ).withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: widget.clientLogoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      widget.clientLogoUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, progress) =>
                                              progress == null
                                              ? child
                                              : _defaultLogoIcon(),
                                      errorBuilder: (context, url, error) =>
                                          _defaultLogoIcon(),
                                    ),
                                  )
                                : _defaultLogoIcon(),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            widget.clientName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff111827),
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
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.75,
                              color: Color(0xff374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ══════════════ PROJECT NAME ══════════════
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1a7a5e),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ══════════════ SEARCH + CARDS ══════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xffe5e7eb),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Cari kuisioner berdasarkan judul atau deskripsi',
                              hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xff9ca3af),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xff9ca3af),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: CircularProgressIndicator(
                              color: Color(0xff1a7a5e),
                            ),
                          )
                        else if (provider.hasError)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  provider.errorMessage ?? 'Terjadi kesalahan.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refresh,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff1a7a5e),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Coba Lagi',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada kuisioner.',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (_, i) {
                              final s = filtered[i];
                              return ViewSurveyCard(
                                survey: s,
                                clientSlug: widget.clientSlug,
                                projectSlug: widget.projectSlug,
                                onRefresh: _refresh,
                                onDelete: _refresh,
                                onTapResponden: () {},
                                onCekEdit: () {},
                                hasAnswered: provider.hasUserAnswered(s.slug),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _defaultLogoIcon() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.insert_drive_file_rounded,
        size: 34,
        color: const Color(0xff1a7a5e).withOpacity(0.45),
      ),
      const SizedBox(height: 2),
      Text(
        'Client Logo',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
        ),
      ),
    ],
  );

  String _clientDescription(String name) {
    if (name.toLowerCase().contains('bpk') ||
        name.toLowerCase().contains('badan pemeriksa')) {
      return 'Badan Pemeriksa Keuangan (BPK) adalah lembaga negara yang bebas dan mandiri, bertugas memeriksa pengelolaan dan tanggung jawab keuangan negara, mencakup penerimaan, pengeluaran, penyimpanan, serta penggunaan uang dan barang milik negara, berdasarkan UUD 1945 dan UU terkait. BPK berperan memastikan transparansi dan akuntabilitas dalam pengelolaan keuangan publik di semua tingkatan pemerintah dan lembaga terkait, dengan hasil laporannya disampaikan ke DPR, DPD, dan DPRD serta terbuka untuk umum.';
    }
    return name;
  }
}
