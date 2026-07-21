/// Unit tests for the tool-calling router (DEC-050, Phase 0.5).
///
/// Covers what the golden intent matrix (test/fixtures/golden_intent_matrix.jsonl)
/// deliberately does NOT: the router's own mechanics — tool lookup, argument
/// parsing/validation, and the route() dispatch loop — using a [FakeRouterLlm]
/// so no real LLM network call ever happens.
///
/// Two tiers:
/// 1. Pure, network-free: ToolRegistry lookup + parseArgs on every tool.
///    Real service instances are constructed (PurchaseDecisionService etc.
///    are all `final class` — cannot be faked/mocked via implements, so a
///    throwaway SupabaseClient pointed at an RFC 2606 reserved-invalid host
///    is used instead). parseArgs never touches the service (verified by
///    reading tools.dart), so this is still fully deterministic and offline.
/// 2. route() integration: same throwaway-client pattern for the required
///    ToolCallTraceService (also `final`); its own insert()/backfillWriteIds()
///    already catch every exception internally and return null/void
///    (verified by reading tool_call_trace_service.dart), so this should
///    degrade gracefully rather than throw or hang. Written and reasoned
///    through carefully, but not executed — no Flutter/Dart toolchain in the
///    authoring sandbox. If any of these prove slow/flaky on a real
///    `flutter test` run, this file is the first place to look.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:googleai_dart/googleai_dart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:azdal/features/router/router.dart';
import 'package:azdal/features/router/tools.dart';
import 'package:azdal/features/chat/services/commitment_service.dart';
import 'package:azdal/features/chat/services/goal_service.dart';
import 'package:azdal/features/chat/services/integrity_score_service.dart';
import 'package:azdal/features/chat/services/purchase_decision_service.dart';

/// A throwaway Supabase client for constructing real service/tool instances
/// in tests that never actually exercise the network path (parseArgs never
/// touches the service; ToolCallTraceService swallows its own errors).
SupabaseClient _unreachableClient() =>
    SupabaseClient('https://router-test.invalid', 'fake-anon-key');

// ─────────────────────────────────────────────────────────────────────
// FakeRouterLlm — programmable RouterLlm test double, zero network calls
// ─────────────────────────────────────────────────────────────────────

/// A [RouterLlm] test double whose response is set ahead of time.
///
/// Records every call to [route] and [chat] so tests can assert on
/// call count (e.g. proving route() only ever makes one generateContent
/// call per user message, per DEC-050 rule 4).
final class FakeRouterLlm implements RouterLlm {
  FakeRouterLlm({
    RouterLlmResponse? routeResponse,
    String chatResponse = 'رد تجريبي',
  })  : _routeResponse = routeResponse ?? const RouterLlmResponse(),
        _chatResponse = chatResponse;

  final RouterLlmResponse _routeResponse;
  final String _chatResponse;

  int routeCallCount = 0;
  int chatCallCount = 0;
  String? lastUserText;
  List<RouterTool<Object?>>? lastTools;

  @override
  bool get isConfigured => true;

  @override
  Future<RouterLlmResponse> route({
    required String userText,
    required String stateBlock,
    required List<RouterTool<Object?>> tools,
  }) async {
    routeCallCount++;
    lastUserText = userText;
    lastTools = tools;
    return _routeResponse;
  }

  @override
  Future<String> chat({
    required String userText,
    required String stateBlock,
    required List<Map<String, String>> history,
  }) async {
    chatCallCount++;
    return _chatResponse;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Minimal test-only RouterTool implementations
// ─────────────────────────────────────────────────────────────────────

/// A trivial read tool that records how many times [run] executed —
/// used to prove the router's ≤1-processed-call cap (DEC-050 rule 4).
final class _CountingReadTool extends RouterTool<void> {
  int runCount = 0;

  @override
  String get name => 'counting_read';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'counting_read',
        description: 'test-only counting tool',
        parameters: Schema(type: SchemaType.object, properties: {}),
      );

  @override
  void parseArgs(Map<String, Object?> raw) {}

  @override
  Future<ToolOutcome> run(void args, ToolContext ctx) async {
    runCount++;
    return const RenderOutcome(widget: ChatWidgetSpec(widget: 'summary_card'));
  }
}

/// A tool whose [parseArgs] always throws, to test the invalid-args path.
final class _AlwaysInvalidTool extends RouterTool<Map<String, dynamic>> {
  @override
  String get name => 'always_invalid';

  @override
  WriteTier get tier => WriteTier.none;

  @override
  FunctionDeclaration get declaration => FunctionDeclaration(
        name: 'always_invalid',
        description: 'test-only tool that always rejects its args',
        parameters: Schema(type: SchemaType.object, properties: {}),
      );

  @override
  Map<String, dynamic> parseArgs(Map<String, Object?> raw) {
    throw const ToolArgsError('always invalid, for testing');
  }

