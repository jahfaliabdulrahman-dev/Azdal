/// Persistence for the `financial_profile` table.
///
/// Stores Cold Start estimates so they survive past the first session.
/// One row per user (upsert on conflict).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final class FinancialProfileService {
  FinancialProfileService(this._client);
  final SupabaseClient _client;

  Future<void> upsert({
    required double monthlyIncome,
    required double monthlyCommitmentsEstimate,
    required double weeklySpendEstimate,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('financial_profile').upsert({
      'user_id': userId,
      'monthly_income': monthlyIncome,
      'monthly_commitments_estimate': monthlyCommitmentsEstimate,
      'weekly_spend_estimate': weeklySpendEstimate,
      'is_deleted': false,
      'deleted_at': null,
    }, onConflict: 'user_id');
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('financial_profile')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }
}
