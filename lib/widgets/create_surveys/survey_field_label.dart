import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class SurveyFieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const SurveyFieldLabel({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFDEF2DF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.green600),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.green600,
          ),
        ),
      ],
    );
  }
}