import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// OCR-02: System share sheet (Stage 3)
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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

  // ── DEC-051: no anonymous/guest sign-in ──
  // The app requires email/password login from first launch, so every account
  // is permanent from message one. The router's auth gate (app_router.dart)
  // sends any unauthenticated launch to /login and restores an existing
  // permanent session automatically (supabase_flutter persists it on-device).
  //
  // Transition safety: a device upgrading from the pre-DEC-051 build may still
  // hold a persisted ANONYMOUS session. Sign it out so the gate requires a real
  // login rather than silently continuing on throwaway guest data.
  final auth = Supabase.instance.client.auth;
  if (auth.currentUser?.isAnonymous ?? false) {
    await auth.signOut();
  }

  // ── System Share Sheet (Stage 3 OCR) ── DISABLED
  // receive_sharing_intent has kotlin() build error with AGP 8.x.
  // Will re-enable when fixed.
  // ReceiveSharingIntent.instance.getMediaStream().listen(
  //   (List<SharedMediaFile> files) { ... },
  //   onError: (Object err) { ... },
  // );

  runApp(const ProviderScope(child: AzdalApp()));
}

/// Pending shared image path — set by the share intent stream,
/// consumed once by ChatScreen, then cleared.
String? _pendingSharedImage;

/// Public accessor for pending shared image.
/// Called once by ChatScreen, then clears the pending value.
String? consumePendingSharedImage() {
  final path = _pendingSharedImage;
  _pendingSharedImage = null;
  return path;
}

/// Provider that holds the path of a system-shared image, consumed by ChatScreen.
final sharedImagePathProvider = StateProvider<String?>((ref) => null);

/// Root widget — RTL, light theme, MaterialApp.router + go_router.
///
/// RTL is enforced via locale + localizationsDelegates, NOT a manual
/// Directionality wrapper: MaterialApp's own Localizations widget always
/// re-inserts a fresh Directionality below itself, derived from the
/// active WidgetsLocalizations — with no delegates configured that
/// defaults to LTR and silently overrides any outer wrapper. Setting
/// locale: ar (with the standard Global*Localizations delegates) makes
/// that framework-derived Directionality RTL instead, which is what
/// every screen actually needs to inherit.
class AzdalApp extends StatelessWidget {
  const AzdalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'أزدل',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
