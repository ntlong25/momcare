/// VND formatting for optional checklist prices (Phase 19, B7).
///
/// Done by hand so it does not depend on intl locale data.
library;

/// Max digits accepted by [parseVndInput] (999.999.999 đ).
const int vndMaxDigits = 9;

/// Formats [amount] with dot thousands separators: `1250000` -> "1.250.000 đ".
String formatVnd(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer đ';
}

/// Parses user input such as "1.250.000" by stripping every non-digit.
/// Returns null for an empty result, 0, or more than [vndMaxDigits] digits.
int? parseVndInput(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty || digits.length > vndMaxDigits) return null;
  final value = int.parse(digits);
  return value <= 0 ? null : value;
}
