import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  final bool isLoggedIn;
  final String? initialRoute;
  final Map<String, dynamic>? initialArgs;

  const SplashPage({
    super.key,
    required this.isLoggedIn,
    this.initialRoute,
    this.initialArgs,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Tunda selama 2 detik untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (widget.initialRoute != null) {
      Navigator.pushReplacementNamed(
        context,
        widget.initialRoute!,
        arguments: widget.initialArgs,
      );
    } else {
      if (widget.isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background warna putih sedikit kehijauan
      backgroundColor: const Color(0xFFF4FAF5),
      body: Center(
        child: Image.asset(
          'assets/images/SIS-WDU-logo.png',
          width: 200,
        ),
      ),
    );
  }
}
