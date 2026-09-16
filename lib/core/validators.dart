String? requiredField(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe o $fieldName.';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null) {
    return 'Informe um e-mail válido.';
  }
  final int atIndex = value.indexOf('@');
  final bool hasCharBeforeAt = atIndex >= 1;
  final bool hasDotAfterAt =
      atIndex >= 0 && value.indexOf('.', atIndex + 1) > atIndex;
  if (!hasCharBeforeAt || !hasDotAfterAt) {
    return 'Informe um e-mail válido.';
  }
  return null;
}

String? validatePhone(String? value) {
  if (value == null) {
    return 'Informe um telefone válido.';
  }
  final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length != 10 && digits.length != 11) {
    return 'Informe um telefone válido.';
  }
  return null;
}
