import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../core/api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  // ── GETTERS ───────────────────────────────────────────────
  bool get loading => _loading;
  bool get rememberMe => _rememberMe;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  // ── TOGGLE ────────────────────────────────────────────────
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // ── LOGIN ─────────────────────────────────────────────────
  /// Mengembalikan true jika login berhasil, false jika gagal
  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.login(email, password);
      _loading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('ApiException: ', '')
          .replaceFirst('ApiException(null): ', '');
      if (e is UnauthorizedException) {
        _errorMessage = 'Email atau password salah';
      }
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
