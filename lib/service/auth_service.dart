import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../core/utils/storage.dart';

class AuthService {
  final _api = ApiClient();

  // ── LOGIN ─────────────────────────────────────────────────
  // POST /api/login
  Future<bool> login(String email, String password) async {
    final response = await _api.post(
      Endpoints.login,
      body: {'email': email, 'password': password},
      requireAuth: false,
    );

    final token = response.data?['token'] as String?;
    final userId = response.data?['user']?['id']?.toString();

    if (token == null) {
      throw ApiException('Token tidak ditemukan dalam respons server');
    }

    await StorageHelper.saveToken(token);
    if (userId != null) await StorageHelper.saveUserId(userId);

    final rememberMe = await StorageHelper.getRememberMe();
    if (rememberMe) await StorageHelper.saveLastEmail(email);

    return true;
  }

  // ── GET USER ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await _api.get(Endpoints.me);
      return response.data;
    } on UnauthorizedException {
      debugPrint(
        '[AuthService] getUser() - 401 Unauthorized (token mungkin expired tapi masih ada di storage)',
      );
      return null;
    } on ApiException {
      return null;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    debugPrint('[AuthService] logout() called - clearing all secure data');
    await StorageHelper.clearSecure();
    await StorageHelper.clearLastRoute();
    debugPrint('[AuthService] logout complete');
  }

  // ── CEK STATUS LOGIN ──────────────────────────────────────
  Future<bool> isLoggedIn() async {
    return await StorageHelper.hasToken();
  }
}
