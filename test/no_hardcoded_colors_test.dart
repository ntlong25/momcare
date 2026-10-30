import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Phase 22 guard: every colour in `lib/` comes from the [ColorScheme],
/// the semantic tokens or the brand constants in `lib/core/theme/`.
///
/// Outside `lib/core/theme/` it fails on `Colors.` (except
/// `Colors.transparent`), `Color(0x..)` literals, `.primaryColor`,
/// `AppTheme.*Color` and `GoogleFonts` / `google_fonts`. Inside
/// `lib/core/theme/`, colour literals are only allowed in the files that
/// define the seed, the semantic token values and the documented brand
/// constants for exported images.
void main() {
  final forbidden = <String, RegExp>{
    'Colors.* (use ColorScheme roles or context.semantic)': RegExp(
      r'\bColors\.(?!transparent\b)\w+',
    ),
    'Color(0x..) literal': RegExp(r'\bColor\(\s*0x'),
    '.primaryColor (use colorScheme.primary)': RegExp(r'\.primaryColor\b'),
    'AppTheme.*Color alias': RegExp(r'\bAppTheme\.\w*Color\b'),
    'GoogleFonts (fonts are bundled)': RegExp(r'GoogleFonts|google_fonts'),
  };

  /// Only these theme files may hold colour literals.
  const literalAllowList = {
    'lib/core/theme/app_theme.dart',
    'lib/core/theme/app_tokens.dart',
  };

  String rel(File f) => f.path.replaceAll('\\', '/');

  List<File> dartFiles(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('no hard-coded colours or GoogleFonts in lib/ outside '
      'lib/core/theme/', () {
    final hits = <String>[];
    for (final file in dartFiles('lib')) {
      final path = rel(file);
      if (path.startsWith('lib/core/theme/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final MapEntry(key: reason, value: pattern) in forbidden.entries) {
          if (pattern.hasMatch(lines[i])) {
            hits.add('$path:${i + 1}: $reason\n    ${lines[i].trim()}');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('colour literals in lib/core/theme/ only in the allow-listed files', () {
    final literal = RegExp(r'\bColor\(\s*0x|\bColors\.(?!transparent\b)\w+');
    final offenders = <String>{};
    for (final file in dartFiles('lib/core/theme')) {
      final path = rel(file);
      if (literalAllowList.contains(path)) continue;
      if (file.readAsLinesSync().any(literal.hasMatch)) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });

  test('the guard patterns catch what they should', () {
    bool flagged(String line) =>
        forbidden.values.any((pattern) => pattern.hasMatch(line));
    expect(flagged('color: Colors.red,'), isTrue);
    expect(flagged('color: Colors.grey[600],'), isTrue);
    expect(flagged('color: const Color(0xFFFF9A9E),'), isTrue);
    expect(flagged('color: Theme.of(context).primaryColor,'), isTrue);
    expect(flagged('color: AppTheme.textPrimaryColor,'), isTrue);
    expect(flagged('style: GoogleFonts.poppins(),'), isTrue);
    expect(flagged('color: Colors.transparent,'), isFalse);
    expect(flagged('final s = AppSemanticColors.of(scheme);'), isFalse);
    expect(flagged('color: AppBrandColors.primary,'), isFalse);
    expect(flagged('color: scheme.primary,'), isFalse);
  });
}
