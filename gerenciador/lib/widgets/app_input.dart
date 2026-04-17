import 'package:flutter/material.dart';

class AppInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool password;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.password = false,
    this.keyboardType,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _showPassword = false;

  Widget _buildLabel() {
    final label = widget.label;
    if (!label.contains('*')) {
      return Text(label);
    }

    final defaultStyle = Theme.of(context).inputDecorationTheme.labelStyle;
    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: label.split('*').asMap().entries.expand((entry) {
          final parts = <InlineSpan>[];
          if (entry.value.isNotEmpty) {
            parts.add(TextSpan(text: entry.value));
          }
          if (entry.key < label.split('*').length - 1) {
            parts.add(
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }
          return parts;
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      maxLines: widget.password ? 1 : widget.maxLines,
      obscureText: widget.password && !_showPassword,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        label: _buildLabel(),
        hintText: widget.hintText,
        errorText: widget.errorText,
        suffixIcon: widget.password
            ? IconButton(
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
              )
            : null,
      ),
    );
  }
}
