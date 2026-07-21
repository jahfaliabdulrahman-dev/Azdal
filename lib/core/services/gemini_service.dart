/// Gemini AI service for Azdal.
///
/// Wraps the googleai_dart package (DEC-050 SDK decision, flipped
/// 2026-07-21 — pure Dart, no Firebase dependency, no App Check gate
/// needed for sideloaded APKs) for round-trip communication with Google's
/// Gemini models.
///
/// The API key is injected at **compile time** via
/// `--dart-define-from-file=.env`  — never read from the OS process
/// environment (`Platform.environment` is useless on Android).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:googleai_dart/googleai_dart.dart';

import '../../features/chat/models/chat_message.dart';

/// Compile-time Gemini API key (injected via --dart-define-from-file=.env).
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

// ─────────────────────────────────────────────────────────────────────
// Coach prompt — used ONLY for non-transaction conversational chat
// ─────────────────────────────────────────────────────────────────────

/// System prompt for Azdal's financial AI coach in Saudi Arabic dialect.
///
/// IMPORTANT: This prompt is used ONLY for conversational (non-digit)
/// messages routed through the tool-calling router's general_chat path.
/// It must never emit `action_buttons`
/// or `compound_split_card` — those are Dart-built from classification.
const _systemPrompt = '''
أنت أزدل — مدرّب مالي سعودي ودود وذكي. تتكلم باللهجة السعودية فقط، بأسلوب مشجّع ومختصر وطبيعي — مو آلي، ومو رسمي.
دورك: الرد على أسئلة المستخدم، تقديم النصائح المالية، التحفيز، والترحيب.

قواعد ثابتة:
- التطبيق يتكفّل بتسجيل المعاملات — لا ترسل action_buttons ولا compound_split_card إطلاقاً.
- لا تخترع ولا تحسب أي رقم مالي بنفسك (مجموع، نسبة، متوسط، تقدير) — إذا ما وصلك رقم حقيقي مع هذه الرسالة، لا تذكر أي رقم محدد إطلاقاً. رد بتشجيع أو توضيح عام بدون اختلاق تفاصيل.
- حالياً summary_card و bar_chart غير مفعّلين في هذا المسار — لا ترسلهما إطلاقاً. لو سُئلت عن ملخص أو تقرير مصاريف، رد بجملة ودّية تفيد إن التقرير التفصيلي قادم قريباً — بدون أي رقم.
- رد بجملة أو جملتين بس. لا تكرر نفس القالب كل مرة — نوّع بأسلوب طبيعي.

أمثلة على الأسلوب المطلوب (وحّي منها، لا تكررها حرفياً):
- تحية ("مرحبا" / "السلام عليكم") ⟶ "هلا فيك! جاهز تسجل أول مصروف اليوم أو تسألني أي شي؟"
- سؤال أداء عام بدون بيانات كافية ("كيف أدائي؟") ⟶ "أدائك يعتمد على انتظامك بالتسجيل — كل ما سجلت أكثر، قدرت أعطيك صورة أدق. جرّب تسجل يومين وشوف الفرق 📊"
- طلب شراء ("أبي أشتري جوال بـ 3000") ⟶ "خلني أحلل وضعك المالي وأعطيك قرار — كم سعر الشيء اللي تبي تشتريه؟"
- سؤال ملخص ("لخص لي مصاريفي") ⟶ "التقرير التفصيلي قادم قريب — لين ذاك، استمر تسجل كل عملية وأنا أراقب وياك 📈"
''';

// ─────────────────────────────────────────────────────────────────────
// Shared JSON helper
// ─────────────────────────────────────────────────────────────────────

/// Extract and decode a JSON object from raw LLM text.

const _coldStartReactionPrompt = '''
أنت أزدل — تصيغ جملة تفاعل واحدة على نتيجة "البداية السريعة" لمستخدم جديد، بناءً على رقمين حسبهما التطبيق مسبقاً فقط. ما عندك أي معلومة ثانية عن المستخدم.

المدخل يوصلك بصيغة JSON:
{"spend_ratio_percent": رقم, "disposable_after_commitments": رقم بالريال}
- spend_ratio_percent: نسبة مصروفه الأسبوعي التقديري من اللي يتبقى له بعد الالتزامات.
- disposable_after_commitments: كم يتبقى له شهرياً بعد الالتزامات (بالريال، قبل خصم المصروف). قد يكون سالباً.

ممنوع:
- لا تحسب ولا تقرّب ولا تعدّل أي رقم — استخدم الرقمين كما وصلوك بالضبط.
- لا تذكر أي رقم غير هذين الرقمين إطلاقاً (ممنوع دخل، التزامات، مصروف أسبوعي، أو أي رقم مشتق لم يصلك).
- لا تكرر نفس الصياغة حرفياً كل مرة — نوّع بأسلوب طبيعي.
- لا ترسل أي widget أو أي حقل JSON غير المطلوب.

أخرج JSON فقط بحقل واحد:
{"reply": "جملة أو جملتين بالكثير، لهجة سعودية دافئة ومشجعة، تعلّق على وضعه بالاعتماد على الرقمين، وتختم بدعوة لطيفة يسجل أول عملية بالصوت أو الكتابة"}

أمثلة:
- المدخل {"spend_ratio_percent": 85, "disposable_after_commitments": 2000}
  {"reply": "تصرف 85% من اللي يتبقى لك بعد الالتزامات قبل نص الشهر — خليني أساعدك تتحكم فيها أكثر. سجل أول عملية وأنا وياك 💪"}
- المدخل {"spend_ratio_percent": 35, "disposable_after_commitments": 4000}
  {"reply": "وضعك المالي معقول جداً — عندك مجال كويس بعد الالتزامات. تبي نبدأ نسجل أول عملية؟ 🎤"}
- المدخل {"spend_ratio_percent": 100, "disposable_after_commitments": -500}
  {"reply": "التزاماتك الشهرية أعلى من دخلك حالياً — هذا شي مهم ننتبه له بدري. أول خطوة: خلنا نسجل مصاريفك عشان نشوف وين نقدر نرتب 📊"}
''';

