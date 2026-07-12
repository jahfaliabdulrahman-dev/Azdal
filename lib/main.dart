import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// OCR-02: System share sheet — disabled (receive_sharing_intent broken)
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

  // ── Guest-first RLS (DEC-017): Anonymous sign-in ──
  // Creates a real auth.users row with is_anonymous=true. This gives every
  // guest a real UUID → auth.uid() works → all 14 RLS policies work unchanged.
  // Session persists on-device — guest data survives app restarts.
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentSession == null) {
    try {
      await supabase.auth.signInAnonymously();
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Anonymous sign-in successful — '
          'user_id: ${supabase.auth.currentUser?.id}');
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Anonymous sign-in FAILED — $e');
      // Non-fatal: app still renders, but writes to Supabase will fail
      // until the user is authenticated.
    }
  } else {
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Existing session found — '
        'user_id: ${supabase.auth.currentUser?.id}');
  }

  // ── System Share Sheet (Stage 3 OCR) ── DISABLED
  // receive_sharing_intent package has a kotlin() build error with AGP 8.x.
  // Will be re-enabled when we find a working version or alternative package.
  // When re-enabled, uncomment the stream listener below.
  /*
  ReceiveSharingIntent.getMediaStream().listen(
    (List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        final file = files.first;
        if (file.path.isNotEmpty) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: Shared image received — '
              'path=${file.path}');
          _pendingSharedImage = file.path;
        }
      }
    },
    onError: (Object err) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Share intent stream error — $err');
    },
  );
  */

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
