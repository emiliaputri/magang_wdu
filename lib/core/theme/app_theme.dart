import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── DIGITAL ARCHITECT COLORS ──
  static const Color ijoTerang = Color(0xFF6FD358);
  static const Color ijoGelap = Color(0xFF54A145);

  static const Color primary = ijoTerang;
  static const Color primaryContainer = Color(0xFFE7F7EF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = ijoGelap;
  
  static const Color secondary = Color(0xFF505F55);
  static const Color secondaryContainer = Color(0xFFD6E7D9);
  
  static const Color tertiary = Color(0xFF00656F);
  static const Color tertiaryContainer = Color(0xFF10EAFE);
  
  static const Color background = Color(0xFFF5F7F6);
  static const Color surface = Color(0xFFF5F7F6);
  static const Color onSurface = Color(0xFF2C2F2F);
  static const Color onSurfaceVariant = Color(0xFF595C5C);
  
  static const Color outline = Color(0xFF747777);
  static const Color outlineVariant = Color(0xFFABAEAD);
  
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF1F0);
  static const Color surfaceContainer = Color(0xFFE6E9E8);
  static const Color surfaceContainerHigh = Color(0xFFDFE3E2);
  static const Color surfaceContainerHighest = Color(0xFFD9DEDD);
  
  static const Color error = Color(0xFFB02500);

  // ── LEGACY COLORS (Kept for compatibility where needed) ──
  static const Color dashSage50    = Color(0xFFF0FAF1);
  static const Color dashSage100   = Color(0xFFDDF2E0);
  static const Color dashSage200   = Color(0xFFB2E0BA);
  static const Color dashSage500   = Color(0xFF4CAF50);
  static const Color dashTextDark  = Color(0xFF1A2E1C);
  static const Color dashTextMid   = Color(0xFF4A6350);
  static const Color dashTextLight = Color(0xFF8AAB8F);

  static const Color monGreenDark   = ijoGelap;
  static const Color monGreenMid    = ijoTerang;
  static const Color monGreenLight  = Color(0xFF90E47F); // Adjusted for harmony
  static const Color monGreenPale   = Color(0xFFF1F9F0);
  static const Color monBgColor     = Color(0xFFF0F4F1);
  static const Color monTextDark    = Color(0xFF1A2E1C);
  static const Color monTextMid     = Color(0xFF4A6350);
  static const Color monTextLight   = Color(0xFF8AAB8F);
  static const Color monBorderColor = Color(0xFFD4E8D7);

  static const Color primaryColor    = ijoTerang;
  static const Color darkGreenColor  = ijoGelap;
  static const Color lightGreenBg    = Color(0xFFC7EBC0);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor       = Colors.white;

  static const Color green     = ijoTerang;
  static const Color textDark  = Color(0xFF1A2340);
  static const Color textGrey  = Color(0xFF7A869A);
  static const Color bgPage    = Color(0xFFF4F6F8);
  static const Color bgLight   = Color(0xFFF0F0F0);
  static const Color bgGreen   = Color(0xFFE8F5E9);
  static const Color border    = Color(0xFFE0E0E0);
  static const Color rowBorder = Color(0xFFF0F0F0);

  // ── WARNA CREATE SURVEY ──
  static const Color csBgColor     = Color(0xFFEDF5EC);
  static const Color csGreen50     = Color(0xFFE8F5E9);
  static const Color csGreen100    = Color(0xFFC8E6C9);
  static const Color csGreen600    = ijoTerang;
  static const Color csGreen700    = ijoGelap;
  static const Color csIconBg      = ijoTerang;
  static const Color csTextSub     = Color(0xFF6A9E6C);
  static const Color csInputBorder = Color(0xFFCEE5CF);

  static const TextStyle titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelBoldStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    letterSpacing: 1,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 13,
    letterSpacing: 1,
  );

  // ── INPUT DECORATION ──
  static const UnderlineInputBorder greenUnderlineBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: ijoTerang),
  );

  static const UnderlineInputBorder greenUnderlineFocusedBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: ijoTerang, width: 2),
  );

  // ── BORDER RADIUS ──
  static BorderRadius get defaultRadius => BorderRadius.circular(8);
  static BorderRadius get cardRadius    => BorderRadius.circular(12);
  static BorderRadius get smallRadius   => BorderRadius.circular(6);

  // ── THEME DATA ──
  static ThemeData get themeData {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
      ),
      scaffoldBackgroundColor: background,
    );

    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    final manropeTextTheme = GoogleFonts.manropeTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: interTextTheme.copyWith(
        displayLarge: manropeTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
        displayMedium: manropeTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
        displaySmall: manropeTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        headlineLarge: manropeTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        headlineMedium: manropeTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: manropeTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        titleLarge: manropeTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        titleMedium: manropeTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        titleSmall: manropeTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        labelLarge: interTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 14),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: interTextTheme.bodySmall?.copyWith(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ijoTerang,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ijoTerang,
          side: const BorderSide(color: ijoTerang),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ijoTerang,
        ),
      ),
    );
  }
}