// ─────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────

/// Thin service wrapper around the Gemini generative AI SDK.
final class GeminiService {
  /// The model identifier for all Gemini calls (chat + vision/OCR).
  /// `gemini-flash-latest` auto-resolves to the newest available Flash model.
  /// Gemini Flash is natively multimodal — no separate vision model needed.
  static const _modelName = 'gemini-flash-latest';

  /// Shared client for all Gemini calls (same pattern as
  /// `GeminiRouterLlm` in `router_llm.dart` — already device-verified).
  /// Safe to construct even with an empty compile-time key; every method
  /// below guards `_apiKey.isEmpty` before making a real request.
  final GoogleAIClient _client = GoogleAIClient(
    config: GoogleAIConfig.googleAI(authProvider: ApiKeyProvider(_apiKey)),
  );

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
      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: [Content.text('Reply with just: pong')],
        ),
      );
      // ignore: avoid_print
      print('=== AZDAL DEBUG: Gemini ping response: ${response.text}');
      return response.text?.trim().toLowerCase() == 'pong';
    } on GoogleAIException catch (e) {
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
      // Build conversation history
      final contents = _buildContents(userText, history);

      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: contents,
          systemInstruction: Content.text(_systemPrompt),
        ),
      );

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
    } on GoogleAIException catch (e) {
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

  // ── Shared JSON helper ──────────────────────────────────────────

  /// Extract and decode a JSON object from raw LLM text.
  ///
  /// Strips ```json fences if present, else greedily matches the first
  /// `{...}` block.  Returns `null` on any parse failure.
  Map<String, dynamic>? _extractJsonObject(String rawText) {
    var jsonStr = rawText.trim();
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
    if (fenced != null) jsonStr = fenced.group(1)!.trim();
    final brace = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
    if (brace != null) jsonStr = brace.group(0)!;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Cold Start reaction ─────────────────────────────────────────

  /// Cold Start insight reaction.
  ///
  /// Takes ZERO user-authored text — only two numbers Dart has already
  /// computed. Cannot be a function of any prior or current conversational
  /// text, so it's history-free by construction.
  Future<GeminiResponse> reactToColdStart({
    required int spendRatio,
    required double disposableAfterCommitments,
  }) async {
    assert(_apiKey.isNotEmpty, 'GEMINI_API_KEY is empty.');
    if (_apiKey.isEmpty) {
      return const GeminiResponse(text: '');
    }

    try {
      final input = jsonEncode({
        'spend_ratio_percent': spendRatio,
        'disposable_after_commitments': disposableAfterCommitments.round(),
      });

      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: [Content.text(input)],
          systemInstruction: Content.text(_coldStartReactionPrompt),
        ),
      );
      final rawText = response.text ?? '';
      final map = _extractJsonObject(rawText);
      final reply = (map?['reply'] as String?)?.trim() ?? '';

      return GeminiResponse(text: reply);
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: reactToColdStart FAILED — $e');
      return GeminiResponse(text: '', error: e.toString());
    }
  }

  // ── Setup-intent detection (commitments/goals) ──────────────────

  // ── Legacy helpers ──────────────────────────────────────────────

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
  /// Returns a parsed JSON map with `items`, `total`, `currency`, and
  /// `reply` on success, or an error map with `error` key on failure.
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
      const prompt =
          'استخرج جميع بنود هذا الإيصال. '
          'لكل بند: اسم المنتج/الخدمة، السعر. '
          'أعد النتيجة بصيغة JSON فقط بدون أي نص آخر، بالشكل التالي:\n'
          '{"items": [{"name": "...", "price": 0}], "total": 0, "currency": "SAR", "reply": "..."}\n\n'
          'حقل reply: جملة قصيرة وحيدة بلهجة سعودية دافئة تصف نوع الإيصال اللي شفته '
          '(مثلاً مقاضي، مطعم، بنزين...) — ممنوع تذكر أي مبلغ إجمالي أو مجموع إطلاقاً '
          '(التطبيق يحسب الإجمالي بنفسه من البنود). لا تكرر نفس الصياغة حرفياً كل مرة.\n\n'
          'أمثلة على حقل reply فقط (وحّي منها، لا تنسخها حرفياً):\n'
          '- إيصال سوبرماركت فيه خضار ولحوم ومنظفات ⟶ "شكلك جبت مقاضي البيت — طلعت 5 بنود 🛒"\n'
          '- إيصال مطعم فيه أطباق وشراب ⟶ "عشاء اليوم كان في مطعم — سجلتلك كل طبق لحاله 🍽️"\n'
          '- إيصال محطة بنزين ⟶ "تعبئة بنزين — سجلتها لك ⛽"';

      final imagePart = InlineDataPart(Blob.fromBytes('image/jpeg', imageBytes));

      // ignore: avoid_print
      print('=== AZDAL DEBUG: OCR — sending to $_modelName...');

      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: [
            Content.user([imagePart, TextPart(prompt)]),
          ],
        ),
      );

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
    } on GoogleAIException catch (e) {
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
