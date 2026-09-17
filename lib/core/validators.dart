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

double? parseDecimal(String? value) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  final String normalized = text.contains(',')
      ? text.replaceAll('.', '').replaceAll(',', '.')
      : text;
  return double.tryParse(normalized);
}

String? validatePartDescription(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe a descrição da peça.';
  }
  return null;
}

String? validateQuantity(String? value) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Informe a quantidade.';
  }
  final int? quantity = int.tryParse(text);
  if (quantity == null) {
    return 'Informe um número inteiro válido.';
  }
  if (quantity <= 0) {
    return 'A quantidade deve ser maior que zero.';
  }
  return null;
}

String? validateUnitPrice(String? value) =>
    _validateAmount(value, 'Informe o valor unitário.');

String? validateLaborCost(String? value) =>
    _validateAmount(value, 'Informe o valor da mão de obra.');

String? _validateAmount(String? value, String missingMessage) {
  final String text = value?.trim() ?? '';
  if (text.isEmpty) {
    return missingMessage;
  }
  final double? amount = parseDecimal(text);
  if (amount == null) {
    return 'Informe um valor válido.';
  }
  if (amount < 0) {
    return 'O valor não pode ser negativo.';
  }
  return null;
}
