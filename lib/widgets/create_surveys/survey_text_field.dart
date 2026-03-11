import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class SurveyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const SurveyTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFAFDFA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}