class SurveyPageModel {
  String namaHalaman;
  List<String> daftarPertanyaan;

  SurveyPageModel({
    required this.namaHalaman,
    List<String>? daftarPertanyaan,
  }) : daftarPertanyaan = daftarPertanyaan ?? [];
}