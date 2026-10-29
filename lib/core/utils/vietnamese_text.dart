/// Vietnamese text helpers for accent-insensitive search.
library;

const String _accented =
    'àáạảãâầấậẩẫăằắặẳẵ'
    'èéẹẻẽêềếệểễ'
    'ìíịỉĩ'
    'òóọỏõôồốộổỗơờớợởỡ'
    'ùúụủũưừứựửữ'
    'ỳýỵỷỹ'
    'đ';

const String _plain =
    'aaaaaaaaaaaaaaaaa'
    'eeeeeeeeeee'
    'iiiii'
    'ooooooooooooooooo'
    'uuuuuuuuuuu'
    'yyyyy'
    'd';

final Map<int, int> _foldMap = {
  for (var i = 0; i < _accented.length; i++)
    _accented.codeUnitAt(i): _plain.codeUnitAt(i),
};

final RegExp _whitespace = RegExp(r'\s+');

// Combining tone/vowel marks used by decomposed (NFD) input.
final RegExp _combiningMarks = RegExp('[̀-ͯ]');

/// Lowercases [input], strips Vietnamese tone and vowel marks, maps đ/Đ to
/// `d`, trims and collapses whitespace: `normalizeVi('Đậu  Bắp') == 'dau bap'`.
String normalizeVi(String input) {
  final lower = input.toLowerCase().replaceAll(_combiningMarks, '');
  final folded = String.fromCharCodes(
    lower.codeUnits.map((unit) => _foldMap[unit] ?? unit),
  );
  return folded.trim().replaceAll(_whitespace, ' ');
}
