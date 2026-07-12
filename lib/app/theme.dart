import 'package:flutter/material.dart';

/// Light-mode theme for Azdal.
///
/// Navy (#001F5E) as primary/seed, Cyan (#32C2FF) as secondary.
/// Cairo font is bundled as local assets (assets/fonts/) — no network
/// dependency on google_fonts at runtime.
class AppTheme {
  AppTheme._();

  static const Color _navy = Color(0xFF001F5E);
  static const Color _cyan = Color(0xFF32C2FF);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _navy,
      primary: _navy,
      secondary: _cyan,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
