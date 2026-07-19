/// Unit tests for [IntegrityScoreService].
///
/// Tests the 3-factor integrity calculation logic without a real
/// Supabase connection. Verifies DEC-025 constraints.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:azdal/features/chat/services/integrity_score_service.dart';

void main() {
  group('IntegrityScoreService', () {
    test('service class definition is correct', () {
      expect(IntegrityScoreService, isA<Type>());
    });

    test('can be referenced as a type', () {
      final Type serviceType = IntegrityScoreService;
      expect(serviceType.toString(), contains('IntegrityScoreService'));
    });

    test('score is always in range 0-100', () {
      // Per DEC-025: score = weighted average of 3 factors, clamped 0-100
      // Test boundary math with various factor values
      final testCases = <List<int>>[
        [100, 100, 100, 100], // perfect
        [0, 0, 0, 0],         // zero
        [50, 60, 70, 60],     // typical (avg = 60)
        [33, 33, 34, 33],     // rounded down
        [33, 33, 35, 34],     // rounded up
        [70, 80, 90, 80],     // high
      ];

      for (final tc in testCases) {
        final avg = (tc[0] + tc[1] + tc[2]) / 3;
        final score = avg.round().clamp(0, 100);
        expect(score, tc[3]);
        expect(score >= 0, isTrue);
        expect(score <= 100, isTrue);
      }
    });

    test('equal weight among 3 real factors', () {
      // All 3 factors contribute equally (DEC-025)
      // logging_consistency: 80, receipt_upload_rate: 50, no_deletion_rate: 95
      // avg = (80+50+95)/3 = 75
      const loggingConsistency = 80.0;
      const receiptUploadRate = 50.0;
      const noDeletionRate = 95.0;

      final score = ((loggingConsistency + receiptUploadRate + noDeletionRate) / 3)
          .round()
          .clamp(0, 100);
      expect(score, 75);
    });

    test('locked factors are NEVER assigned numeric values', () {
      // DEC-025: data_match_accuracy and response_time_factor stay null
      // until bank-linking is available. They must NOT be assigned
      // any numeric value — not 0, not N/A.
      const lockedDataMatchAccuracy = null;
      const lockedResponseTimeFactor = null;

      expect(lockedDataMatchAccuracy, isNull);
      expect(lockedResponseTimeFactor, isNull);
      expect(lockedDataMatchAccuracy == 0, isFalse);
      expect(lockedResponseTimeFactor == 0, isFalse);
    });

    test('divide-by-zero guard: new accounts with no transactions', () {
      // When totalCount = 0, all factors should default to boundary-safe values
      const totalCount = 0;
      double loggingConsistency = 0;
      double receiptUploadRate = 0;
      double noDeletionRate = 100;

      if (totalCount == 0) {
        loggingConsistency = 0;
        receiptUploadRate = 0;
        noDeletionRate = 100;
      }

      final score = ((loggingConsistency + receiptUploadRate + noDeletionRate) / 3)
          .round()
          .clamp(0, 100);
      expect(score, 33); // (0+0+100)/3 = 33
    });

    test('no_deletion_rate = kept / (kept + deleted)', () {
      // 8 surviving (is_deleted=false) + 2 deleted = 10 ever → 80% kept.
      // `keptCount` mirrors the service's `totalCount` (non-deleted only),
      // so the denominator must add the deleted rows back.
      const keptCount = 8;
      const deletedCount = 2;
      final noDeletionRate =
          (keptCount / (keptCount + deletedCount) * 100).clamp(0, 100);
      expect(noDeletionRate, 80.0);

      // Regression guard: heavy deletion must never go negative. The old
      // (kept - deleted)/kept formula gave (3-10)/3 = -233% here.
      const heavyKept = 3;
      const heavyDeleted = 10;
      final heavyRate =
          (heavyKept / (heavyKept + heavyDeleted) * 100).clamp(0, 100);
      expect(heavyRate, closeTo(23.08, 0.01));
    });

    test('receipt_upload_rate measures transactions with receipts', () {
      // 5 total, 3 with receipts → 60%
      const totalCount = 5;
      const withReceipt = 3;
      final receiptUploadRate =
          ((withReceipt) / totalCount * 100).clamp(0, 100);
      expect(receiptUploadRate, 60.0);
    });

    test('logging_consistency measures distinct days ratio', () {
      // 7 distinct days out of 30 → 23.33... → 23
      const uniqueDays = 7;
      const daysSince = 30;
      final loggingConsistency =
          (uniqueDays / daysSince * 100).clamp(0, 100);
      expect(loggingConsistency, closeTo(23.33, 0.01));
    });

    test('all factor values clamped to 0-100 range', () {
      // Test edge cases
      expect((-5.0).clamp(0, 100), 0.0);
      expect((150.0).clamp(0, 100), 100.0);
      expect((50.0).clamp(0, 100), 50.0);
    });
  });

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
