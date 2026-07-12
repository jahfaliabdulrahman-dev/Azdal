import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_router.dart';
import 'app/theme.dart';

// ── Compile-time credentials (injected via --dart-define-from-file=.env) ──
// These are baked into the APK at build time — NOT read from the OS
// process environment.  On Android `Platform.environment` does NOT contain
// the developer's shell vars.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Fail loud — never silently proceed with empty credentials ──
  assert(
    _supabaseUrl.isNotEmpty,
    'SUPABASE_URL is empty.\n'
    'Build with:  flutter build apk --dart-define-from-file=.env\n'
    'Or use:      bash scripts/build_debug.sh',
  );
  assert(
    _supabaseKey.isNotEmpty,
    'SUPABASE_ANON_KEY is empty.\n'
    'Build with:  flutter build apk --dart-define-from-file=.env\n'
    'Or use:      bash scripts/build_debug.sh',
  );

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseKey,
  );

  runApp(const ProviderScope(child: AzdalApp()));
}

/// Root widget — RTL, light theme, MaterialApp.router + go_router.
class AzdalApp extends StatelessWidget {
  const AzdalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        title: 'أزدل',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
