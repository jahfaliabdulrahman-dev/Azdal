/// Provider declarations for Azdal.
///
/// This file centralises Riverpod providers used across the app.
/// Each section groups providers by domain (services, features, etc.).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/gemini_service.dart';
import '../features/auth/auth_service.dart';
import '../features/chat/services/commitment_service.dart';
import '../features/chat/services/financial_profile_service.dart';
import '../features/chat/services/goal_service.dart';
import '../features/chat/services/integrity_score_service.dart';
import '../features/chat/services/purchase_decision_service.dart';
import '../features/chat/services/transaction_service.dart';
import '../features/chat/services/voice_service.dart';
import '../features/router/router.dart';
import '../features/router/tools.dart';

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

/// Singleton provider for auth (anonymous → permanent upgrade, login).
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client),
);

// ─────────────────────────────────────────────────────────────────────
// Router (Phase 0.5 — DEC-050)
// ─────────────────────────────────────────────────────────────────────

/// Compile-time Gemini API key (same source as GeminiService).
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Singleton provider for the tool-calling router LLM backend.
/// Uses googleai_dart (DEC-050 SDK decision, flipped 2026-07-21 — pure
/// Dart, no Firebase dependency, no App Check gate needed for this path).
final routerLlmProvider = Provider<RouterLlm>(
  (ref) => GeminiRouterLlm(apiKey: _apiKey),
);

/// Singleton provider for the tool registry — all routable tools
/// wired to the live Supabase client.
final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) {
    final tools = createAllTools(Supabase.instance.client);
    return ToolRegistry(tools);
  },
);

/// Singleton provider for the tool-call trace service (DEC-050 §5).
/// Writes one row per routing decision to `tool_calls`.
final toolCallTraceServiceProvider = Provider<ToolCallTraceService>(
  (ref) => ToolCallTraceService(Supabase.instance.client),
);
