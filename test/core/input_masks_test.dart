import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordem_de_servico/core/input_masks.dart';

void main() {
  TextEditingValue typed(String text, {int? cursor}) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: cursor ?? text.length),
  );

  group('digitsOnly', () {
    test('strips every non-digit character', () {
      expect(digitsOnly('(83) 99999-1234'), '83999991234');
      expect(digitsOnly('12.345.678/0001-95'), '12345678000195');
      expect(digitsOnly(''), '');
    });
  });

  group('formatDocument', () {
    test('formats a CPF progressively while typing', () {
      expect(formatDocument(''), '');
      expect(formatDocument('123'), '123');
      expect(formatDocument('1234'), '123.4');
      expect(formatDocument('1234567'), '123.456.7');
      expect(formatDocument('1234567890'), '123.456.789-0');
      expect(formatDocument('12345678900'), '123.456.789-00');
    });

    test('switches to the CNPJ mask from the twelfth digit', () {
      expect(formatDocument('123456789001'), '12.345.678/9001');
      expect(formatDocument('1234567800019'), '12.345.678/0001-9');
      expect(formatDocument('12345678000195'), '12.345.678/0001-95');
    });

    test('formats values that already carry a mask', () {
      expect(formatDocument('123.456.789-00'), '123.456.789-00');
    });
  });

  group('formatPhone', () {
    test('formats a phone progressively while typing', () {
      expect(formatPhone(''), '');
      expect(formatPhone('8'), '(8');
      expect(formatPhone('83'), '(83');
      expect(formatPhone('833'), '(83) 3');
      expect(formatPhone('833222'), '(83) 3222');
      expect(formatPhone('8332221'), '(83) 3222-1');
    });

    test('uses 4+4 digits for landlines and 5+4 for mobiles', () {
      expect(formatPhone('8332221234'), '(83) 3222-1234');
      expect(formatPhone('83999991234'), '(83) 99999-1234');
    });
  });

  group('DigitMaskFormatter', () {
    test('masks typed digits and keeps the cursor after the last digit', () {
      final TextEditingValue result = DigitMaskFormatter.phone()
          .formatEditUpdate(typed(''), typed('83999991234'));

      expect(result.text, '(83) 99999-1234');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('ignores input beyond the maximum number of digits', () {
      final TextEditingValue previous = typed('(83) 99999-1234');

      final TextEditingValue phone = DigitMaskFormatter.phone()
          .formatEditUpdate(previous, typed('(83) 99999-12345'));
      final TextEditingValue document = DigitMaskFormatter.document()
          .formatEditUpdate(
            typed('12.345.678/0001-95'),
            typed('12.345.678/0001-951'),
          );

      expect(phone, previous);
      expect(document.text, '12.345.678/0001-95');
    });

    test('drops letters and symbols', () {
      final TextEditingValue result = DigitMaskFormatter.document()
          .formatEditUpdate(typed(''), typed('abc123.45x6'));

      expect(result.text, '123.456');
    });

    test('keeps the cursor next to the edited digit when editing mid-text', () {
      final TextEditingValue result = DigitMaskFormatter.document()
          .formatEditUpdate(
            typed('123.456.789-00'),
            typed('1239.456.789-00', cursor: 4),
          );

      expect(result.text, '12.394.567/8900');
      expect(result.selection.baseOffset, 5);
    });
  });
}
