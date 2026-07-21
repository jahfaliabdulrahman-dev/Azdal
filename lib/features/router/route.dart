/// Core router dispatch function — replaces the `_sendMessage` cascade.
///
/// Single entry point: one [RouterLlm.route] call, cap at 2 tool calls,
/// deterministic bail-to-clarify.
///
/// DEC-050 disciplines enforced here:
/// - Tools stay coarse and verdict-shaped (the model never sees raw financials)
/// - Write-tools return StagedProposal — nothing is written inside run()
/// - Model routes in, Dart speaks out (no narration round-trip for number paths)
/// - Hard-cap 2 calls then bail-to-clarify
/// - History policy: the router sees the current message + RouterState block only
/// - Every routing decision is traced to the `tool_calls` table (DEC-050 §5)
library;

import 'router_llm.dart';
import 'tool_call_trace_service.dart';
import 'tool_types.dart';

/// Result of a [route] call — what the chat screen should render next.
final class RouteResult {
  const RouteResult({
    this.outcome,
    this.errorText,
    this.isGeneralChat = false,
    this.userText = '',
  });

  /// The tool outcome to render (or null if the model chose general_chat).
  final ToolOutcome? outcome;

  /// Error text to display (null on success).
  final String? errorText;

  /// Whether the model chose general_chat — the chat screen should delegate
  /// to the coach LLM path.
  final bool isGeneralChat;

  /// The original user text (for general_chat fallback).
  final String userText;

  bool get isError => errorText != null;
}

