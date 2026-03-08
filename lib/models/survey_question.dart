class SurveyQuestion {
  final String id;
  final String title;
  final String type; // radio, dropdown, checkbox
  final List<String> options;

  SurveyQuestion({
    required this.id,
    required this.title,
    required this.type,
    required this.options,
  });
}