import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/login/app_input_field.dart';
import '../widgets/login/sis_logo.dart';
import 'dashboard_page.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final bool isActivationFlow;
  const OtpPage({
    super.key, 
    required this.email, 
    this.isActivationFlow = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      _showSnackBar('Kode verifikasi harus 6 digit', isError: true);
      return;
    }

    final provider = context.read<AuthProvider>();
    
    if (widget.isActivationFlow) {
      // 2FA Activation Flow
      final success = await provider.confirm2FA(code);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true); // Return to SettingsPage
      } else {
        _showSnackBar(provider.errorMessage ?? 'Kode salah atau kedaluwarsa', isError: true);
      }
    } else {
      // Standard Login Flow
      final success = await provider.verifyOtp(code);
      if (!mounted) return;
      if (success) {
        // Initialize notifications and websockets
        if (mounted) {
          context.read<NotificationProvider>().init();
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      } else {
        _showSnackBar(provider.errorMessage ?? 'Kode salah atau kedaluwarsa', isError: true);
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    final provider = context.read<AuthProvider>();
    final message = await provider.resendOtp();

    if (!mounted) return;

    if (message != null) {
      _showSnackBar(message, isError: false);
      _startResendTimer();
    } else {
      _showSnackBar(provider.errorMessage ?? 'Gagal mengirim ulang kode', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.darkGreenColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F6),
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 64),
                    const SisLogo(),
                    const SizedBox(height: 52),
                    _buildCard(provider),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: provider.loading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Kembali',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AuthProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 36,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isActivationFlow ? 'Konfirmasi 2FA' : 'Verifikasi 2FA',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kode verifikasi telah dikirim ke\n${widget.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 32),
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
          _buildVerifyButton(provider),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                _canResend
                    ? 'Tidak menerima kode?'
                    : 'Kirim ulang dalam $_secondsRemaining detik',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: (provider.loading || !_canResend) ? null : _handleResend,
                child: Text(
                  'Kirim ulang',
                  style: TextStyle(
                    fontSize: 13,
                    color: _canResend ? AppTheme.darkGreenColor : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    decoration: _canResend ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(AuthProvider provider) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: provider.loading ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: provider.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Konfirmasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -70,
          child: _circle(240, AppTheme.primaryColor, 0.15),
        ),
        Positioned(
          bottom: -90,
          left: -60,
          child: _circle(220, AppTheme.darkGreenColor, 0.1),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
    );
  }
}
