/// Golden Intent Matrix harness test.
///
/// Reads test/fixtures/golden_intent_matrix.jsonl and asserts every row's
/// expected_gate matches the actual IntentRouter.classify output.
///
/// This harness is deterministic and network-free — it asserts the pure
/// regex gate. The full expected_intent path (requiring FakeGeminiService
/// and chat_screen wiring) is deferred to Phase 0.5 (DEC-050).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/routing/intent_router.dart';

/// Maps JSONL expected_gate strings to GateDecision enum values.
const _gateMap = <String, GateDecision>{
  'setup_commitment': GateDecision.setupCommitment,
  'buy_intent': GateDecision.buyIntent,
  'integrity_query': GateDecision.integrityQuery,
  'budget_query': GateDecision.budgetQuery,
  'general_chat': GateDecision.generalChat,
};

/// Valid expected_intent values from the 10-value enum.
const _validIntents = {
  'setup_commitment', 'setup_goal', 'evaluate_purchase', 'buy_query',
  'view_integrity', 'view_budget', 'log_expense', 'log_compound_expense',
  'clarify', 'general_chat',
};

List<Map<String, dynamic>> _loadFixture() {
  final file = File('test/fixtures/golden_intent_matrix.jsonl');
  if (!file.existsSync()) {
    throw StateError(
      'Golden intent matrix fixture not found at ${file.path}. '
      'Run from the project root.',
    );
  }

  final rows = <Map<String, dynamic>>[];
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    rows.add(jsonDecode(line) as Map<String, dynamic>);
  }
  return rows;
}

void main() {
  late List<Map<String, dynamic>> rows;

  setUpAll(() {
    rows = _loadFixture();
  });

  test('fixture has exactly 32 rows (GM-001 through GM-032)', () {
    expect(rows.length, 32);
    for (var i = 1; i <= 32; i++) {
      final expectedId = 'GM-${i.toString().padLeft(3, '0')}';
      expect(
        rows.any((r) => r['id'] == expectedId),
        isTrue,
        reason: 'Missing row: $expectedId',
      );
    }
  });

  test('all 10 expected_intent values present with >=2 rows each', () {
    final counts = <String, int>{};
    for (final r in rows) {
      final intent = r['expected_intent'] as String;
      counts[intent] = (counts[intent] ?? 0) + 1;
    }

    for (final intent in _validIntents) {
      expect(
        counts[intent] ?? 0,
        greaterThanOrEqualTo(2),
        reason: 'expected_intent "$intent" must have >=2 rows',
      );
    }
  });

  test('every row has IntentRouter.classify == expected_gate', () {
    final failures = <String>[];
    for (final r in rows) {
      final id = r['id'] as String;
      final msg = r['message'] as String;
      final specGateStr = r['expected_gate'] as String;

      final expectedGate = _gateMap[specGateStr];
      if (expectedGate == null) {
        failures.add('$id: unknown expected_gate "$specGateStr"');
        continue;
      }

      final actual = IntentRouter.classify(msg);
      if (actual != expectedGate) {
        failures.add(
          '$id: expected_gate="$specGateStr", '
          'actual="${actual.name}" | message="$msg"',
        );
      }
    }

    if (failures.isNotEmpty) {
      fail('${failures.length} row(s) did not match:\n${failures.join('\n')}');
    }
  });

  test('all GateDecision enum values are represented', () {
    final gatesSeen = rows.map((r) => r['expected_gate'] as String).toSet();
    for (final gate in _gateMap.keys) {
      expect(gatesSeen, contains(gate), reason: 'GateDecision.$gate not in fixture');
    }
  });

  test('every row is valid JSON with required fields', () {
    const required = {'id', 'message', 'expected_intent', 'expected_gate',
                      'requires_llm_classify', 'ground_truth', 'notes'};

    for (final r in rows) {
      for (final field in required) {
        expect(r, contains(field), reason: '${r['id']}: missing field "$field"');
      }
      expect(r['id'], isA<String>());
      expect(r['message'], isA<String>());
      expect(_validIntents, contains(r['expected_intent']),
             reason: '${r['id']}: invalid expected_intent "${r['expected_intent']}"');
      expect(_gateMap, contains(r['expected_gate']),
             reason: '${r['id']}: invalid expected_gate "${r['expected_gate']}"');
      expect(r['requires_llm_classify'], isA<bool>());
    }
  });

  test('reconciled rows GM-015, GM-020, GM-032 have expected_gate=general_chat with reconciliation notes', () {
    for (final r in rows) {
      final id = r['id'] as String;
      if (id == 'GM-015' || id == 'GM-020' || id == 'GM-032') {
        expect(r['expected_gate'], 'general_chat',
               reason: '$id must be reconciled to generalChat');
        expect((r['notes'] as String).contains('RECONCILED'), isTrue,
               reason: '$id must carry RECONCILED annotation');
        // Verify the actual classify output matches generalChat
        expect(
          IntentRouter.classify(r['message'] as String),
          GateDecision.generalChat,
          reason: '$id: IntentRouter.classify must return generalChat',
        );
      }
    }
  });

  test('GM-032 ground_truth stores two items as explicit literals (DEC-024)', () {
    final gm032 = rows.firstWhere((r) => r['id'] == 'GM-032');
    final gt = gm032['ground_truth'] as Map<String, dynamic>;
    expect(gt, isNotNull);
    expect(gt['items'], isA<List<dynamic>>());
    expect((gt['items'] as List).length, 2);
    final item0 = (gt['items'] as List)[0] as Map<String, dynamic>;
    expect(item0['item'], 'جوال');
    expect(item0['amount'], 2000);
    final item1 = (gt['items'] as List)[1] as Map<String, dynamic>;
    expect(item1['item'], 'دراجة');
    expect(item1['amount'], 800);
  });

  test('GM-008 through GM-013 ground_truth stores amounts as int literals (DEC-024)', () {
    for (final r in rows) {
      final id = r['id'] as String;
      if (int.tryParse(id.substring(3)) case final n? when n >= 8 && n <= 13) {
        final gt = r['ground_truth'];
        if (gt != null) {
          final item = gt['item'] as String;
          final amount = gt['amount'];
          expect(amount, isA<int>(), reason: '$id: amount must be int literal');
          expect(item, isNotEmpty);
        }
      }
    }
  });
}
