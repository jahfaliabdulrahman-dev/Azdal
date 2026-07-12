/// Voice input service for Azdal.
///
/// Wraps the `speech_to_text` package to provide Arabic voice transcription
/// via Android's native SpeechRecognizer (DEC-016).
///
/// Listening state is Riverpod-reactive via [VoiceListeningNotifier] —
/// the service updates the notifier from its internal `onStatus` callback
/// so the UI rebuilds automatically on any status transition, whether
/// triggered by a user tap, a timeout, or an internal recognizer event.
///
/// Usage:
/// ```dart
/// final voiceService = VoiceService(listeningNotifier);
/// await voiceService.initialize();
/// await voiceService.startListening(onResult: (text, isFinal) { ... });
/// // ... user speaks, UI reactively shows listening state ...
/// final text = await voiceService.stopListening();
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ─────────────────────────────────────────────────────────────────────
// VoiceListeningState
// ─────────────────────────────────────────────────────────────────────

/// Immutable state for voice listening, exposed via Riverpod.
final class VoiceListeningState {
  const VoiceListeningState({
    this.isListening = false,
    this.error,
  });

  /// Whether the speech recognizer is currently active.
  final bool isListening;

  /// Optional error string (e.g. permission denied).
  final String? error;

  VoiceListeningState copyWith({
    bool? isListening,
    String? error,
    bool clearError = false,
  }) {
    return VoiceListeningState(
      isListening: isListening ?? this.isListening,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// VoiceListeningNotifier
// ─────────────────────────────────────────────────────────────────────

/// [StateNotifier] that manages [VoiceListeningState].
///
/// Updated by [VoiceService] from its internal `onStatus` callback —
/// every status transition ("listening" → true, "notListening"/"done" → false)
/// pushes a new state, causing any `ref.watch(voiceListeningProvider)` to rebuild.
final class VoiceListeningNotifier extends StateNotifier<VoiceListeningState> {
  VoiceListeningNotifier() : super(const VoiceListeningState());

  /// Called by [VoiceService] when the recognizer status changes.
  void setListening(bool value) {
    if (state.isListening != value) {
      state = state.copyWith(isListening: value, clearError: true);
    }
  }

  /// Called by [VoiceService] when a permanent error occurs.
  void setError(String message) {
    state = state.copyWith(isListening: false, error: message);
  }
}

// ─────────────────────────────────────────────────────────────────────
// VoiceService
// ─────────────────────────────────────────────────────────────────────

/// Service wrapping speech-to-text for Arabic voice input.
///
/// Takes a [VoiceListeningNotifier] so it can push listening-state updates
/// reactively from the recognizer's internal status callback — no manual
/// `setState()` required in the UI layer.
final class VoiceService {
  VoiceService(this._listeningNotifier);

  final VoiceListeningNotifier _listeningNotifier;
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// The transcribed text from the most recent listen session.
  String _lastResult = '';

  /// Whether the service has been initialized and is ready.
  bool get isInitialized => _speech.isAvailable;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _speech.isAvailable;

  /// Initialize the speech recognizer.
  ///
  /// Registers the [VoiceListeningNotifier] to track status changes
  /// from the recognizer's internal [onStatus] callback — every transition
  /// automatically updates Riverpod state.
  ///
  /// Returns `true` if initialization succeeded, `false` if speech
  /// recognition is not available or permission was denied.
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: Voice recognition error — $error');
          _listeningNotifier.setError(error.errorMsg);
        },
        onStatus: (status) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: Voice status — $status');
          // Every status transition pushes to Riverpod — the UI
          // rebuilds reactively, no manual setState() needed.
          _listeningNotifier.setListening(status == 'listening');
        },
      );
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice service initialized — '
          'available=$available');
      return available;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice service init FAILED — $e');
      return false;
    }
  }

  /// Start listening for Arabic speech.
  ///
  /// [onResult] is called on every recognition result (interim and final)
  /// with the recognized text and whether this is a final result.
  /// Use this to provide live feedback in the text field as the user speaks.
  ///
  /// Transcripts also accumulate in [lastResult].
  /// Call [stopListening] to finalize and retrieve the text.
  Future<bool> startListening({
    void Function(String text, bool isFinal)? onResult,
  }) async {
    if (!_speech.isAvailable) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice startListening SKIPPED — '
          'not available');
      return false;
    }

    _lastResult = '';

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'ar_SA',
          partialResults: true,
          pauseFor: const Duration(seconds: 2),
        ),
        onResult: (result) {
          _lastResult = result.recognizedWords;
          onResult?.call(result.recognizedWords, result.finalResult);
        },
      );
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice listening started');
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice startListening FAILED — $e');
      return false;
    }
  }

  /// Stop listening and return the transcribed text.
  ///
  /// Returns the full recognized string, or an empty string if nothing
  /// was recognized or listening was never started.
  Future<String> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice stopListening error — $e');
    }
    final result = _lastResult;
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Voice result — "$result"');
    return result;
  }

  /// Cancel listening without retrieving the result.
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Voice cancel error — $e');
    }
  }
}
