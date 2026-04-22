import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/constants/endpoints.dart';
import '../core/utils/storage.dart';

enum AuthStatus { success, twoFactorRequired, error }

class AuthResponse {
  final AuthStatus status;
  final String? message;
  final Map<String, dynamic>? user;

  AuthResponse({required this.status, this.message, this.user});
}

class AuthService {
  final _api = ApiClient();

  // ── LOGIN ─────────────────────────────────────────────────
  // POST /api/login
  Future<AuthResponse> performLogin(String email, String password) async {
    final response = await _api.post(
      Endpoints.login,
      body: {'email': email, 'password': password},
      requireAuth: false,
    );

    final status = response.data?['status'] as String?;
    final token = response.data?['token'] as String?;
    final user = response.data?['user'] as Map<String, dynamic>?;

    if (token == null) {
      throw ApiException('Token tidak ditemukan dalam respons server');
    }

    await StorageHelper.saveToken(token);

    if (status == '2fa_required') {
      return AuthResponse(
        status: AuthStatus.twoFactorRequired,
        message: response.data?['message'],
      );
    }

    final userId = user?['id']?.toString();
    if (userId != null) await StorageHelper.saveUserId(userId);

    return AuthResponse(status: AuthStatus.success, user: user);
  }

  // ── 2FA VERIFY ───────────────────────────────────────────
  Future<bool> verifyOtp(String code) async {
    final response = await _api.post(
      Endpoints.verifyOtp,
      body: {'code': code},
    );

    if (response.success) {
      final user = response.data?['user'] as Map<String, dynamic>?;
      final userId = user?['id']?.toString();
      if (userId != null) await StorageHelper.saveUserId(userId);
      return true;
    }
    return false;
  }

  // ── 2FA RESEND ───────────────────────────────────────────
  Future<String> resendOtp() async {
    final response = await _api.post(Endpoints.resendOtp, body: {});
    return response.data?['message'] ?? 'Kode verifikasi telah dikirim.';
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

  // ── CHANGE PASSWORD ───────────────────────────────────────
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post(
      Endpoints.changePassword,
      body: {
        'old_password': oldPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
  }
}
