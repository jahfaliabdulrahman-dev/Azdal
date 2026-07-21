/// Abstract LLM interface for the tool-calling router.
///
/// Decouples the router from any specific AI SDK. Implementation backed by
/// `googleai_dart` (DEC-050 SDK decision, flipped 2026-07-21) — pure Dart,
/// no Firebase dependency, works with the sideloaded APK distribution path.
///
/// See: DEC-050, 23_research_tool_calling_router.md §1
library;

import 'package:googleai_dart/googleai_dart.dart';

import 'tool_types.dart';

/// The model's response to a routing call.
///
/// [toolCalls] is non-empty when the model chose one or more tools.
/// [text] is the fallback when the model chose NOT to call a tool
/// (which should be rare under forced-ANY mode, but is handled).
final class RouterLlmResponse {
  const RouterLlmResponse({
    this.toolCalls = const [],
    this.text,
    this.finishReason,
  });

  /// Tool calls the model chose (name → args map).
  final List<Map<String, Object?>> toolCalls;

  /// Raw text if the model replied without calling a tool.
  final String? text;

  /// The finish reason from the underlying API (best-effort; not currently
  /// surfaced by googleai_dart's Candidate model, kept for interface parity).
  final String? finishReason;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

/// Abstract interface for the LLM backing the tool-calling router.
///
/// Implementations:
/// - [GeminiRouterLlm] — uses googleai_dart (DEC-050 primary SDK).
abstract interface class RouterLlm {
  /// Route a single user message through the model with the given tool
  /// declarations and forced-ANY tool config.
  ///
  /// The model MUST be configured with [FunctionCallingMode.any] and
  /// [allowedFunctionNames] set to the set of all tool names so that it
  /// always chooses a tool (never falls through to raw text silently).
  ///
  /// [stateBlock] is a compact, Dart-authored JSON string describing
  /// the current routing context (pending clarifications, etc.) — never
  /// the raw transcript.
  Future<RouterLlmResponse> route({
    required String userText,
    required String stateBlock,
    required List<RouterTool<Object?>> tools,
  });

  /// Send a free-form coach chat message (used by the `general_chat` tool).
  /// This is the ONLY path that still passes filtered history to the coach
  /// prompt — all other paths are single-hop tool dispatches.
  Future<String> chat({
    required String userText,
    required String stateBlock,
    required List<Map<String, String>> history,
  });

  /// Whether this LLM backend is properly configured and ready.
  bool get isConfigured;
}

/// googleai_dart implementation of [RouterLlm].
///
/// DEC-050 primary SDK (flipped 2026-07-21) — pure Dart client, no Firebase
/// dependency, works with the sideloaded APK distribution path. Kept behind
/// the [RouterLlm] interface so a future swap (e.g. to firebase_ai, should
/// App Check ever become viable) stays a one-file change.
final class GeminiRouterLlm implements RouterLlm {
  GeminiRouterLlm({required String apiKey, String model = 'gemini-flash-latest'})
      : _apiKey = apiKey,
        _modelName = model,
        _client = GoogleAIClient(
          config: GoogleAIConfig.googleAI(
            authProvider: ApiKeyProvider(apiKey),
          ),
        );

  final String _apiKey;
  final String _modelName;
  final GoogleAIClient _client;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<RouterLlmResponse> route({
    required String userText,
    required String stateBlock,
    required List<RouterTool<Object?>> tools,
  }) async {
    if (_apiKey.isEmpty) {
      return const RouterLlmResponse(text: 'API key not configured');
    }

    final toolList = Tool(
      functionDeclarations: [
        for (final t in tools) t.declaration,
      ],
    );

    final toolConfig = ToolConfig(
      functionCallingConfig: FunctionCallingConfig(
        mode: FunctionCallingMode.any,
        allowedFunctionNames: [for (final t in tools) t.name],
      ),
    );

    try {
      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: [Content.text(userText)],
          tools: [toolList],
          toolConfig: toolConfig,
          systemInstruction: Content.text(_routerSystemPrompt(stateBlock)),
        ),
      );

      final toolCalls = <Map<String, Object?>>[
        for (final call in response.functionCalls)
          {'name': call.name, 'args': call.args},
      ];

      return RouterLlmResponse(
        toolCalls: toolCalls,
        text: response.text,
      );
    } on GoogleAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: RouterLlm.route FAILED — $e');
      return RouterLlmResponse(text: e.toString());
    }
  }

  @override
  Future<String> chat({
    required String userText,
    required String stateBlock,
    required List<Map<String, String>> history,
  }) async {
    if (_apiKey.isEmpty) return 'عذراً — مفتاح API غير متوفر.';

    final contents = <Content>[];
    for (final h in history) {
      if (h['role'] == 'user') {
        contents.add(Content.text(h['text']!));
      }
    }
    // Always include the latest message
    contents.add(Content.text(userText));

    try {
      final response = await _client.models.generateContent(
        model: _modelName,
        request: GenerateContentRequest(
          contents: contents,
          systemInstruction: Content.text(_coachSystemPrompt(stateBlock)),
        ),
      );
      return response.text ?? '';
    } on GoogleAIException catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: RouterLlm.chat FAILED — $e');
      return 'عذراً — حدث خطأ في الاتصال بالمساعد الذكي.';
    }
  }

  /// Build the router system prompt with the current state block.
  static String _routerSystemPrompt(String stateBlock) => '''
أنت محرّك توجيه لتطبيق "أزدل" المالي. مهمتك: تحليل رسالة المستخدم واختيار الأداة المناسبة من القائمة.
$stateBlock

قواعد ثابتة:
- اختر دائماً أداة واحدة من القائمة — لا ترد بنص عادي أبداً.
- general_chat لأي رسالة لا تنطبق عليها أي أداة أخرى (سلام، شكر، سؤال عام، نصيحة).
- ask_clarification إذا كان قصد المستخدم غير واضح وتحتاج توضيح.
- لا تخترع أي رقم مالي بنفسك — فقط استخرج الأرقام من رسالة المستخدم كما هي.
- استخدم general_chat لأسئلة "كيف" و"ليش" و"وش تنصحني" العامة.
''';

  /// Build the coach system prompt (used ONLY by the general_chat tool).
  static String _coachSystemPrompt(String stateBlock) => '''
أنت أزدل — مدرّب مالي سعودي ودود وذكي. تتكلم باللهجة السعودية فقط، بأسلوب مشجّع ومختصر وطبيعي — مو آلي، ومو رسمي.
$stateBlock

قواعد ثابتة:
- لا تخترع ولا تحسب أي رقم مالي بنفسك (مجموع، نسبة، متوسط، تقدير) — إذا ما وصلك رقم حقيقي، لا تذكر أي رقم محدد إطلاقاً.
- رد بجملة أو جملتين بس. لا تكرر نفس القالب كل مرة — نوّع بأسلوب طبيعي.
- التطبيق يتكفّل بتسجيل المعاملات وعرض التقارير — لا ترسل أي JSON أو widgets.
''';
}
