/// Core tool-calling router types for Azdal.
///
/// Grounded in DEC-050 and 23_research_tool_calling_router.md §2.
/// All types are pure Dart — no Flutter dependency (testable offline).
library;

import 'package:googleai_dart/googleai_dart.dart';

// ─────────────────────────────────────────────────────────────────────
// ToolOutcome — sealed result types
// ─────────────────────────────────────────────────────────────────────

/// Sealed result from running a [RouterTool].
///
/// - [RenderOutcome]: a read-tool produced a widget to display immediately.
/// - [StagedProposal]: a write-tool produced a draft that needs user approval.
/// - [ClarifyOutcome]: the tool needs more info before it can proceed.
sealed class ToolOutcome {
  const ToolOutcome();
}

/// A read-tool ran successfully — render this widget.
final class RenderOutcome extends ToolOutcome {
  const RenderOutcome({required this.widget});
  final ChatWidgetSpec widget;
}

/// A write-tool drafted a proposal — show it for user approval.
/// NOTHING was written to the database (DEC-020/021).
final class StagedProposal extends ToolOutcome {
  const StagedProposal({
    required this.toolName,
    required this.draft,
    required this.previewText,
    this.confirmLabel = 'تأكيد ✓',
    this.undoLabel = '↩️ تراجع',
  });
  final String toolName;
  final Map<String, dynamic> draft;
  final String previewText;
  final String confirmLabel;
  final String undoLabel;
}

/// The tool needs clarification — a hardcoded Dart question (BRP-exempt).
final class ClarifyOutcome extends ToolOutcome {
  const ClarifyOutcome({required this.question});
  final String question;
}

// ─────────────────────────────────────────────────────────────────────
// ChatWidgetSpec — what the widget catalog needs to render
// ─────────────────────────────────────────────────────────────────────

/// Spec for rendering a widget from the existing catalog.
///
/// Mirrors the existing JSON widget format so the rendering code
/// in chat_screen.dart works unchanged.
final class ChatWidgetSpec {
  const ChatWidgetSpec({
    required this.widget,
    this.title,
    this.tone,
    this.rows,
    this.question,
    this.buttons,
    this.fields,
    this.submitLabel,
    this.items,
    this.draft,
    this.nameHint,
    this.txId,
    this.txType,
    this.purchaseItem,
    this.purchaseAmount,
    this.purchaseReply,
    this.purchaseDisposable,
  });

  final String widget;
  final String? title;
  final String? tone;
  final List<Map<String, dynamic>>? rows;
  final String? question;
  final List<Map<String, dynamic>>? buttons;
  final List<Map<String, dynamic>>? fields;
  final String? submitLabel;
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? draft;
  final String? nameHint;
  final String? txId;
  final String? txType;
  final String? purchaseItem;
  final int? purchaseAmount;
  final String? purchaseReply;
  final double? purchaseDisposable;

  Map<String, dynamic> toJson() => {
        'widget': widget,
        if (title != null) 'title': title,
        if (tone != null) 'tone': tone,
        if (rows != null) 'rows': rows,
        if (question != null) 'question': question,
        if (buttons != null) 'buttons': buttons,
        if (fields != null) 'fields': fields,
        if (submitLabel != null) 'submit_label': submitLabel,
        if (items != null) 'items': items,
        if (draft != null) 'draft': draft,
        if (nameHint != null) 'name_hint': nameHint,
        if (txId != null) 'tx_id': txId,
        if (txType != null) 'tx_type': txType,
        if (purchaseItem != null) 'purchase_item': purchaseItem,
        if (purchaseAmount != null) 'purchase_amount': purchaseAmount,
        if (purchaseReply != null) 'purchase_reply': purchaseReply,
        if (purchaseDisposable != null) 'purchase_disposable': purchaseDisposable,
      };
}

// ─────────────────────────────────────────────────────────────────────
// RouterState — compact Dart-authored context (never raw transcript)
// ─────────────────────────────────────────────────────────────────────

