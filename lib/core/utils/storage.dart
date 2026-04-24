import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────

class StorageHelper {
  // ── SECURE STORAGE (untuk data sensitif) ──────────────────
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── KEY CONSTANTS ─────────────────────────────────────────
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';

  static const _keyOnboarded = 'is_onboarded';
  static const _keyRememberMe = 'remember_me';
  static const _keyLastEmail = 'last_email';
  static const _keyAppLanguage = 'app_language';
  static const _keyFontSizeScale = 'font_size_scale';
  static const _keyLastRouteName = 'last_route_name';
  static const _keyLastRouteArgs = 'last_route_args';

  // ── DRAFT SURVEY KEYS ───────────────────────────────────────
  static const _keyDraftSurveyPrefix = 'draft_survey_';
  static const _keyDraftBiodataPrefix = 'draft_biodata_';
  static const _keyDraftPhotoPrefix = 'draft_photo_';

  // ═══════════════════════════════════════════════════════════
  // SECURE — TOKEN
  // ═══════════════════════════════════════════════════════════

  /// Simpan JWT token secara aman
  static Future<void> saveToken(String token) async {
    debugPrint(
      '[Storage] Saving token: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
    );
    await _secure.write(key: _keyToken, value: token);
  }

  /// Ambil JWT token
  static Future<String?> getToken() async {
    final token = await _secure.read(key: _keyToken);
    debugPrint(
      '[Storage] getToken: ${token != null ? "exists (${token.length} chars)" : "NULL"}',
    );
    return token;
  }

  /// Cek apakah token tersedia
  static Future<bool> hasToken() async {
    final token = await _secure.read(key: _keyToken);
    debugPrint(
      '[Storage] hasToken check: ${token != null && token.isNotEmpty} (token: ${token != null ? "exists" : "NULL"})',
    );
    return token != null && token.isNotEmpty;
  }

  /// Hapus token (saat logout)
  static Future<void> deleteToken() async {
    debugPrint('[Storage] deleteToken called - clearing token');
    await _secure.delete(key: _keyToken);
  }

  // ═══════════════════════════════════════════════════════════
  // SECURE — USER ID
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveUserId(String userId) async {
    await _secure.write(key: _keyUserId, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _secure.read(key: _keyUserId);
  }

  static Future<void> deleteUserId() async {
    await _secure.delete(key: _keyUserId);
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED PREFERENCES — SETTINGS & FLAGS
  // ═══════════════════════════════════════════════════════════

  /// Simpan status onboarding
  static Future<void> setOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, value);
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  /// Simpan pilihan "Remember Me"
  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Simpan email terakhir (untuk pre-fill form login)
  static Future<void> saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastEmail, email);
  }

  static Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastEmail);
  }

  /// Simpan preferensi bahasa
  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppLanguage, langCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppLanguage) ?? 'id';
  }

  /// Simpan skala ukuran font
  static Future<void> saveFontSizeScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSizeScale, scale);
  }

  static Future<double> getFontSizeScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSizeScale) ?? 1.0;
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED PREFERENCES — NAVIGATION
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveLastRoute(String? name, Object? args) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null) {
      await prefs.remove(_keyLastRouteName);
      await prefs.remove(_keyLastRouteArgs);
      return;
    }
    await prefs.setString(_keyLastRouteName, name);
    if (args != null) {
      try {
        await prefs.setString(_keyLastRouteArgs, jsonEncode(args));
      } catch (_) {
        await prefs.remove(_keyLastRouteArgs);
      }
    } else {
      await prefs.remove(_keyLastRouteArgs);
    }
  }

  static Future<String?> getLastRouteName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastRouteName);
  }

  static Future<Map<String, dynamic>?> getLastRouteArgs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLastRouteArgs);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DRAFT SURVEY - LOCAL STORAGE
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveDraftSurvey({
    required String surveySlug,
    required Map<String, dynamic> answers,
    required int currentPageIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftSurveyPrefix$surveySlug';
    final data = {
      'answers': answers,
      'currentPageIndex': currentPageIndex,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getDraftSurvey(String surveySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftSurveyPrefix$surveySlug';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // ── KONVERSI JAWABAN (String Key -> Int Key) ──
      if (data.containsKey('answers') && data['answers'] is Map) {
        final rawAnswers = data['answers'] as Map<String, dynamic>;
        final converted = <int, dynamic>{};

        rawAnswers.forEach((k, v) {
          final intKey = int.tryParse(k) ?? 0;
          if (v is Map) {
            // Konversi key dalam map (untuk data Matrix: Row ID)
            final convertedMatrix = <int, dynamic>{};
            v.forEach((mk, mv) {
              final mIntKey = int.tryParse(mk.toString()) ?? 0;
              convertedMatrix[mIntKey] = mv;
            });
            converted[intKey] = convertedMatrix;
          } else {
            converted[intKey] = v;
          }
        });

        data['answers'] = converted;
      }

      return data;
    } catch (e) {
      debugPrint('Error getDraftSurvey: $e');
      return null;
    }
  }

  static Future<void> deleteDraftSurvey(String surveySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftSurveyPrefix$surveySlug';
    final photoKey = '$_keyDraftPhotoPrefix$surveySlug';
    await prefs.remove(key);
    await prefs.remove(photoKey);
  }

  static Future<bool> hasDraftSurvey(String surveySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftSurveyPrefix$surveySlug';
    return prefs.containsKey(key);
  }

  // ═══════════════════════════════════════════════════════════
  // DRAFT PHOTO - LOCAL STORAGE
  // ═══════════════════════════════════════════════════════════

  static Future<void> saveDraftPhoto({
    required String surveySlug,
    required String photoPath,
    required double latitude,
    required double longitude,
    required String captureTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftPhotoPrefix$surveySlug';
    final data = {
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'capture_time': captureTime,
    };
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getDraftPhoto(String surveySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftPhotoPrefix$surveySlug';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteDraftPhoto(String surveySlug) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyDraftPhotoPrefix$surveySlug';
    await prefs.remove(key);
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════

  /// Hapus semua data sensitif (dipanggil saat logout)
  static Future<void> clearSecure() async {
    try {
      await _secure.delete(key: _keyToken);
      await _secure.delete(key: _keyUserId);
    } catch (e) {
      // Abaikan error pada SecureStorage Android (sering terjadi karena isu Keystore)
      // agar proses logout tetap bisa dilanjutkan.
    }
  }

  static Future<void> clearLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastRouteName);
    await prefs.remove(_keyLastRouteArgs);
  }

  /// Hapus semua data (token + preferences)
  static Future<void> clearAll() async {
    await _secure.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
