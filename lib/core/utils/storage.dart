import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// StorageHelper
//
// Pemisahan tanggung jawab:
//   • flutter_secure_storage → data SENSITIF (token JWT, user id)
//   • shared_preferences     → data TIDAK SENSITIF (settings, flags)
// ─────────────────────────────────────────────────────────────

class StorageHelper {
  // ── SECURE STORAGE (untuk data sensitif) ──────────────────
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── KEY CONSTANTS ─────────────────────────────────────────
  static const _keyToken  = 'auth_token';
  static const _keyUserId = 'user_id';

  static const _keyOnboarded   = 'is_onboarded';
  static const _keyRememberMe  = 'remember_me';
  static const _keyLastEmail   = 'last_email';
  static const _keyAppLanguage = 'app_language';

  // ═══════════════════════════════════════════════════════════
  // SECURE — TOKEN
  // ═══════════════════════════════════════════════════════════

  /// Simpan JWT token secara aman
  static Future<void> saveToken(String token) async {
    await _secure.write(key: _keyToken, value: token);
  }

  /// Ambil JWT token
  static Future<String?> getToken() async {
    return await _secure.read(key: _keyToken);
  }

  /// Cek apakah token tersedia
  static Future<bool> hasToken() async {
    final token = await _secure.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  /// Hapus token (saat logout)
  static Future<void> deleteToken() async {
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

  // ═══════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════

  /// Hapus semua data sensitif (dipanggil saat logout)
  static Future<void> clearSecure() async {
    await _secure.delete(key: _keyToken);
    await _secure.delete(key: _keyUserId);
  }

  /// Hapus semua data (token + preferences)
  static Future<void> clearAll() async {
    await _secure.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}