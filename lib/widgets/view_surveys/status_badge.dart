import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isOpen;

  const StatusBadge({super.key, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'DIBUKA' : 'DITUTUP',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOpen ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}