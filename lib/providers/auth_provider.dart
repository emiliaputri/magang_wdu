import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../service/auth_service.dart';
import '../core/api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  Map<String, dynamic>? _user;

  String? _errorMessage;

  // ── GETTERS ───────────────────────────────────────────────
  bool get loading => _loading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  // ── TOGGLE ────────────────────────────────────────────────
  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // ── USER DATA ─────────────────────────────────────────────
  Future<void> getUser() async {
    _loading = true;
    notifyListeners();

    try {
      final userData = await _authService.getUser();
      if (userData != null) {
        _user = userData['user'];
      }
    } catch (e) {
      debugPrint('[AuthProvider] getUser error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── UPDATE PHOTO ──────────────────────────────────────────
  Future<bool> updateProfilePhoto(XFile image) async {
    _loading = true;
    notifyListeners();

    try {
      final newPhotoUrl = await _authService.updateProfilePhoto(image);
      if (newPhotoUrl != null && _user != null) {
        // Create a copy of the user map and update the photo URL
        final updatedUser = Map<String, dynamic>.from(_user!);
        updatedUser['profile_photo_url'] = newPhotoUrl;
        _user = updatedUser;
        
        _loading = false;
        notifyListeners();
        return true;
      }
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] updateProfilePhoto error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
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

  // ── TOGGLE 2FA ────────────────────────────────────────────
  Future<bool> toggle2FA(bool enable, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.toggle2FA(enable, password);
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

  // ── CONFIRM 2FA ───────────────────────────────────────────
  Future<bool> confirm2FA(String code) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.confirm2FA(code);
      if (data != null && _user != null) {
        final updatedUser = Map<String, dynamic>.from(_user!);
        updatedUser['email_2fa_enabled'] = data['email_2fa_enabled'];
        _user = updatedUser;
        
        _loading = false;
        notifyListeners();
        return true;
      }
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
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
