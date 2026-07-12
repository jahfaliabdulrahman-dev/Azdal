import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/core/services/gemini_service.dart';

/// Tests for [GeminiService].
///
/// These tests adapt to the environment:
/// - When `GEMINI_API_KEY` is set: a real round-trip [ping] is attempted.
/// - When the key is missing: we verify the service reports `isConfigured == false`
///   and that [ping] returns `false` gracefully.
void main() {
  late GeminiService service;

  setUp(() {
    service = GeminiService();
  });

  group('GeminiService configuration', () {
    test('can be instantiated', () {
      expect(service, isA<GeminiService>());
    });

    test('isConfigured matches env state', () {
      final hasKey = Platform.environment['GEMINI_API_KEY'] != null &&
          Platform.environment['GEMINI_API_KEY']!.isNotEmpty;
      expect(service.isConfigured, hasKey);
    });
  });

  group('GeminiService ping', () {
    test('returns false when API key is missing', () async {
      if (service.isConfigured) {
        // Key is present — we can't test the missing-key path.
        // Skip with a message rather than failing.
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Skipping missing-key test — '
            'GEMINI_API_KEY is set.');
        return;
      }
      final result = await service.ping();
      expect(result, isFalse);
    });

    test('returns true on successful round-trip', () async {
      if (!service.isConfigured) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: Skipping live ping test — '
            'GEMINI_API_KEY is not set.');
        return;
      }
      final result = await service.ping();
      expect(result, isTrue,
          reason: 'Gemini did not respond with "pong". '
              'Check API key validity and network.');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
