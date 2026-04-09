String? requiredValidator(String value, String label) {
  if (value.trim().isEmpty) {
    return '$label é obrigatório';
  }
  return null;
}

String? emailValidator(String value) {
  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!regex.hasMatch(value.trim())) {
    return 'Digite um email válido';
  }
  return null;
}

String? minLengthValidator(String value, int min, String label) {
  if (value.length < min) {
    return '$label deve ter no mínimo $min caracteres';
  }
  return null;
}
