/// Shared Arabic-Indic numeral normalization.
///
/// Single source of truth for converting user-typed numeric strings into
/// something `double.tryParse` can read. Previously duplicated in
/// `chat_screen.dart` (`_arabicToWestern`, digits only) and
/// `router/tools.dart` (`_normalizeDigits`, digits + comma-stripping) with
/// **divergent behavior** — the chat_screen.dart copy did not strip commas,
/// so a comma-formatted amount like "50,000" typed into any of its
/// quick-input-form fields would fail `double.tryParse` and silently fall
/// back to 0. Found during the 2026-07-21 tech-debt audit
/// (`app-spec/TECH_DEBT_AUDIT_20260721.md`, item 1). Both call sites now use
/// this single implementation.
library;

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Convert Arabic-Indic digits (٠-٩) to Western (0-9) and strip
/// thousands-separator commas, so the result is safe to pass to
/// `double.tryParse`/`int.tryParse`.
///
/// Examples: `'٥٠'` → `'50'`, `'50,000'` → `'50000'`, `'٢٠٠٠'` → `'2000'`.
String normalizeArabicNumerals(String input) {
  var result = input;
  for (var i = 0; i < _arabicDigits.length; i++) {
    result = result.replaceAll(_arabicDigits[i], '$i');
  }
  return result.replaceAll(',', '');
}
