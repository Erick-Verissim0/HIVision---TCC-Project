String normalizeDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

String formatCpf(String value) {
  final digits = normalizeDigits(value).padRight(11, '0').substring(0, 11);
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, 11)}';
}

String maskCpfForTable(String value) {
  final digits = normalizeDigits(value).padRight(11, '0').substring(0, 11);
  final tail = digits.substring(6);
  return '***.***.${tail.substring(0, 3)}-${tail.substring(3, 5)}';
}

String maskNameForTable(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '';
  }

  final blocked = {'da', 'dos', 'de', 'do', 'das', 'e'};
  final visible = <int>{};

  bool valid(String word) => word.length >= 4 && !blocked.contains(word.toLowerCase());

  int? pick(int preferred) {
    if (preferred >= 0 && preferred < parts.length && !visible.contains(preferred) && valid(parts[preferred])) {
      return preferred;
    }

    for (var i = preferred + 1; i < parts.length; i += 1) {
      if (!visible.contains(i) && valid(parts[i])) {
        return i;
      }
    }

    for (var i = (preferred - 1).clamp(0, parts.length - 1); i >= 0; i -= 1) {
      if (!visible.contains(i) && valid(parts[i])) {
        return i;
      }
    }

    return null;
  }

  for (final preferred in [0, 2]) {
    final idx = pick(preferred);
    if (idx != null) {
      visible.add(idx);
    }
  }

  return parts
      .asMap()
      .entries
      .map((entry) => visible.contains(entry.key) ? entry.value : '*' * entry.value.length)
      .join(' ');
}

String toDateOnly(String? iso) {
  if (iso == null || iso.isEmpty) {
    return '-';
  }

  final dt = DateTime.tryParse(iso);
  if (dt == null) {
    return '-';
  }

  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  return '$day/$month/${dt.year}';
}
