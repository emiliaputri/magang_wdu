import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login/app_input_field.dart';
import '../widgets/login/sis_logo.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider provider) async {
    FocusScope.of(context).unfocus();

    final success = await provider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/dashboard'),
          builder: (_) => const DashboardPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email atau password salah'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F8F6),
            body: Stack(
              children: [
                // ── DECORATIVE BACKGROUND ──
                _buildBackgroundBlobs(),

                // ── MAIN CONTENT ──
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 64),
                              const Center(child: SisLogo()),
                              const SizedBox(height: 52),
                              _buildCard(context, provider),
                              const SizedBox(height: 32),
                              _buildFooter(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── BACKGROUND BLOBS ──
  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -70,
          child: _blob(240, AppTheme.primaryColor, 0.22),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: _blob(100, AppTheme.primaryColor, 0.13),
        ),
        Positioned(
          bottom: -90,
          left: -60,
          child: _blob(220, AppTheme.darkGreenColor, 0.14),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  // ── LOGIN CARD ──
  Widget _buildCard(BuildContext context, AuthProvider provider) {
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
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // JUDUL
          const Text(
            'Login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selamat datang kembali',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 28),

          // EMAIL
          AppInputField(
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          // PASSWORD
          AppInputField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: provider.obscurePassword,
            onToggleObscure: provider.toggleObscurePassword,
          ),
          const SizedBox(height: 16),

          // REMEMBER ME + FORGOT PASSWORD
          _buildRememberRow(provider),
          const SizedBox(height: 28),

          // LOGIN BUTTON
          _buildLoginButton(provider),
        ],
      ),
    );
  }

  // ── REMEMBER ME ROW ──
  Widget _buildRememberRow(AuthProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: provider.toggleRememberMe,
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: provider.rememberMe,
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  onChanged: (_) => provider.toggleRememberMe(),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.darkGreenColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── LOGIN BUTTON ──
  Widget _buildLoginButton(AuthProvider provider) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: provider.loading ? null : () => _handleLogin(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: provider.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  // ── FOOTER ──
  Widget _buildFooter() {
    return Center(
      child: Text(
        "© 2024 Survey's Integrated System",
        style: TextStyle(
          fontSize: 11,
          color: AppTheme.darkGreenColor.withOpacity(0.6),
        ),
      ),
    );
  }
}
