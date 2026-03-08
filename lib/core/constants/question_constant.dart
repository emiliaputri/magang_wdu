import 'package:flutter/material.dart';

class QuestionConstants {
  // Daftar tipe pertanyaan
  static const List<Map<String, dynamic>> daftarTipe = [
    {"judul": "Text",            "icon": Icons.text_fields},
    {"judul": "Single Choice",   "icon": Icons.radio_button_checked},
    {"judul": "Multiple Choice", "icon": Icons.check_box},
    {"judul": "Number Scale",    "icon": Icons.pin},
    {"judul": "Dropdown",        "icon": Icons.arrow_drop_down_circle},
    {"judul": "Cellphone",       "icon": Icons.smartphone},
    {"judul": "Matrix Choice",   "icon": Icons.grid_view},
    {"judul": "Document",        "icon": Icons.insert_drive_file},
  ];

  // Daftar tipe deskripsi
  static const List<Map<String, dynamic>> daftarDeskripsi = [
    {"judul": "Image",     "icon": Icons.image},
    {"judul": "Paragraph", "icon": Icons.format_align_left},
  ];

  // Tipe yang memiliki opsi pilihan
  static const List<String> tipeWithOptions = [
    "Single Choice",
    "Multiple Choice",
    "Dropdown",
  ];

  static bool hasOptions(String tipe) => tipeWithOptions.contains(tipe);
}