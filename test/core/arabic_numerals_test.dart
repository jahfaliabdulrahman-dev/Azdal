import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/core/utils/arabic_numerals.dart';

/// Regression test for the 2026-07-21 tech-debt audit finding (item 1):
/// `chat_screen.dart` and `router/tools.dart` used to each implement their
/// own Arabic-Indic digit normalizer, and only the router's copy stripped
/// thousands-separator commas. A comma-formatted amount typed into any of
/// `chat_screen.dart`'s 14 quick-input-form fields would silently fail
/// `double.tryParse` and fall back to 0. Both call sites now share this one
/// implementation — this test locks in the comma-stripping behavior so that
/// regression can't reappear silently in either caller again.
void main() {
  group('normalizeArabicNumerals', () {
    test('converts Arabic-Indic digits to Western', () {
      expect(normalizeArabicNumerals('٥٠'), '50');
      expect(normalizeArabicNumerals('٢٠٠٠'), '2000');
      expect(normalizeArabicNumerals('٠'), '0');
    });

    test('strips thousands-separator commas (the bug this fixes)', () {
      expect(normalizeArabicNumerals('50,000'), '50000');
      expect(normalizeArabicNumerals('1,234,567'), '1234567');
    });

    test('handles combined Arabic digits + commas', () {
      expect(normalizeArabicNumerals('٥٠,٠٠٠'), '50000');
    });

    test('is a no-op on already-clean Western input', () {
      expect(normalizeArabicNumerals('1500'), '1500');
    });

    test('leaves non-numeric text untouched aside from digit/comma swaps',
        () {
      expect(normalizeArabicNumerals('٥٠ ريال'), '50 ريال');
    });

    test('comma-formatted input is now parseable by double.tryParse', () {
      // This is the actual failure mode found in the audit: before the
      // fix, chat_screen.dart's normalizer left the comma in place, and
      // double.tryParse('50,000') returns null, which every call site
      // then silently defaulted to 0.
      final parsed = double.tryParse(normalizeArabicNumerals('50,000'));
      expect(parsed, 50000.0);
    });
  });
}
