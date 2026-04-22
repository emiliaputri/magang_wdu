import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login/app_input_field.dart';

class TwoFactorSettingsPage extends StatefulWidget {
  final bool isEnabling;
  const TwoFactorSettingsPage({super.key, required this.isEnabling});

  @override
  State<TwoFactorSettingsPage> createState() => _TwoFactorSettingsPageState();
}

class _TwoFactorSettingsPageState extends State<TwoFactorSettingsPage> {
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _requiresOtp = false;
  String? _localError;

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordConfirm() async {
    setState(() => _localError = null);
    
    if (_passwordController.text.isEmpty) {
      setState(() => _localError = 'Password wajib diisi');
      return;
    }

    final provider = context.read<AuthProvider>();
    final success = await provider.toggle2FA(widget.isEnabling, _passwordController.text);

    if (mounted) {
      if (success) {
        setState(() => _requiresOtp = true);
      } else {
        setState(() => _localError = provider.errorMessage ?? 'Konfirmasi password gagal');
      }
    }
  }

  Future<void> _handleOtpVerify() async {
    setState(() => _localError = null);
    
    if (_otpController.text.length != 6) {
      setState(() => _localError = 'Kode harus 6 digit');
      return;
    }

    final provider = context.read<AuthProvider>();
    final success = await provider.confirm2FA(_otpController.text);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnabling ? '2FA Berhasil diaktifkan' : '2FA Berhasil dinonaktifkan'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() => _localError = provider.errorMessage ?? 'Kode verifikasi salah');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isEnabling ? 'Enable 2FA' : 'Disable 2FA',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _requiresOtp ? 'Verify OTP' : 'Confirm Password',
              style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              _requiresOtp 
                ? 'Masukkan 6 digit kode yang dikirim ke email Anda.' 
                : 'Silakan masukkan password akun Anda untuk melanjutkan perubahan pengaturan keamanan ini.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.outline, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            if (_localError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Text(
                  _localError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),

            if (!_requiresOtp) ...[
              AppInputField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: provider.obscurePassword,
                onToggleObscure: provider.toggleObscurePassword,
              ),
              const SizedBox(height: 32),
              _buildButton(
                label: 'Confirm Password',
                onPressed: provider.loading ? null : _handlePasswordConfirm,
                isLoading: provider.loading,
              ),
            ] else ...[
              AppInputField(
                controller: _otpController,
                hint: '6-digit Code',
                icon: Icons.security_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 32),
              _buildButton(
                label: 'Activate 2FA',
                onPressed: provider.loading ? null : _handleOtpVerify,
                isLoading: provider.loading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback? onPressed, required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
