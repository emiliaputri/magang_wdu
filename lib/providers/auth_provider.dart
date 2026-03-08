import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading      = false;
  bool _rememberMe   = false;
  bool _obscurePassword = true;

  // ── GETTERS ──
  bool get loading         => _loading;
  bool get rememberMe      => _rememberMe;
  bool get obscurePassword => _obscurePassword;

  // ── TOGGLE ──
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // ── LOGIN ──
  /// Mengembalikan true jika login berhasil, false jika gagal
  Future<bool> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    final success = await _authService.login(email, password);

    _loading = false;
    notifyListeners();

    return success;
  }
}