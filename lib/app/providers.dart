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

/// Reactive provider for voice listening state.
///
/// Updated internally by [VoiceService] from the speech recognizer's
/// `onStatus` callback — every status transition automatically pushes
/// a new state. Widgets that `ref.watch` this rebuild when the mic
/// is activated or deactivated from any cause (tap, timeout, internal
/// recognizer event).
final voiceListeningProvider =
    StateNotifierProvider<VoiceListeningNotifier, VoiceListeningState>(
  (ref) => VoiceListeningNotifier(),
);

/// Singleton provider for the voice input service.
///
/// Injected with [VoiceListeningNotifier] so the service can push
/// listening-state updates reactively.
final voiceServiceProvider = Provider<VoiceService>(
  (ref) => VoiceService(ref.read(voiceListeningProvider.notifier)),
);

/// Singleton provider for the transaction persistence service.
final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(),
);
