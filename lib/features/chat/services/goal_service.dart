/// Persistence for the `goals` table.
///
/// Mirrors CommitmentService in style. `current_amount` starts at 0
/// (opposite of commitment `remaining` which starts at `total_amount`).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final class GoalService {
  GoalService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> addGoal({
    required String name,
    required double targetAmount,
    required double monthlyContribution,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client.from('goals').insert({
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': 0, // starts unsaved
      'monthly_contribution': monthlyContribution,
      'status': 'active',
    }).select();
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listActive() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active')
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<bool> hasAnyGoals() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('goals')
        .select('id')
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> markAchieved(String id) async {
    await _client.from('goals').update({
      'status': 'achieved',
      'achieved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> updateCurrentAmount(String id, double currentAmount) async {
    await _client.from('goals').update({
      'current_amount': currentAmount,
    }).eq('id', id);
  }

  Future<void> softDelete(String id) async {
    await _client.from('goals').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
