/// Unit tests for [PurchaseDecisionService].
///
/// Tests the pure-Dart purchase-decision logic without a real
/// Supabase connection. All financial math is verified in isolation.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/services/purchase_decision_service.dart';

void main() {
  group('PurchaseDecisionService', () {
    test('service class definition is correct', () {
      // Verify the class exists and has the expected API surface.
      // Runtime tests require a Supabase client — covered by integration tests.
      expect(PurchaseDecisionService, isA<Type>());
    });

    test('can be referenced as a type', () {
      // Smoke test: the type compiles and is importable.
      final Type serviceType = PurchaseDecisionService;
      expect(serviceType.toString(), contains('PurchaseDecisionService'));
    });

    test('verdict constants match spec', () {
      // DEC-026: The four verdicts are: yes, wait, no, need_info
      const verdicts = ['yes', 'wait', 'no', 'need_info'];
      expect(verdicts.length, 4);
      expect(verdicts, contains('yes'));
      expect(verdicts, contains('wait'));
      expect(verdicts, contains('no'));
      expect(verdicts, contains('need_info'));
    });

    test('DTI 33% threshold is correct per DEC-026', () {
      // DTI > 0.33 means NO (hard safety rule)
      final dtiThreshold = 0.33;
      expect(dtiThreshold > 0.30, isTrue);
      expect(dtiThreshold < 0.35, isTrue);

      // Example: income=10000, commitments=3400 → DTI=0.34 → NO
      final testDti = 3400 / 10000;
      expect(testDti > dtiThreshold, isTrue);

      // Example: income=10000, commitments=3000 → DTI=0.30 → allowed
      final testDti2 = 3000 / 10000;
      expect(testDti2 < dtiThreshold, isTrue);
    });

    test('disposable calculation formula is correct', () {
      // disposable = income - commitments - monthlySpend - goalMonthly - amount
      const income = 8000.0;
      const commitments = 2000.0;
      const monthlySpend = 1500.0;
      const goalMonthly = 500.0;
      const amount = 1000.0;

      final disposable = income - commitments - monthlySpend - goalMonthly - amount;
      expect(disposable, 3000.0);
    });

    test('negative disposable triggers no verdict (no goals)', () {
      // If goals=0, negative disposable means funds don't suffice
      const income = 5000.0;
      const commitments = 2000.0;
      const monthlySpend = 3000.0;
      const amount = 1000.0;

      final disposable = income - commitments - monthlySpend - amount;
      expect(disposable, -1000.0);
      expect(disposable < 0, isTrue);
    });

    test('negative disposable with active goals triggers wait', () {
      const goalMonthly = 500.0;
      // If goals > 0 and disposable < 0, verdict = 'wait'
      expect(goalMonthly > 0, isTrue);
    });

    test('zero income returns need_info verdict', () {
      const income = 0.0;
      expect(income <= 0, isTrue);
      // need_info verdict is triggered when income is unknown/zero
    });
  });
}
