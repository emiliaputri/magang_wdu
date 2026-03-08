import 'package:flutter/material.dart';

class SisLogo extends StatelessWidget {
  final double height;

  const SisLogo({super.key, this.height = 50});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/SIS-WDU-logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}