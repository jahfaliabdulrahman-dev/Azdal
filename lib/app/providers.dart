/// Provider declarations for Azdal.
///
/// This file centralises Riverpod providers used across the app.
/// Each section groups providers by domain (services, features, etc.).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/gemini_service.dart';
import '../features/chat/services/transaction_service.dart';
import '../features/chat/services/voice_service.dart';

// ─────────────────────────────────────────────────────────────────────
// Services
// ─────────────────────────────────────────────────────────────────────

/// Singleton provider for the Gemini AI service.
final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);

/// Singleton provider for the voice input service.
final voiceServiceProvider = Provider<VoiceService>(
  (ref) => VoiceService(),
);

/// Singleton provider for the transaction persistence service.
final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(),
);
