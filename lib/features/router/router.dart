/// Tool-calling router for Azdal chat — Phase 0.5 (DEC-050).
///
/// Replaces the hand-maintained cascade of Arabic regex intent-gates with
/// Gemini native function-calling used as a single-hop tool dispatcher.
///
/// Architecture (from research doc 23_research_tool_calling_router.md):
/// - [RouterLlm] — abstract interface behind which the LLM SDK lives
///   (googleai_dart — DEC-050 SDK decision, flipped 2026-07-21)
/// - [RouterTool] — one routable intent wrapping an existing pure-Dart service
/// - [ToolOutcome] — sealed result: RenderOutcome | StagedProposal | ClarifyOutcome
/// - [ToolRegistry] — open/closed registry; adding a tool touches zero dispatcher lines
/// - [route] — single entry point; one generateContent call, cap ≤2 then bail-to-clarify
library;

export 'router_llm.dart';
export 'tool_types.dart';
export 'route.dart';
export 'tool_call_trace_service.dart';
