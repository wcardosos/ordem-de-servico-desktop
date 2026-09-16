import 'package:flutter/services.dart';

const int maxDocumentDigits = 14;

const int maxPhoneDigits = 11;

const int _cpfDigits = 11;

String digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String formatDocument(String value) {
  final String digits = digitsOnly(value);
  if (digits.length <= _cpfDigits) {
    return _applySeparators(digits, const <int, String>{
      3: '.',
      6: '.',
      9: '-',
    });
  }
  return _applySeparators(digits, const <int, String>{
    2: '.',
    5: '.',
    8: '/',
    12: '-',
  });
}

String formatPhone(String value) {
  final String digits = digitsOnly(value);
  if (digits.isEmpty) {
    return '';
  }
  if (digits.length <= 2) {
    return '($digits';
  }
  final String areaCode = digits.substring(0, 2);
  final String number = digits.substring(2);
  final int dashPosition = digits.length == maxPhoneDigits ? 5 : 4;
  if (number.length <= dashPosition) {
    return '($areaCode) $number';
  }
  return '($areaCode) ${number.substring(0, dashPosition)}-'
      '${number.substring(dashPosition)}';
}

String _applySeparators(String digits, Map<int, String> separators) {
  final StringBuffer buffer = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    final String? separator = separators[index];
    if (separator != null) {
      buffer.write(separator);
    }
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

class DigitMaskFormatter extends TextInputFormatter {
  const DigitMaskFormatter({required this.maxDigits, required this.format});

  DigitMaskFormatter.document()
    : this(maxDigits: maxDocumentDigits, format: formatDocument);

  DigitMaskFormatter.phone()
    : this(maxDigits: maxPhoneDigits, format: formatPhone);

  final int maxDigits;

  final String Function(String digits) format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = digitsOnly(newValue.text);
    if (digits.length > maxDigits) {
      return oldValue;
    }
    final String formatted = format(digits);
    final int cursor = newValue.selection.baseOffset < 0
        ? newValue.text.length
        : newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final int digitsBeforeCursor = digitsOnly(
      newValue.text.substring(0, cursor),
    ).length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetAfterDigits(formatted, digitsBeforeCursor),
      ),
    );
  }

  int _offsetAfterDigits(String formatted, int digitCount) {
    if (digitCount == 0) {
      return 0;
    }
    int seen = 0;
    for (int index = 0; index < formatted.length; index++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[index])) {
        seen++;
        if (seen == digitCount) {
          return index + 1;
        }
      }
    }
    return formatted.length;
  }
}
