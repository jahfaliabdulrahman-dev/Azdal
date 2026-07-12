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
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../features/chat/models/chat_message.dart';

/// Compile-time Gemini API key (injected via --dart-define-from-file=.env).
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

/// System prompt for Azdal's financial AI coach in Saudi Arabic dialect.
///
/// IMPORTANT: This prompt deliberately does NOT instruct Gemini to emit
/// `action_buttons` or `compound_split_card` JSON for transaction
/// classifications.  The app constructs ALL transaction widgets locally
/// from the dedicated `classifyTransaction` call, which runs without
/// conversation history so it cannot conflate a prior transaction with
/// the current one.  The main chat response should just describe in
/// plain Arabic — the app handles the widget generation.
const _systemPrompt = '''
أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط.
دورك: مساعدة المستخدم في رحلته المالية — نصائح، توضيح، تحفيز.
التطبيق يتولى تصنيف المعاملات — لا ترسل action_buttons أو compound_split_card.
عبر عن ردودك بنص عادي. لا تحسب أبداً — الحسابات على Supabase.
إذا احتجت توضيحاً — اسأل سؤالاً واحداً واضحاً. لا تخمن.

عند السؤال عن ملخص المصاريف، استخدم summary_card أو bar_chart.
''';

/// Thin service wrapper around the Gemini generative AI SDK.
final class GeminiService {
  /// The model identifier for all Gemini calls (chat + vision/OCR).
  /// `gemini-flash-latest` auto-resolves to the newest available Flash model.
  /// Gemini Flash is natively multimodal — no separate vision model needed.
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

  // ── Classification (dedicated — no main _systemPrompt interference) ──

  /// Classification-specific system prompt.
  ///
  /// Separate from [_systemPrompt] so the classification instructions
  /// (compound_split_card, JSON extraction) don't conflict with the main
  /// chat prompt's "express in plain text" directive.
  /// Only used by [classifyTransaction] — the main chat response uses
  /// [_systemPrompt] and will never see these widget instructions.
  static const _classifySystemPrompt = '''
أنت نظام تصنيف معاملات مالية. مهمتك الوحيدة: تحليل النص واستخراج البيانات.
أجب بصيغة JSON فقط، بدون أي نص آخر — لا تقدم شرحاً ولا اعتذاراً.

للمعاملة الواحدة:
{"amount": الرقم, "category": "الفئة", "subcategory": "الفئة الفرعية", "tone": "green أو gray أو red"}

لعدة عناصر في نفس الرسالة:
{"widget": "compound_split_card", "splits": [{"category": "...", "amount": الرقم}]}

إذا لم تكن معاملة مالية:
{"error": "NOT_TRANSACTION"}
''';

  /// Classify a single user message as a transaction.
  ///
  /// Uses [_classifySystemPrompt] — NOT [_systemPrompt] — so Gemini
  /// receives explicit JSON-formatting instructions without conflicting
  /// with the main chat prompt's "express in plain text" directive.
  ///
  /// No conversation history is sent — each classification is isolated
  /// to the current message, preventing prior transactions from leaking in.
  Future<GeminiResponse> classifyTransaction(String userText) async {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY is empty.');

    if (_apiKey.isEmpty) {
      return const GeminiResponse(text: '{}');
    }

    // ignore: avoid_print
    print('=== AZDAL DEBUG: classifyTransaction — '
        '"${userText.length > 50 ? '${userText.substring(0, 50)}...' : userText}"');

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(_classifySystemPrompt),
      );

      final response = await model.generateContent([
        Content.text(userText),
      ]);

      final rawText = response.text ?? '';
      final widget = _extractWidget(rawText);

      return GeminiResponse(text: rawText, widget: widget);
    } on GenerativeAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: classifyTransaction FAILED — $e');
      return GeminiResponse(text: '{}', error: e.toString());
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: classifyTransaction FAILED (unexpected) — $e');
      return GeminiResponse(text: '{}', error: e.toString());
    }
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

  // ── OCR (Stage 3) ─────────────────────────────────────────────────

  /// OCR a receipt image using Gemini Vision.
  ///
  /// [imageBytes] is the raw JPEG/PNG bytes of the receipt photo.
  ///
  /// Returns a parsed JSON map with `items`, `total`, and `currency` on
  /// success, or an error map with `error` key on failure.
  ///
  /// The Arabic prompt instructs Gemini to extract each line item — product
  /// name and price — and return a structured JSON response.
  Future<Map<String, dynamic>> ocrReceipt(Uint8List imageBytes) async {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY is empty.');

    if (_apiKey.isEmpty) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR SKIPPED — no API key');
      return {'error': 'GEMINI_API_KEY is empty'};
    }

    // ignore: avoid_print
    print('=== AZDAL DEBUG: OCR started — '
        'image size=${imageBytes.length} bytes');

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
      );

      const prompt =
          'استخرج جميع بنود هذا الإيصال. '
          'لكل بند: اسم المنتج/الخدمة، السعر. '
          'أعد النتيجة بصيغة JSON فقط بدون أي نص آخر: '
          '{"items": [{"name": "...", "price": 0}], "total": 0, "currency": "SAR"}';

      final imagePart = DataPart('image/jpeg', imageBytes);

      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR — sending to $_modelName...');

      final response = await model.generateContent([
        Content.multi([imagePart, TextPart(prompt)]),
      ]);

      final rawText = response.text ?? '';
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR raw response — '
          '"${rawText.length > 200 ? '${rawText.substring(0, 200)}...' : rawText}"');

      // Extract JSON from response (may be wrapped in ```json blocks)
      final jsonMatch = RegExp(
        r'(\{[\s\S]*"items"[\s\S]*\})',
        multiLine: true,
      ).firstMatch(rawText);

      final jsonStr = jsonMatch?.group(1)?.trim() ?? rawText.trim();

      try {
        final result = jsonDecode(jsonStr) as Map<String, dynamic>;

        final items = result['items'];
        if (items == null || items is! List || items.isEmpty) {
          // ignore: avoid_print
          print('=== AZDAL DEBUG: OCR — no items extracted');
          return {
            'error': 'no_items',
            'raw_response': rawText,
          };
        }

        // ignore: avoid_print
        print('=== AZDAL DEBUG: OCR success — '
            '${items.length} items, total=${result['total']}');
        return result;
      } catch (e) {
        // ignore: avoid_print
        print('=== AZDAL DEBUG: OCR JSON parse FAILED — $e');
        return {
          'error': 'parse_failed',
          'raw_response': rawText,
          'detail': e.toString(),
        };
      }
    } on GenerativeAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR Gemini FAILED — $e');
      return {'error': 'gemini_error', 'detail': e.toString()};
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR FAILED (unexpected) — $e');
      return {'error': 'unexpected', 'detail': e.toString()};
    }
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
