/// Provider declarations for Azdal.
///
/// This file centralises Riverpod providers used across the app.
/// Each section groups providers by domain (services, features, etc.).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/gemini_service.dart';

// ─────────────────────────────────────────────────────────────────────
// Services
// ─────────────────────────────────────────────────────────────────────

/// Singleton provider for the Gemini AI service.
///
/// The service reads its API key from the `GEMINI_API_KEY` environment
/// variable at runtime.  If the key is not set, callers can check
/// `geminiServiceProvider.isConfigured` or handle graceful fallback.
final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);
