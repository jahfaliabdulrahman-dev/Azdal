/// Provider declarations for Azdal.
///
/// This file centralises Riverpod providers used across the app.
/// Each section groups providers by domain (services, features, etc.).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/gemini_service.dart';
import '../features/chat/services/commitment_service.dart';
import '../features/chat/services/financial_profile_service.dart';
import '../features/chat/services/goal_service.dart';
import '../features/chat/services/integrity_score_service.dart';
import '../features/chat/services/purchase_decision_service.dart';
import '../features/chat/services/transaction_service.dart';
import '../features/chat/services/voice_service.dart';

// ─────────────────────────────────────────────────────────────────────
// Services
// ─────────────────────────────────────────────────────────────────────

/// Singleton provider for the Gemini AI service.
final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);

/// Reactive provider for voice listening state.
final voiceListeningProvider =
    StateNotifierProvider<VoiceListeningNotifier, VoiceListeningState>(
  (ref) => VoiceListeningNotifier(),
);

/// Singleton provider for the voice input service.
final voiceServiceProvider = Provider<VoiceService>(
  (ref) => VoiceService(ref.read(voiceListeningProvider.notifier)),
);

/// Singleton provider for the transaction persistence service.
final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(),
);

/// Singleton provider for the financial-profile persistence service.
final financialProfileServiceProvider = Provider<FinancialProfileService>(
  (ref) => FinancialProfileService(Supabase.instance.client),
);

/// Singleton provider for the commitment persistence service.
final commitmentServiceProvider = Provider<CommitmentService>(
  (ref) => CommitmentService(Supabase.instance.client),
);

/// Singleton provider for the goal persistence service.
final goalServiceProvider = Provider<GoalService>(
  (ref) => GoalService(Supabase.instance.client),
);

/// Singleton provider for the purchase-decision service (Stage 4).
final purchaseDecisionServiceProvider = Provider<PurchaseDecisionService>(
  (ref) => PurchaseDecisionService(Supabase.instance.client),
);

/// Singleton provider for the integrity-score service (Stage 4).
final integrityScoreServiceProvider = Provider<IntegrityScoreService>(
  (ref) => IntegrityScoreService(Supabase.instance.client),
);
