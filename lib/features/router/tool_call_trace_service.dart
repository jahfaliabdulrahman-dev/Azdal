/// Trace service for the `tool_calls` audit table.
///
/// One row per routing decision — message → tool → args → outcome.
/// The trace is inserted at routing time, before the user confirms,
/// so the full funnel (routed → staged → confirmed/undone) is captured.
///
/// Schema: `supabase/migrations/20260721220000_tool_calls.sql`
/// Specification: `app-spec/27_tool_calls_trace_table.md`
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Writes one row to the `tool_calls` trace table per routing decision.
final class ToolCallTraceService {
  ToolCallTraceService(this._client);

  final SupabaseClient _client;

  /// Insert a trace row. Returns the new row's UUID, or null on failure.
  ///
  /// [userId] is the authenticated user's UUID (required by RLS).
  /// [model] is the LLM model alias (e.g. 'gemini-flash-latest').
  /// [latencyMs] is the round-trip ms from generateContent to parsed response.
  /// [toolName] is the RouterTool.name the model selected.
  /// [args] are the parsed+validated arguments (Arabic-Indic normalized).
  /// [outcomeKind] is one of: render, staged, clarify, invalid_args, unknown_tool, error.
  /// [resultSummary] is a compact JSON summary of the outcome.
  /// [error] is set only for failure outcomes.
  Future<String?> insert({
    required String userId,
    required String messageText,
    required String model,
    int? latencyMs,
    required String toolName,
    required Map<String, dynamic> args,
    required String outcomeKind,
    Map<String, dynamic>? resultSummary,
    String? error,
  }) async {
    if (userId.isEmpty) return null; // safety — RLS would reject it anyway
    try {
      final data = {
        'user_id': userId,
        'message_text': messageText,
        'model': model,
        'tool_name': toolName,
        'args': args,
        'outcome_kind': outcomeKind,
        if (latencyMs != null) 'latency_ms': latencyMs,
        if (resultSummary != null) 'result_summary': resultSummary,
        if (error != null) 'error': error,
      };
      final response = await _client.from('tool_calls').insert(data).select('id').single();
      return response['id'] as String?;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: ToolCallTraceService.insert FAILED — $e');
      return null;
    }
  }

  /// Backfill [writeIds] for a staged proposal after the user confirms.
  Future<void> backfillWriteIds(String traceId, List<String> writeIds) async {
    try {
      await _client
          .from('tool_calls')
          .update({'write_ids': writeIds})
          .eq('id', traceId);
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: ToolCallTraceService.backfillWriteIds FAILED — $e');
    }
  }
}
