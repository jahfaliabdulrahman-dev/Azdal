/// Gemini AI service for Azdal.
///
/// Wraps the google_generative_ai package for round-trip communication
/// with Google's Gemini models.
///
/// The API key is injected at **compile time** via
/// `--dart-define-from-file=.env`  — never read from the OS process
/// environment (`Platform.environment` is useless on Android).
library;

import 'package:google_generative_ai/google_generative_ai.dart';

/// Compile-time Gemini API key (injected via --dart-define-from-file=.env).
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Thin service wrapper around the Gemini generative AI SDK.
///
/// Currently supports a [ping] health-check that sends a simple prompt
/// and verifies a valid response. Future tasks (chat, vision, etc.) will
/// add dedicated methods.
final class GeminiService {
  /// The model identifier used for health checks.
  /// `gemini-flash-latest` auto-resolves to the newest available Flash model.
  static const _pingModel = 'gemini-flash-latest';

  /// Whether a valid API key was injected at compile time.
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Sends a minimal round-trip prompt to Gemini to verify connectivity.
  ///
  /// The prompt is "Reply with just: pong" — lightweight and deterministic.
  ///
  /// Returns `true` if Gemini responds successfully.
  /// Returns `false` if the compile-time key is empty, the network call
  /// fails, or the response is blocked.
  Future<bool> ping() async {
    // ── Guard: no compile-time key ─────────────────────────────────
    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping SKIPPED — '
          'GEMINI_API_KEY was not compiled into the APK.\n'
          'Build with:  flutter build apk --dart-define-from-file=.env');
      return false;
    }

    try {
      final model = GenerativeModel(
        model: _pingModel,
        apiKey: _apiKey,
      );

      final response = await model.generateContent(
        [Content.text('Reply with just: pong')],
      );

      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping response: ${response.text}');
      return response.text?.trim().toLowerCase() == 'pong';
    } on GenerativeAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping FAILED — $e');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping FAILED (unexpected) — $e');
      return false;
    }
  }
}
