/// Integrity Score service for Azdal.
///
/// Pure Dart per DEC-025 — 3 real factors only:
/// 1. logging_consistency — distinct logging days / days since first tx
/// 2. receipt_upload_rate — transactions with receipt / total
/// 3. no_deletion_rate — 1 − (deleted / total)
///
/// The 2 locked factors (data_match_accuracy, response_time_factor)
/// are NEVER assigned numeric values — they remain null until
/// bank-linking is available.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final class IntegrityScoreService {
  IntegrityScoreService(this._client);
  final SupabaseClient _client;

  /// Pure synchronous score computation — all factor math, no Supabase.
  ///
  /// Takes pre-fetched numbers and returns the same map [calculate] would.
  /// All three factors are clamped 0–100; the final score is their average
  /// rounded and clamped. Locked factors remain null per DEC-025.
  static Map<String, dynamic> computeScore({
    required int totalCount,
    required int deletedCount,
    required int uniqueDays,
    required int daysSince,
    required int withReceipt,
  }) {
    // ── 1. logging_consistency ──────────────────────────────────
    double loggingConsistency = 0;
    if (totalCount > 0) {
      loggingConsistency =
          (uniqueDays / daysSince * 100).clamp(0, 100);
    }

    // ── 2. receipt_upload_rate ──────────────────────────────────
    double receiptUploadRate = 0;
    if (totalCount > 0) {
      receiptUploadRate =
          (withReceipt / totalCount * 100).clamp(0, 100);
    }

    // ── 3. no_deletion_rate ─────────────────────────────────────
    double noDeletionRate = 100;
    if (totalCount > 0) {
      final totalEver = totalCount + deletedCount;
      noDeletionRate = (totalCount / totalEver * 100).clamp(0, 100);
    }

    // ── Combine: equal weight among 3 real factors ──────────────
    final score = ((loggingConsistency + receiptUploadRate + noDeletionRate) / 3)
        .round()
        .clamp(0, 100);

    return {
      'score': score,
      'logging_consistency': loggingConsistency.round(),
      'receipt_upload_rate': receiptUploadRate.round(),
      'no_deletion_rate': noDeletionRate.round(),
      // Locked factors — NEVER assigned numeric values (DEC-025)
      'data_match_accuracy': null,
      'response_time_factor': null,
    };
  }

  /// Calculate the integrity score for the current user.
  ///
  /// Returns a map with `score` (0-100), plus individual factor
  /// percentages and the locked factors set to null.
  Future<Map<String, dynamic>> calculate() async {
    final userId = _client.auth.currentUser!.id;

    // Count total expense transactions (non-deleted)
    final totalRows = await _client
        .from('transactions')
        .select('id')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .eq('is_deleted', false);

    final totalCount = (totalRows as List).length;

    // ── Gather pre-fetched numbers for the pure function ────────
    int uniqueDays = 0;
    int daysSince = 0;
    if (totalCount > 0) {
      final firstTxRow = await _client
          .from('transactions')
          .select('created_at')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .eq('is_deleted', false)
          .order('created_at')
          .limit(1)
          .single();

      final firstDate = DateTime.parse(
        firstTxRow['created_at'] as String,
      );
      daysSince =
          DateTime.now().difference(firstDate).inDays.clamp(1, 30);

      final distinctRows = await _client
          .from('transactions')
          .select('created_at')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .eq('is_deleted', false);

      uniqueDays = (distinctRows as List)
          .map((r) => DateTime.parse(
                  (r as Map<String, dynamic>)['created_at'] as String)
              .toIso8601String()
              .substring(0, 10))
          .toSet()
          .length;
    }

    int withReceipt = 0;
    if (totalCount > 0) {
      final withReceiptRows = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .eq('is_deleted', false)
          .not('receipt_url', 'is', null);
      withReceipt = (withReceiptRows as List).length;
    }

    int deletedCount = 0;
    if (totalCount > 0) {
      final deletedRows = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .eq('is_deleted', true);
      deletedCount = (deletedRows as List).length;
    }

    return computeScore(
      totalCount: totalCount,
      deletedCount: deletedCount,
      uniqueDays: uniqueDays,
      daysSince: daysSince,
      withReceipt: withReceipt,
    );
  }
}