/// Compact routing context, authored by Dart (never the raw transcript).
///
/// Carries zero financial magnitudes — only intent-level state, per
/// DEC-050 rule 5 (\"RouterState contains no financial values\").
final class RouterState {
  const RouterState({
    this.pendingTool,
    this.pendingItem,
    this.pendingMissing = const [],
  });

  /// The tool that is waiting for missing arguments.
  final String? pendingTool;

  /// A partial item name (e.g. \"ساعة\" from a buy-intent with no amount).
  final String? pendingItem;

  /// What's missing (e.g. [\"amount\"]).
  final List<String> pendingMissing;

  bool get hasPending => pendingTool != null;

  /// Build the state block string sent to the LLM router.
  String toStateBlock() {
    if (!hasPending) return '';
    final missing = pendingMissing.join('، ');
    return 'حالة معلّقة: الأداة \"$pendingTool\" تنتظر توضيح — ناقص: $missing.';
  }
}

// ─────────────────────────────────────────────────────────────────────
// RouterTool — one routable intent
// ─────────────────────────────────────────────────────────────────────

/// Permission tier for a tool (DEC-020/021).
enum WriteTier {
  /// Read-only — no writes ever. Render immediately.
  none,

  /// Auto-save with undo button (single transactions).
  autoSaveWithUndo,

  /// Show confirm/edit card before saving (compounds, commitments, goals).
  confirmCard,
}

/// Exception thrown by [RouterTool.parseArgs] on invalid input.
final class ToolArgsError implements Exception {
  const ToolArgsError(this.message);
  final String message;

  @override
  String toString() => 'ToolArgsError: $message';
}

/// One routable intent wrapping an existing pure-Dart service.
///
/// Each tool is one file under `lib/features/router/tools/`.
/// Adding a new tool touches exactly one file — zero dispatcher lines.
///
/// Type parameter [A] is the parsed-args type (often `Map<String, dynamic>`).
abstract class RouterTool<A> {
  /// Unique tool name (e.g. 'evaluate_purchase', 'log_expense').
  /// Must match the function declaration name exactly.
  String get name;

  /// The Gemini FunctionDeclaration for this tool.
  /// Descriptions must be in Arabic (Saudi dialect).
  FunctionDeclaration get declaration;

  /// The write tier — governs whether the tool produces a
  /// [RenderOutcome], [StagedProposal], or writes directly.
  WriteTier get tier;

  /// Parse and validate raw args from the model.
  /// Throws [ToolArgsError] on invalid input.
  /// Must normalize Arabic-Indic digits (٠-٩ → 0-9).
  A parseArgs(Map<String, Object?> raw);

  /// Execute the tool. Receives parsed args and context.
  /// Returns a sealed [ToolOutcome].
  Future<ToolOutcome> run(A args, ToolContext ctx);
}

/// Context passed to [RouterTool.run].
final class ToolContext {
  const ToolContext({
    required this.userId,
    required this.routerState,
  });

  /// The current authenticated user's ID.
  final String userId;

  /// The current router state (for multi-turn clarification flow).
  final RouterState routerState;
}

// ─────────────────────────────────────────────────────────────────────
// ToolRegistry — open/closed (DEC-050, research doc §2)
// ─────────────────────────────────────────────────────────────────────

/// Central registry of all routable tools.
///
/// Adding intent N+1 touches zero dispatcher lines — register the new
/// [RouterTool] here and the router picks it up automatically.
final class ToolRegistry {
  ToolRegistry(this._tools);

  final List<RouterTool<Object?>> _tools;

  /// All registered tool names (for forced-ANY allowed set).
  Set<String> get toolNames => {for (final t in _tools) t.name};

  /// Look up a tool by name. Returns null if the model hallucinated
  /// a name — the router treats this as a clarify-outcome.
  RouterTool<Object?>? operator [](String name) {
    for (final t in _tools) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// The tool list for the LLM call.
  List<RouterTool<Object?>> get tools => List.unmodifiable(_tools);
}