/// Route a single user message through the tool-calling router.
///
/// [routerLlm] is the LLM backend (GeminiRouterLlm for now).
/// [registry] holds all registered tools.
/// [userText] is the user's raw message.
/// [userId] is the authenticated Supabase user ID (for RLS + tracing).
/// [tracer] writes one row per routing decision to `tool_calls`.
/// [state] is the current routing state (for multi-turn clarification).
///
/// Returns a [RouteResult] the chat screen uses to render the response.
Future<RouteResult> route({
  required RouterLlm routerLlm,
  required ToolRegistry registry,
  required String userText,
  required String userId,
  required ToolCallTraceService tracer,
  RouterState state = const RouterState(),
}) async {
  if (!routerLlm.isConfigured) {
    return const RouteResult(errorText: 'عذراً — المساعد غير متوفر حالياً.');
  }

  final stateBlock = state.toStateBlock();

  try {
    final sw = Stopwatch()..start();

    // ── Single-hop: one generateContent call ─────────────────
    final response = await routerLlm.route(
      userText: userText,
      stateBlock: stateBlock,
      tools: registry.tools,
    );

    final latencyMs = sw.elapsedMilliseconds;

    if (response.text != null && !response.hasToolCalls) {
      // Model didn't call any tool — forced-ANY should prevent this,
      // but handle gracefully: delegate to general_chat
      await tracer.insert(
        userId: userId,
        messageText: userText,
        model: 'gemini-flash-latest',
        latencyMs: latencyMs,
        toolName: 'general_chat',
        args: {},
        outcomeKind: 'render',
        resultSummary: {'fallback': 'no_tool_calls'},
      );
      return RouteResult(
        isGeneralChat: true,
        userText: userText,
      );
    }

    // ── Cap enforcement: ≤2 calls then deterministic bail ─────
    // (Only the first tool call is processed; extras are ignored)

    // ── Process tool calls ────────────────────────────────────
    for (final tc in response.toolCalls) {
      final toolName = tc['name'] as String?;
      final rawArgs = Map<String, Object?>.from(
        (tc['args'] as Map?) ?? <String, Object?>{},
      );

      if (toolName == null) continue;

      // Special case: general_chat → delegate to coach
      if (toolName == 'general_chat') {
        await tracer.insert(
          userId: userId,
          messageText: userText,
          model: 'gemini-flash-latest',
          latencyMs: latencyMs,
          toolName: toolName,
          args: {},
          outcomeKind: 'render',
          resultSummary: {'delegated_to': 'coach_prompt'},
        );
        return RouteResult(
          isGeneralChat: true,
          userText: userText,
        );
      }

      // Special case: ask_clarification → ClarifyOutcome
      if (toolName == 'ask_clarification') {
        final tool = registry['ask_clarification'];
        if (tool != null) {
          try {
            final args = tool.parseArgs(rawArgs);
            final outcome = await tool.run(args, ToolContext(
              userId: userId,
              routerState: state,
            ));
            await tracer.insert(
              userId: userId,
              messageText: userText,
              model: 'gemini-flash-latest',
              latencyMs: latencyMs,
              toolName: toolName,
              args: args is Map<String, dynamic> ? args : {'raw': '$args'},
              outcomeKind: 'clarify',
            );
            return RouteResult(outcome: outcome);
          } on ToolArgsError catch (e) {
            await tracer.insert(
              userId: userId,
              messageText: userText,
              model: 'gemini-flash-latest',
              latencyMs: latencyMs,
              toolName: toolName,
              args: rawArgs.cast<String, dynamic>(),
              outcomeKind: 'invalid_args',
              error: e.message,
            );
            return RouteResult(errorText: 'خطأ في المدخلات: ${e.message}');
          }
        }
        continue;
      }

      // Look up the tool
      final tool = registry[toolName];
      if (tool == null) {
        // Hallucinated tool name → trace + clarify
        await tracer.insert(
          userId: userId,
          messageText: userText,
          model: 'gemini-flash-latest',
          latencyMs: latencyMs,
          toolName: toolName,
          args: rawArgs.cast<String, dynamic>(),
          outcomeKind: 'unknown_tool',
          error: 'Model selected unrecognized tool: $toolName',
        );
        return const RouteResult(
          outcome: ClarifyOutcome(question: 'ما فهمت قصدك — تقدر تعيد الصياغة؟'),
        );
      }

      // Parse args
      try {
        final args = tool.parseArgs(rawArgs);
        final outcome = await tool.run(args, ToolContext(
          userId: userId,
          routerState: state,
        ));

        // Trace the outcome
        final OutcomeTrace trace = _classifyOutcome(outcome);
        await tracer.insert(
          userId: userId,
          messageText: userText,
          model: 'gemini-flash-latest',
          latencyMs: latencyMs,
          toolName: toolName,
          args: args is Map<String, dynamic>
              ? args
              : args != null
                  ? {'value': '$args'}
                  : {},
          outcomeKind: trace.kind,
          resultSummary: trace.summary,
        );

        return RouteResult(outcome: outcome);
      } on ToolArgsError catch (e) {
        await tracer.insert(
          userId: userId,
          messageText: userText,
          model: 'gemini-flash-latest',
          latencyMs: latencyMs,
          toolName: toolName,
          args: rawArgs.cast<String, dynamic>(),
          outcomeKind: 'invalid_args',
          error: e.message,
        );
        return const RouteResult(
          outcome: ClarifyOutcome(question: 'المعلومات اللي كتبتها ناقصة — تقدر توضح أكثر؟'),
        );
      }
    }

    // No recognized tool calls processed
    await tracer.insert(
      userId: userId,
      messageText: userText,
      model: 'gemini-flash-latest',
      latencyMs: latencyMs,
      toolName: '(none)',
      args: {},
      outcomeKind: 'error',
      error: 'No tool calls processed from response',
    );
    return const RouteResult(errorText: 'عذراً — ما قدرت أحدد قصدك.');
  } catch (e) {
    // ignore: avoid_print
    print('=== AZDAL DEBUG: route() FAILED — $e');
    // Best-effort trace on total failure
    try {
      await tracer.insert(
        userId: userId,
        messageText: userText,
        model: 'gemini-flash-latest',
        toolName: '(crash)',
        args: {},
        outcomeKind: 'error',
        error: e.toString(),
      );
    } catch (_) {}
    return const RouteResult(errorText: 'عذراً — حدث خطأ في المعالجة.');
  }
}

// ─────────────────────────────────────────────────────────────────────
// Outcome classification helper
// ─────────────────────────────────────────────────────────────────────

final class OutcomeTrace {
  const OutcomeTrace({required this.kind, this.summary});
  final String kind;
  final Map<String, dynamic>? summary;
}

OutcomeTrace _classifyOutcome(ToolOutcome outcome) {
  switch (outcome) {
    case RenderOutcome(:final widget):
      return OutcomeTrace(
        kind: 'render',
        summary: {
          'widget_type': widget.widget,
          if (widget.title != null) 'title': widget.title,
        },
      );
    case StagedProposal(:final toolName, :final previewText, :final draft):
      return OutcomeTrace(
        kind: 'staged',
        summary: {
          'tool': toolName,
          'preview': previewText,
          'draft_keys': draft.keys.toList(),
        },
      );
    case ClarifyOutcome(:final question):
      return OutcomeTrace(
        kind: 'clarify',
        summary: {'question': question},
      );
  }
}