  @override
  Future<ToolOutcome> run(Map<String, dynamic> args, ToolContext ctx) async {
    throw StateError('should never reach run() — parseArgs always throws');
  }
}

void main() {
  // ── ToolRegistry ─────────────────────────────────────────────────

  group('ToolRegistry', () {
    late ToolRegistry registry;
    late _CountingReadTool countingTool;
    late GeneralChatTool generalChatTool;
    late AskClarificationTool askClarificationTool;

    setUp(() {
      countingTool = _CountingReadTool();
      generalChatTool = GeneralChatTool();
      askClarificationTool = AskClarificationTool();
      registry = ToolRegistry([
        countingTool as RouterTool<Object?>,
        generalChatTool as RouterTool<Object?>,
        askClarificationTool as RouterTool<Object?>,
      ]);
    });

    test('looks up a registered tool by exact name', () {
      expect(registry['counting_read'], same(countingTool));
      expect(registry['general_chat'], same(generalChatTool));
    });

    test('hallucinated tool name returns null (not a throw)', () {
      // This is the exact scenario route() must handle: the model invents
      // a tool name that was never declared. Registry lookup must degrade
      // to null, never throw, so route() can fall back to a clarify.
      expect(registry['this_tool_does_not_exist'], isNull);
      expect(registry['evaluate_purchase_v2'], isNull);
      expect(registry[''], isNull);
    });

    test('toolNames contains every registered tool, nothing else', () {
      expect(
        registry.toolNames,
        {'counting_read', 'general_chat', 'ask_clarification'},
      );
    });

    test('tools list is unmodifiable', () {
      expect(() => registry.tools.add(countingTool as RouterTool<Object?>),
          throwsUnsupportedError);
    });
  });

  // ── parseArgs — every concrete tool ──────────────────────────────

  group('EvaluatePurchaseTool.parseArgs', () {
    late EvaluatePurchaseTool tool;
    setUp(() => tool = EvaluatePurchaseTool(PurchaseDecisionService(_unreachableClient())));

    test('valid args parse cleanly', () {
      final args = tool.parseArgs({'item': 'جوال', 'amount': 2000});
      expect(args, {'item': 'جوال', 'amount': 2000.0});
    });

    test('Arabic-Indic digit amount (string) normalizes', () {
      final args = tool.parseArgs({'item': 'جوال', 'amount': '٢٠٠٠'});
      expect(args['amount'], 2000.0);
    });

    test('comma-separated amount normalizes', () {
      final args = tool.parseArgs({'item': 'سيارة', 'amount': '50,000'});
      expect(args['amount'], 50000.0);
    });

    test('missing item throws ToolArgsError', () {
      expect(
        () => tool.parseArgs({'amount': 2000}),
        throwsA(isA<ToolArgsError>()),
      );
    });

    test('empty item throws ToolArgsError', () {
      expect(
        () => tool.parseArgs({'item': '   ', 'amount': 2000}),
        throwsA(isA<ToolArgsError>()),
      );
    });

    test('missing amount throws ToolArgsError', () {
      expect(
        () => tool.parseArgs({'item': 'جوال'}),
        throwsA(isA<ToolArgsError>()),
      );
    });

    test('zero or negative amount throws ToolArgsError', () {
      expect(() => tool.parseArgs({'item': 'جوال', 'amount': 0}),
          throwsA(isA<ToolArgsError>()));
      expect(() => tool.parseArgs({'item': 'جوال', 'amount': -5}),
          throwsA(isA<ToolArgsError>()));
    });
  });

  group('LogExpenseTool.parseArgs', () {
    late LogExpenseTool tool;
    setUp(() => tool = LogExpenseTool());

    test('valid args with all fields', () {
      final args = tool.parseArgs({
        'amount': 35,
        'category': 'أكل',
        'tone': 'gray',
      });
      expect(args, {'amount': 35.0, 'category': 'أكل', 'tone': 'gray'});
    });

    test('missing category defaults to متنوع', () {
      final args = tool.parseArgs({'amount': 12});
      expect(args['category'], 'متنوع');
    });

    test('missing tone defaults to gray', () {
      final args = tool.parseArgs({'amount': 12, 'category': 'قهوة'});
      expect(args['tone'], 'gray');
    });

    test('Arabic-Indic digit amount normalizes', () {
      final args = tool.parseArgs({'amount': '٢٠٠'});
      expect(args['amount'], 200.0);
    });

    test('missing amount throws ToolArgsError', () {
      expect(() => tool.parseArgs({'category': 'أكل'}),
          throwsA(isA<ToolArgsError>()));
    });

    test('non-positive amount throws ToolArgsError', () {
      expect(() => tool.parseArgs({'amount': 0}),
          throwsA(isA<ToolArgsError>()));
    });
  });

  group('LogCompoundExpenseTool.parseArgs', () {
    late LogCompoundExpenseTool tool;
    setUp(() => tool = LogCompoundExpenseTool());

    test('valid multi-item splits parse cleanly', () {
      final args = tool.parseArgs({
        'splits': [
          {'category': 'مقاضي', 'amount': 200},
          {'category': 'بنزين', 'amount': 150},
        ],
      });
      final splits = args['splits'] as List;
      expect(splits.length, 2);
      expect(splits[0], {'category': 'مقاضي', 'amount': 200.0});
    });

    test('missing splits throws ToolArgsError', () {
      expect(() => tool.parseArgs({}), throwsA(isA<ToolArgsError>()));
    });

    test('empty splits list throws ToolArgsError', () {
      expect(() => tool.parseArgs({'splits': <dynamic>[]}),
          throwsA(isA<ToolArgsError>()));
    });

    test('split missing amount throws ToolArgsError', () {
      expect(
        () => tool.parseArgs({
          'splits': [
            {'category': 'مقاضي'},
          ],
        }),
        throwsA(isA<ToolArgsError>()),
      );
    });

    test('split with non-map entry throws ToolArgsError', () {
      expect(
        () => tool.parseArgs({
          'splits': ['not a map'],
        }),
        throwsA(isA<ToolArgsError>()),
      );
    });
  });

  group('AddCommitmentTool.parseArgs', () {
    late AddCommitmentTool tool;
    setUp(() => tool = AddCommitmentTool());

    test('valid args with only required name', () {
      final args = tool.parseArgs({'name': 'قسط سيارة'});
      expect(args['name'], 'قسط سيارة');
      expect(args['type'], 'recurring'); // default
    });

    test('missing name throws ToolArgsError', () {
      expect(() => tool.parseArgs({'provider': 'تمارا'}),
          throwsA(isA<ToolArgsError>()));
    });

    test('empty name throws ToolArgsError', () {
      expect(() => tool.parseArgs({'name': '  '}),
          throwsA(isA<ToolArgsError>()));
    });

    test('Arabic-Indic amounts normalize', () {
      final args = tool.parseArgs({'name': 'قسط', 'amount_monthly': '٢٠٠'});
      expect(args['amount_monthly'], 200.0);
    });
  });

  group('AddGoalTool.parseArgs', () {
    late AddGoalTool tool;
    setUp(() => tool = AddGoalTool());

    test('valid args with only required name', () {
      final args = tool.parseArgs({'name': 'سيارة'});
      expect(args['name'], 'سيارة');
    });

    test('missing name throws ToolArgsError', () {
      expect(() => tool.parseArgs({'amount_total': 10000}),
          throwsA(isA<ToolArgsError>()));
    });
  });

  group('ViewCommitmentsTool / ViewGoalsTool.parseArgs', () {
    test('name_hint is optional and passes through', () {
      final commitTool = ViewCommitmentsTool(CommitmentService(_unreachableClient()));
      expect(commitTool.parseArgs({'name_hint': 'تمارا'}), 'تمارا');
      expect(commitTool.parseArgs({}), isNull);

      final goalTool = ViewGoalsTool(GoalService(_unreachableClient()));
      expect(goalTool.parseArgs({'name_hint': 'سيارة'}), 'سيارة');
      expect(goalTool.parseArgs({}), isNull);
    });
  });

  group('GetRemainingBudgetTool / GetIntegrityScoreTool.parseArgs', () {
    test('no-arg tools accept and ignore any input', () {
      final budgetTool = GetRemainingBudgetTool(PurchaseDecisionService(_unreachableClient()));
      expect(() => budgetTool.parseArgs({'unexpected': 'value'}), returnsNormally);

      final integrityTool = GetIntegrityScoreTool(IntegrityScoreService(_unreachableClient()));
      expect(() => integrityTool.parseArgs({}), returnsNormally);
    });
  });

  group('AskClarificationTool.parseArgs', () {
    test('valid args parse cleanly', () {
      final tool = AskClarificationTool();
      final args = tool.parseArgs({
        'missing': ['المبلغ', 'اسم الشيء'],
        'question': 'كم سعره؟',
      });
      expect(args['missing'], ['المبلغ', 'اسم الشيء']);
      expect(args['question'], 'كم سعره؟');
    });

    test('missing fields fall back to safe defaults (never throws)', () {
      final tool = AskClarificationTool();
      final args = tool.parseArgs({});
      expect(args['missing'], isEmpty);
      expect(args['question'], isNotEmpty);
    });
  });

  group('GeneralChatTool.parseArgs', () {
    test('never throws — general_chat is the structural fallback', () {
      final tool = GeneralChatTool();
      expect(() => tool.parseArgs({}), returnsNormally);
      expect(tool.parseArgs({'message': 'شكراً'}), 'شكراً');
    });
  });

  // ── RouterState — no financial magnitudes (DEC-050 rule 5) ───────

  group('RouterState', () {
    test('empty state produces an empty state block', () {
      const state = RouterState();
      expect(state.hasPending, isFalse);
      expect(state.toStateBlock(), isEmpty);
    });

    test('pending state block never carries financial magnitudes', () {
      const state = RouterState(
        pendingTool: 'evaluate_purchase',
        pendingItem: 'ساعة',
        pendingMissing: ['amount'],
      );
      final block = state.toStateBlock();
      expect(block, contains('evaluate_purchase'));
      // The state block is Dart-authored intent-level context only — it
      // must never contain a raw number (no amount was ever supplied here
      // for the model to see, structurally enforcing DEC-050 rule 5).
      expect(RegExp(r'[0-9٠-٩]').hasMatch(block), isFalse,
          reason: 'RouterState.toStateBlock() must carry zero digits — '
              'it is intent-level context, never a financial magnitude.');
    });
  });

  // ── route() integration — uses FakeRouterLlm, zero real LLM calls ──
  //
  // NOTE: route() requires a real ToolCallTraceService (the class is
  // `final`, so it cannot be faked/mocked via implements). Pointed at an
  // RFC 2606 reserved-invalid host; ToolCallTraceService.insert() catches
  // every exception internally and returns null, so this should degrade
  // gracefully rather than throw or hang — verified by reading the source,
  // not by running it.
  group('route() dispatch', () {
    late ToolCallTraceService tracer;

    setUp(() {
      tracer = ToolCallTraceService(_unreachableClient());
    });

    test('unknown/hallucinated tool name → ClarifyOutcome, not a crash', () async {
      final llm = FakeRouterLlm(
        routeResponse: const RouterLlmResponse(
          toolCalls: [
            {'name': 'tool_that_was_never_declared', 'args': {}},
          ],
        ),
      );
      final registry = ToolRegistry([GeneralChatTool() as RouterTool<Object?>]);

      final result = await route(
        routerLlm: llm,
        registry: registry,
        userText: 'test',
        userId: 'test-user',
        tracer: tracer,
      );

      expect(result.isError, isFalse);
      expect(result.outcome, isA<ClarifyOutcome>());
    });

    test('invalid args (ToolArgsError) → clarify, run() never reached', () async {
      final badTool = _AlwaysInvalidTool();
      final llm = FakeRouterLlm(
        routeResponse: const RouterLlmResponse(
          toolCalls: [
            {'name': 'always_invalid', 'args': {}},
          ],
        ),
      );
      final registry = ToolRegistry([badTool as RouterTool<Object?>]);

      final result = await route(
        routerLlm: llm,
        registry: registry,
        userText: 'test',
        userId: 'test-user',
        tracer: tracer,
      );

      expect(result.outcome, isA<ClarifyOutcome>());
    });

    test('general_chat tool call → isGeneralChat, no outcome to render', () async {
      final llm = FakeRouterLlm(
        routeResponse: const RouterLlmResponse(
          toolCalls: [
            {'name': 'general_chat', 'args': {}},
          ],
        ),
      );
      final registry = ToolRegistry([GeneralChatTool() as RouterTool<Object?>]);

      final result = await route(
        routerLlm: llm,
        registry: registry,
        userText: 'شكراً',
        userId: 'test-user',
        tracer: tracer,
      );

      expect(result.isGeneralChat, isTrue);
      expect(result.userText, 'شكراً');
    });

    test('cap enforcement: 2 tool calls in one response → only the first runs',
        () async {
      final counting = _CountingReadTool();
      final llm = FakeRouterLlm(
        routeResponse: const RouterLlmResponse(
          toolCalls: [
            {'name': 'counting_read', 'args': {}},
            {'name': 'counting_read', 'args': {}}, // must be ignored
          ],
        ),
      );
      final registry = ToolRegistry([counting as RouterTool<Object?>]);

      await route(
        routerLlm: llm,
        registry: registry,
        userText: 'test',
        userId: 'test-user',
        tracer: tracer,
      );

      expect(counting.runCount, 1,
          reason: 'DEC-050 rule 4: only the first tool call is ever '
              'processed — route() returns immediately after handling it.');
    });

    test('one route() call makes exactly one RouterLlm.route() call', () async {
      final llm = FakeRouterLlm(
        routeResponse: const RouterLlmResponse(
          toolCalls: [
            {'name': 'general_chat', 'args': {}},
          ],
        ),
      );
      final registry = ToolRegistry([GeneralChatTool() as RouterTool<Object?>]);

      await route(
        routerLlm: llm,
        registry: registry,
        userText: 'test',
        userId: 'test-user',
        tracer: tracer,
      );

      expect(llm.routeCallCount, 1);
    });
  });
}
