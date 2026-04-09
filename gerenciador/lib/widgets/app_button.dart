import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final bool outline;
  final bool round;
  final bool disabled;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.title,
    this.onPressed,
    this.color,
    this.textColor,
    this.outline = false,
    this.round = false,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFF550402);
    final fgColor = textColor ?? Colors.white;

    return ElevatedButton.icon(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: outline ? Colors.transparent : buttonColor,
        foregroundColor: outline ? buttonColor : fgColor,
        side: BorderSide(color: buttonColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(round ? 999 : 12),
        ),
      ),
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(title),
    );
  }
}
