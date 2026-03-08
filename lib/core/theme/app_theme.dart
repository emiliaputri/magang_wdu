import 'package:flutter/material.dart';

class AppTheme {
  // ── WARNA UTAMA ──
  static const Color primaryColor    = Color(0xFF3DAA2E);
  static const Color darkGreenColor  = Color(0xFF2A7A20);
  static const Color lightGreenBg    = Color(0xFFB8E0A8);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor       = Colors.white;

  // ── WARNA MONITORING ──
  static const Color monGreenDark   = Color(0xFF2D7A3A);
  static const Color monGreenMid    = Color(0xFF3A9E4F);
  static const Color monGreenLight  = Color(0xFF5DBB6E);
  static const Color monGreenPale   = Color(0xFFE8F5EA);
  static const Color monBgColor     = Color(0xFFF0F4F1);
  static const Color monTextDark    = Color(0xFF1A2E1C);
  static const Color monTextMid     = Color(0xFF4A6350);
  static const Color monTextLight   = Color(0xFF8AAB8F);
  static const Color monBorderColor = Color(0xFFD4E8D7);

  // ── WARNA DASHBOARD ──
  static const Color dashSage50    = Color(0xFFF0FAF1);
  static const Color dashSage100   = Color(0xFFDDF2E0);
  static const Color dashSage200   = Color(0xFFB2E0BA);
  static const Color dashSage500   = Color(0xFF4CAF50);
  static const Color dashTextDark  = Color(0xFF1A2E1C);
  static const Color dashTextMid   = Color(0xFF4A6350);
  static const Color dashTextLight = Color(0xFF8AAB8F);

  // ── WARNA CREATE SURVEY ──
  static const Color csBgColor     = Color(0xFFEDF5EC);
  static const Color csGreen50     = Color(0xFFE8F5E9);
  static const Color csGreen100    = Color(0xFFC8E6C9);
  static const Color csGreen600    = Color(0xFF388E3C);
  static const Color csGreen700    = Color(0xFF2E7D32);
  static const Color csIconBg      = Color(0xFF4CAF50);
  static const Color csTextSub     = Color(0xFF6A9E6C);
  static const Color csInputBorder = Color(0xFFCEE5CF);

  // ── TEXT STYLE ──
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelBoldStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    letterSpacing: 1,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    letterSpacing: 1,
  );

  // ── INPUT DECORATION ──
  static const UnderlineInputBorder greenUnderlineBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF3DAA2E)),
  );

  static const UnderlineInputBorder greenUnderlineFocusedBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF3DAA2E), width: 2),
  );

  // ── BORDER RADIUS ──
  static BorderRadius get defaultRadius => BorderRadius.circular(8);
  static BorderRadius get cardRadius    => BorderRadius.circular(12);
  static BorderRadius get smallRadius   => BorderRadius.circular(6);

  // ── THEME DATA ──
  static ThemeData get themeData => ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3DAA2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF3DAA2E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
}