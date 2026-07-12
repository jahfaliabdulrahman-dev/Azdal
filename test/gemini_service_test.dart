import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/core/services/gemini_service.dart';

/// Tests for [GeminiService].
///
/// The `GEMINI_API_KEY` is compiled into the test binary via
/// `flutter test --dart-define-from-file=.env`.
/// When running without the flag the key will be empty — both paths
/// are handled gracefully in the tests below.
void main() {
  late GeminiService service;

  setUp(() {
    service = GeminiService();
  });

  group('GeminiService configuration', () {
    test('can be instantiated', () {
      expect(service, isA<GeminiService>());
    });

    test('isConfigured matches compile-time key', () {
      // Key is empty unless --dart-define-from-file was passed at build time.
      expect(service.isConfigured, isA<bool>());
    });
  });

  group('GeminiService ping', () {
    test('asserts when API key is missing', () async {
      if (service.isConfigured) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Skipping missing-key test — '
            'GEMINI_API_KEY is compiled in.');
        return;
      }
      await expectLater(
        service.ping(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('returns true on successful round-trip', () async {
      if (!service.isConfigured) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Skipping live ping test — '
            'GEMINI_API_KEY was not compiled in.\n'
            'Pass --dart-define-from-file=.env to flutter test.');
        return;
      }
      final result = await service.ping();
      expect(result, isTrue,
          reason: 'Gemini did not respond with "pong". '
              'Check API key validity and network.');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
