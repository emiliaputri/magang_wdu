import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/survey_provider.dart';
import 'survey_bpk_page.dart';

class SurveyListPage extends StatefulWidget {
  final String clientSlug;
  final String clientName;
  final String projectSlug;
  final String projectTitle;

  const SurveyListPage({
    super.key,
    required this.clientSlug,
    required this.clientName,
    required this.projectSlug,
    required this.projectTitle,
  });

  @override
  State<SurveyListPage> createState() => _SurveyListPageState();
}

class _SurveyListPageState extends State<SurveyListPage> {
  @override
  void initState() {
    super.initState();
    // Fetch data via provider saat page dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SurveyProvider>().loadSurveys(
            widget.clientSlug,
            widget.projectSlug,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Langsung tampilkan SurveyBpkPage dengan desain lengkap
    return SurveyBpkPage(
      clientSlug: widget.clientSlug,
      projectSlug: widget.projectSlug,
      clientName: widget.clientName,
      projectName: widget.projectTitle,
    );
  }
}