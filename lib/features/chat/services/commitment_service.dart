/// Persistence for the `commitments` table.
///
/// Mirrors TransactionService in style. All writes go through Supabase
/// with soft-delete (anti-ghost protocol).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

final class CommitmentService {
  CommitmentService(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> addCommitment({
    required String name,
    required double totalAmount,
    required double remaining,
    required double monthlyAmount,
    required String type,
    String? provider,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client.from('commitments').insert({
      'user_id': userId,
      'name': name,
      'total_amount': totalAmount,
      'remaining': remaining,
      'monthly_amount': monthlyAmount,
      'type': type,
      if (provider != null && provider.isNotEmpty) 'provider': provider,
      'status': 'active',
    }).select();
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listActive() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('commitments')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .eq('status', 'active')
        .order('created_at');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<bool> hasAnyCommitments() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('commitments')
        .select('id')
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> markCompleted(String id) async {
    await _client.from('commitments').update({
      'remaining': 0,
      'status': 'completed',
    }).eq('id', id);
  }

  Future<void> updateRemaining(String id, double remaining) async {
    await _client.from('commitments').update({
      'remaining': remaining,
    }).eq('id', id);
  }

  Future<void> softDelete(String id) async {
    await _client.from('commitments').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
