import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../core/api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  // ── GETTERS ───────────────────────────────────────────────
  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  // ── TOGGLE ────────────────────────────────────────────────
  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // ── LOGIN ─────────────────────────────────────────────────
  /// Mengembalikan AuthResponse
  Future<AuthResponse> performLogin(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.performLogin(email, password);
      _loading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      if (e is UnauthorizedException) {
        _errorMessage = 'Email atau password salah';
      }
      _loading = false;
      notifyListeners();
      return AuthResponse(status: AuthStatus.error, message: _errorMessage);
    }
  }

  // ── 2FA VERIFY ───────────────────────────────────────────
  Future<bool> verifyOtp(String code) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.verifyOtp(code);
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── 2FA RESEND ───────────────────────────────────────────
  Future<String?> resendOtp() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _authService.resendOtp();
      _loading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _errorMessage = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  // ── CHANGE PASSWORD ───────────────────────────────────────
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('ApiException: ', '')
          .replaceFirst('ApiException(null): ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
