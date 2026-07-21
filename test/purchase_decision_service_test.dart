/// Unit tests for [PurchaseDecisionService].
///
/// Tests the pure-Dart purchase-decision logic without a real
/// Supabase connection. All financial math is verified in isolation.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/services/purchase_decision_service.dart';

void main() {
  group('decideVerdict — pure function (no Supabase)', () {
    test('zero income → need_info', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 0,
        totalCommitments: 1000,
        monthlySpend: 500,
        totalGoalMonthly: 0,
        amount: 200,
      );
      expect(result['verdict'], 'need_info');
      expect(result['dti'], 0.0);
      expect(result['disposable'], 0.0);
    });

    test('DTI > 33% → hard no', () {
      // income=5000, commitments=2000 → DTI=40%
      final result = PurchaseDecisionService.decideVerdict(
        income: 5000,
        totalCommitments: 2000,
        monthlySpend: 500,
        totalGoalMonthly: 0,
        amount: 200,
      );
      expect(result['verdict'], 'no');
      expect(result['dti'], 0.4);
      expect((result['reply'] as String).contains('40%'), isTrue);
    });

    test('DTI exactly 33% → allowed (not over cap)', () {
      // income=10000, commitments=3300 → DTI=33%
      final result = PurchaseDecisionService.decideVerdict(
        income: 10000,
        totalCommitments: 3300,
        monthlySpend: 0,
        totalGoalMonthly: 0,
        amount: 1000,
      );
      expect(result['verdict'], isNot('no'));
      expect(result['dti'], 0.33);
    });

    test('positive disposable → yes', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 8000,
        totalCommitments: 2000,
        monthlySpend: 1500,
        totalGoalMonthly: 500,
        amount: 1000,
      );
      // disposable = 8000-2000-1500-500-1000 = 3000
      expect(result['verdict'], 'yes');
      expect(result['disposable'], 3000.0);
      expect((result['reply'] as String).contains('3000'), isTrue);
    });

    test('negative disposable + active goals → wait', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 5000,
        totalCommitments: 1000,
        monthlySpend: 4000,
        totalGoalMonthly: 500,
        amount: 1000,
      );
      // disposable = 5000-1000-4000-500-1000 = -1500, DTI=20%
      expect(result['verdict'], 'wait');
      expect(result['disposable'], -1500.0);
      expect(result['goalImpact'], isNotNull);
    });

    test('negative disposable + no goals → no', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 5000,
        totalCommitments: 1000,
        monthlySpend: 4500,
        totalGoalMonthly: 0,
        amount: 1000,
      );
      // disposable = 5000-1000-4500-0-1000 = -1500, DTI=20%
      expect(result['verdict'], 'no');
      expect(result['disposable'], -1500.0);
      expect(result['goalImpact'], isNull);
    });

    test('disposable exactly zero → yes (not wait)', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 4000,
        totalCommitments: 1000,
        monthlySpend: 2000,
        totalGoalMonthly: 500,
        amount: 500,
      );
      // disposable = 4000-1000-2000-500-500 = 0
      expect(result['verdict'], 'yes');
      expect(result['disposable'], 0.0);
    });

    test('DTI with zero income → need_info (not division by zero)', () {
      final result = PurchaseDecisionService.decideVerdict(
        income: 0,
        totalCommitments: 1000,
        monthlySpend: 0,
        totalGoalMonthly: 0,
        amount: 100,
      );
      expect(result['verdict'], 'need_info');
      expect(result['dti'], 0.0);
    });
  });
}
