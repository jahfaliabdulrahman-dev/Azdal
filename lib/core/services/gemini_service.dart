/// Gemini AI service for Azdal.
///
/// Wraps the google_generative_ai package for round-trip communication
/// with Google's Gemini models.
///
/// The API key is injected at **compile time** via
/// `--dart-define-from-file=.env`  — never read from the OS process
/// environment (`Platform.environment` is useless on Android).
library;

import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../features/chat/models/chat_message.dart';

/// Compile-time Gemini API key (injected via --dart-define-from-file=.env).
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

/// System prompt for Azdal's financial AI coach in Saudi Arabic dialect.
const _systemPrompt = '''
أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط.
تصنف المعاملات (فئة/فئة فرعية/نبرة: أخضر/رمادي/أحمر).
تولد واجهات من 6 أنواع (summary_card, bar_chart, action_buttons, quick_input_form, goal_progress_card, compound_split_card).
لا تحسب أبداً — الحسابات على Supabase.
إذا احتجت توضيحاً — اسأل. لا تخمن.

عند تصنيف معاملة، أرسل رداً يحتوي على JSON widget بالصيغة التالية:
```json
{
  "widget": "action_buttons",
  "question": "هل التصنيف صحيح؟",
  "buttons": [
    {"label": "✅ صحيح", "value": "confirm", "type": "primary"},
    {"label": "🔄 تعديل", "value": "edit", "type": "secondary"}
  ]
}
```

عند وجود عدة عناصر في معاملة واحدة (مثل "٤٧٥ مقاضي: ١٥٠ مقهى + ١٧٥ خضار + ١٥٠ مطعم")، استخدم compound_split_card.

عند السؤال عن ملخص المصاريف، استخدم summary_card أو bar_chart.
''';

/// Thin service wrapper around the Gemini generative AI SDK.
final class GeminiService {
  /// The model identifier.
  /// `gemini-flash-latest` auto-resolves to the newest available Flash model.
  static const _modelName = 'gemini-flash-latest';

  /// Whether a valid API key was injected at compile time.
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Sends a minimal round-trip prompt to Gemini to verify connectivity.
  Future<bool> ping() async {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY is empty.');

    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping SKIPPED — '
          'GEMINI_API_KEY was not compiled into the APK.');
      return false;
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
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

  /// Send a user message to Gemini and get the AI response.
  ///
  /// [userText] is the user's latest message.
  /// [history] is the conversation history (for multi-turn context).
  ///
  /// Returns a [GeminiResponse] containing the reply text and an optional
  /// widget JSON payload parsed from the model's output.
  Future<GeminiResponse> sendMessage(
    String userText, {
    List<ChatMessage> history = const [],
  }) async {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY is empty.');

    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini sendMessage SKIPPED — no API key');
      return const GeminiResponse(
        text: 'عذراً — مفتاح API غير متوفر.',
      );
    }

    // ignore: avoid_print
    print('=== AZDAL DEBUG: Gemini sendMessage — '
        '"${userText.length > 50 ? '${userText.substring(0, 50)}...' : userText}"');

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );

      // Build conversation history
      final contents = _buildContents(userText, history);

      final response = await model.generateContent(contents);

      final rawText = response.text ?? '';
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini raw response (${rawText.length} chars)');

      // Try to extract a JSON widget from the response
      final widget = _extractWidget(rawText);
      final cleanText = _stripJsonBlock(rawText);

      return GeminiResponse(
        text: cleanText.isNotEmpty ? cleanText : rawText,
        widget: widget,
      );
    } on GenerativeAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini sendMessage FAILED — $e');
      return GeminiResponse(
        text: 'عذراً — حدث خطأ في الاتصال بالمساعد الذكي.',
        error: e.toString(),
      );
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini sendMessage FAILED (unexpected) — $e');
      return GeminiResponse(
        text: 'عذراً — حدث خطأ غير متوقع.',
        error: e.toString(),
      );
    }
  }

  /// Build the list of Content objects from user text + history.
  List<Content> _buildContents(
    String userText,
    List<ChatMessage> history,
  ) {
    final contents = <Content>[];

    // Add history (max last 10 turns to stay within context limits)
    final recentHistory = history.length > 20 ? history.sublist(history.length - 20) : history;
    for (final msg in recentHistory) {
      if (msg.isUser) {
        contents.add(Content.text(msg.content));
      }
      // We skip bot messages from history to keep context lighter;
      // Gemini already has its own history from the chat session.
    }

    // Always include the latest user message
    if (contents.isEmpty || contents.last.parts.first is! TextPart) {
      contents.add(Content.text(userText));
    }

    return contents;
  }

  /// Extract a JSON widget block from the response text.
  ///
  /// Looks for ```json ... ``` code blocks and parses the JSON inside.
  /// Returns null if no valid widget JSON is found.
  Map<String, dynamic>? _extractWidget(String text) {
    final regex = RegExp(r'```json\s*([\s\S]*?)```', multiLine: true);
    final match = regex.firstMatch(text);
    if (match == null) return null;

    try {
      final jsonStr = match.group(1)!.trim();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      // Only return if it has a valid widget type
      if (decoded.containsKey('widget')) return decoded;
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Failed to parse widget JSON — $e');
      return null;
    }
  }

  /// Remove the JSON code block from the text to get clean display text.
  String _stripJsonBlock(String text) {
    return text.replaceAll(RegExp(r'```json[\s\S]*?```', multiLine: true), '').trim();
  }
}

/// Response from [GeminiService.sendMessage].
final class GeminiResponse {
  const GeminiResponse({
    required this.text,
    this.widget,
    this.error,
  });

  /// Clean plain-text reply.
  final String text;

  /// Optional widget JSON payload (parsed from the response).
  final Map<String, dynamic>? widget;

  /// Error string if the call failed (null on success).
  final String? error;

  /// Whether this response contains an error.
  bool get hasError => error != null;
}
