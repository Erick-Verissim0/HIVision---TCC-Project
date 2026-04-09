import 'package:flutter/material.dart';

class FeedbackBanner extends StatelessWidget {
  final String message;
  final bool success;

  const FeedbackBanner({
    super.key,
    required this.message,
    required this.success,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: success ? const Color(0xFF6EEF01) : Colors.redAccent,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
