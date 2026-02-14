import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class IdrCurrencyInputFormatter extends TextInputFormatter {
  IdrCurrencyInputFormatter();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  static int parseToInt(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return 0;
    }
    return int.parse(digitsOnly);
  }

  static String formatFromInt(int value) {
    return _formatter.format(value);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(digitsOnly);
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
