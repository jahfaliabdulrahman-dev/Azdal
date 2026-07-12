/// Voice input service for Azdal.
///
/// Wraps the `speech_to_text` package to provide Arabic voice transcription
/// via Android's native SpeechRecognizer (DEC-016).
///
/// Usage:
/// ```dart
/// final voiceService = VoiceService();
/// await voiceService.initialize();
/// await voiceService.startListening();
/// // ... user speaks ...
/// final text = await voiceService.stopListening();
/// ```
library;

import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service wrapping speech-to-text for Arabic voice input.
final class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// The transcribed text from the most recent listen session.
  String _lastResult = '';

  /// Whether the service has been initialized and is ready.
  bool get isInitialized => _speech.isAvailable;

  /// Whether currently listening.
  bool get isListening => _speech.isListening;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _speech.isAvailable;

  /// Initialize the speech recognizer.
  ///
  /// Returns `true` if initialization succeeded, `false` if speech
  /// recognition is not available or permission was denied.
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: Voice recognition error — $error');
        },
        onStatus: (status) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: Voice status — $status');
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
  /// Transcripts accumulate in [lastResult] as the user speaks.
  /// Call [stopListening] to finalize and retrieve the text.
  Future<bool> startListening() async {
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
        ),
        onResult: (result) {
          _lastResult = result.recognizedWords;
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
