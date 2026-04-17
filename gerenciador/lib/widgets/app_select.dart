import 'package:flutter/material.dart';

class AppSelect<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  Widget _buildLabel(BuildContext context) {
    if (!label.contains('*')) {
      return Text(label);
    }

    final defaultStyle = Theme.of(context).inputDecorationTheme.labelStyle;
    final chunks = label.split('*');
    return RichText(
      text: TextSpan(
        style: defaultStyle,
        children: chunks.asMap().entries.expand((entry) {
          final parts = <InlineSpan>[];
          if (entry.value.isNotEmpty) {
            parts.add(TextSpan(text: entry.value));
          }
          if (entry.key < chunks.length - 1) {
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
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: Colors.white,
      decoration: const InputDecoration().copyWith(
        label: _buildLabel(context),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
