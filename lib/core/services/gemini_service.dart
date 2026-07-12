/// Gemini AI service for Azdal.
///
/// Wraps the google_generative_ai package for round-trip communication
/// with Google's Gemini models. The API key is read from the environment
/// variable `GEMINI_API_KEY` — never hardcoded.
///
/// Usage:
/// ```dart
/// final service = GeminiService();
/// final isAlive = await service.ping();
/// ```
library;

import 'dart:io' show Platform;

import 'package:google_generative_ai/google_generative_ai.dart';

/// Thin service wrapper around the Gemini generative AI SDK.
///
/// Currently supports a [ping] health-check that sends a simple prompt
/// and verifies a valid response. Future tasks (chat, vision, etc.) will
/// add dedicated methods.
final class GeminiService {
  /// The model identifier used for health checks.
  /// Using flash for low-latency pings.
  static const _pingModel = 'gemini-1.5-flash-latest';

  /// The API key loaded from the `GEMINI_API_KEY` environment variable.
  ///
  /// Returns `null` when the variable is not set, signalling that the
  /// service cannot make real API calls.
  String? get _apiKey => Platform.environment['GEMINI_API_KEY'];

  /// Whether a valid API key has been detected.
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Sends a minimal round-trip prompt to Gemini to verify connectivity.
  ///
  /// The prompt is "Reply with just: pong" — lightweight and deterministic.
  ///
  /// Returns `true` if Gemini responds successfully.
  /// Returns `false` if the API key is missing, the network call fails,
  /// or the response is blocked.
  ///
  /// Debug output is printed to the console with the `=== AZDAL DEBUG:`
  /// prefix for easy log filtering.
  Future<bool> ping() async {
    final apiKey = _apiKey;

    // ── Guard: no API key ──────────────────────────────────────────
    if (apiKey == null || apiKey.isEmpty) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping SKIPPED — '
          'GEMINI_API_KEY is not set.');
      return false;
    }

    try {
      final model = GenerativeModel(
        model: _pingModel,
        apiKey: apiKey,
      );

      final response = await model.generateContent(
        [Content.text('Reply with just: pong')],
      );

      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping response: ${response.text}');
      // Trimmed comparison handles whitespace / newlines from the model.
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
