/// Transaction service for Azdal — Supabase write operations.
///
/// Handles inserting classified transactions into the live Supabase
/// `transactions` table.  Uses the current anonymous user's UUID
/// (DEC-017) so all RLS policies work unchanged.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for persisting transactions to Supabase.
final class TransactionService {
  TransactionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// The current authenticated user's ID.
  /// Will be null if anonymous sign-in failed.
  String? get userId => _client.auth.currentUser?.id;

  /// Insert a single classified transaction.
  ///
  /// Returns the created row as a Map on success, or throws on failure.
  /// Required fields: [amount], [category].
  /// Optional: [subcategory], [description], [type], [tone], [groupId], [receiptUrl].
  Future<Map<String, dynamic>> saveTransaction({
    required double amount,
    required String category,
    String? subcategory,
    String? description,
    String type = 'expense',
    String tone = 'gray',
    String? groupId,
    String? receiptUrl,
  }) async {
    final uid = userId;
    if (uid == null) {
      throw StateError(
        'Cannot save transaction: no authenticated user. '
        'Anonymous sign-in may have failed.',
      );
    }

    final data = <String, dynamic>{
      'user_id': uid,
      'amount': amount,
      'category': category,
      'type': type,
      'tone': tone,
    };
    if (subcategory != null) data['subcategory'] = subcategory;
    if (description != null) data['description'] = description;
    if (groupId != null) data['group_id'] = groupId;
    if (receiptUrl != null) data['receipt_url'] = receiptUrl;

    // ignore: avoid_print
    print('=== AZDAL DEBUG: Saving transaction — '
        'amount=$amount category=$category tone=$tone');

    final response = await _client
        .from('transactions')
        .insert(data)
        .select()
        .single();

    // ignore: avoid_print
    print('=== AZDAL DEBUG: Transaction saved — id=${response['id']}');
    return response;
  }

  /// Insert multiple transactions as a compound split.
  ///
  /// All rows share the same [groupId] (UUID of the first inserted row).
  /// Returns the list of created rows.
  Future<List<Map<String, dynamic>>> saveCompoundSplits({
    required List<Map<String, dynamic>> splits,
  }) async {
    if (splits.isEmpty) return [];

    final uid = userId;
    if (uid == null) {
      throw StateError(
        'Cannot save compound splits: no authenticated user.',
      );
    }

    // Insert the first row to get a group_id
    final firstData = <String, dynamic>{
      'user_id': uid,
      'amount': splits.first['amount'],
      'category': splits.first['category'],
      'type': splits.first['type'] ?? 'expense',
      'tone': splits.first['tone'] ?? 'gray',
    };
    if (splits.first['subcategory'] != null) {
      firstData['subcategory'] = splits.first['subcategory'];
    }

    final firstResponse = await _client
        .from('transactions')
        .insert(firstData)
        .select()
        .single();

    final groupId = firstResponse['id'] as String;
    // ignore: avoid_print
    print('=== AZDAL DEBUG: Compound split group_id=$groupId');

    final results = <Map<String, dynamic>>[firstResponse];

    // Insert remaining rows with the same group_id
    for (var i = 1; i < splits.length; i++) {
      final split = splits[i];
      final data = <String, dynamic>{
        'user_id': uid,
        'amount': split['amount'],
        'category': split['category'],
        'type': split['type'] ?? 'expense',
        'tone': split['tone'] ?? 'gray',
        'group_id': groupId,
      };
      if (split['subcategory'] != null) {
        data['subcategory'] = split['subcategory'];
      }

      final response = await _client
          .from('transactions')
          .insert(data)
          .select()
          .single();
      results.add(response);
    }

    // ignore: avoid_print
    print('=== AZDAL DEBUG: Compound splits saved — '
        '${results.length} transactions in group $groupId');
    return results;
  }

  /// Check if the current user has any transactions.
  /// Returns `true` if at least one transaction exists (used for Cold Start check).
  Future<bool> hasExistingTransactions() async {
    final uid = userId;
    if (uid == null) return false;

    try {
      final response = await _client
          .from('transactions')
          .select('id')
          .eq('user_id', uid)
          .eq('is_deleted', false)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      // ignore: avoid_print
      print('=== AZDAL DEBUG: hasExistingTransactions FAILED — $e');
      return false;
    }
  }
}
