/// Unit tests for [IntegrityScoreService].
///
/// Tests the 3-factor integrity calculation logic without a real
/// Supabase connection. Verifies DEC-025 constraints.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/services/integrity_score_service.dart';

void main() {
  group('computeScore — pure function (no Supabase)', () {
    test('perfect score — all 100s', () {
      final result = IntegrityScoreService.computeScore(
        totalCount: 10,
        deletedCount: 0,
        uniqueDays: 30,
        daysSince: 30,
        withReceipt: 10,
      );
      expect(result['score'], 100);
      expect(result['logging_consistency'], 100);
      expect(result['receipt_upload_rate'], 100);
      expect(result['no_deletion_rate'], 100);
    });

    test('new account — no transactions', () {
      final result = IntegrityScoreService.computeScore(
        totalCount: 0,
        deletedCount: 0,
        uniqueDays: 0,
        daysSince: 0,
        withReceipt: 0,
      );
      expect(result['score'], 33); // (0+0+100)/3 = 33
      expect(result['logging_consistency'], 0);
      expect(result['receipt_upload_rate'], 0);
      expect(result['no_deletion_rate'], 100);
    });

    test('typical account with some deletions', () {
      // 8 kept, 2 deleted → 10 ever → 80% kept
      // receipt: 4 out of 8 → 50%
      // logging: 12 unique days out of 30 → 40%
      // avg = (40+50+80)/3 = 56.67 → 57
      final result = IntegrityScoreService.computeScore(
        totalCount: 8,
        deletedCount: 2,
        uniqueDays: 12,
        daysSince: 30,
        withReceipt: 4,
      );
      expect(result['logging_consistency'], 40);
      expect(result['receipt_upload_rate'], 50);
      expect(result['no_deletion_rate'], 80);
      expect(result['score'], 57); // (40+50+80)/3 = 56.67 rounds to 57
    });

    test('locked factors always null', () {
      final result = IntegrityScoreService.computeScore(
        totalCount: 5,
        deletedCount: 1,
        uniqueDays: 5,
        daysSince: 30,
        withReceipt: 2,
      );
      expect(result['data_match_accuracy'], isNull);
      expect(result['response_time_factor'], isNull);
    });

    test('heavy deletions — rate clamped to 0–100', () {
      // 3 kept, 10 deleted → 3/13 = 23.08%
      final result = IntegrityScoreService.computeScore(
        totalCount: 3,
        deletedCount: 10,
        uniqueDays: 3,
        daysSince: 30,
        withReceipt: 1,
      );
      expect(result['no_deletion_rate'], 23); // 23.08 rounds to 23
      expect((result['no_deletion_rate'] as int) >= 0, isTrue);
    });

    test('all factors clamped individually', () {
      // uniqueDays > daysSince yields >100% before clamp
      final result = IntegrityScoreService.computeScore(
        totalCount: 10,
        deletedCount: 0,
        uniqueDays: 40, // more than daysSince
        daysSince: 30,
        withReceipt: 15, // more than totalCount
      );
      expect(result['logging_consistency'], 100); // clamped from 133
      expect(result['receipt_upload_rate'], 100);  // clamped from 150
      expect(result['no_deletion_rate'], 100);
    });

    test('rounding — .67 rounds up to next integer', () {
      final result = IntegrityScoreService.computeScore(
        totalCount: 3,
        deletedCount: 0,
        uniqueDays: 2,
        daysSince: 30,
        withReceipt: 1,
      );
      // logging: 2/30*100 = 6.67 → 7
      // receipt: 1/3*100 = 33.33 → 33
      // deletion: 3/3*100 = 100
      // avg = (6.67+33.33+100)/3 = 46.67 → 47
      expect(result['logging_consistency'], 7);
      expect(result['receipt_upload_rate'], 33);
      expect(result['no_deletion_rate'], 100);
      expect(result['score'], 47);
    });
  });
}
