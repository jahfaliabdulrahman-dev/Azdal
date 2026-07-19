/// Intent router for Azdal chat — cheap regex-based pre-filter.
///
/// Classifies user messages into one of five gate decisions using
/// the same Arabic keyword regexes that previously lived in
/// `chat_screen.dart`.  This is a pure synchronous router — it
/// never calls any LLM and is never authoritative (the Gemini
/// classifiers downstream make the real decision).
///
/// Extracted during Phase 0 foundation work (2026-07-19) to:
/// - Make the regexes testable without instantiating a full screen
/// - Keep every pattern identical (MOVED, not deleted)
/// - Provide a single `classify` entry point for future router work
library;

// ─────────────────────────────────────────────────────────────────────
// Gate decision enum
// ─────────────────────────────────────────────────────────────────────

/// The five possible outcomes of the local regex-based intent gate.
///
/// `generalChat` is the fallback — the message is routed to the
/// general-purpose coach chat (possibly via a secondary LLM
/// classifier).
enum GateDecision {
  setupCommitment, // commitments or goals
  buyIntent,       // "can I buy X for Y"
  integrityQuery,  // "what's my integrity score"
  budgetQuery,     // "how much budget is left"
  generalChat,     // fallback
}

// ─────────────────────────────────────────────────────────────────────
// IntentRouter — static regexes + predicates + classify
// ─────────────────────────────────────────────────────────────────────

class IntentRouter {
  IntentRouter._(); // no instances — static utility class

  // ── Arabic text normalization ──────────────────────────────────
  // Casual/dialectal typing frequently drops hamza (أ/إ/آ → ا) and
  // varies ta-marbuta/alef-maqsura. Keyword regexes below are written
  // with plain alef only; normalize user input the same way before
  // matching, or common phrasings like "ابي اشتري" silently miss a
  // pattern written as "أبي أشتري".

  static String normalizeArabic(String s) => s
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');

  // ── Setup-intent heuristic (commitments/goals) — cheap local pre-filter

  static final RegExp commitmentKeywords = RegExp(normalizeArabic(
    'قسط|اقساط|التزام|التزامات|تمارا|تابي|تابى|سله|ايجار|قرض|تمويل|'
    'ديون|دين|اشتراك|اشتراكات',
  ));

  static final RegExp goalKeywords = RegExp(normalizeArabic(
    'هدف|اهداف|هدفي|ادخار|ادخر|ابي ادخر|اوفر|صندوق الطوارئ|'
    'عمره|حج',
  ));

  static bool looksLikeSetupIntent(String text) {
    final normalized = normalizeArabic(text);
    return commitmentKeywords.hasMatch(normalized) ||
        goalKeywords.hasMatch(normalized);
  }

  // ── Buy-intent heuristic (Stage 4) — cheap local pre-filter
  // Not authoritative: a miss falls through to classifyTransaction,
  // whose 'chat' branch runs one more classifyBuyIntent safety-net
  // check before giving up. This regex only decides whether to skip
  // a redundant round-trip, never whether the feature can fire at all.

  static final RegExp buyKeywords = RegExp(normalizeArabic(
    'ابي اشتري|ودي اشتري|ابغى اشتري|بشتري|كم سعر|هل اقدر|ينفع اشتري|'
    'اقدر اشتري|نفسي اشتري|افكر اشتري',
  ));

  static bool looksLikeBuyIntent(String text) =>
      buyKeywords.hasMatch(normalizeArabic(text));

  // ── Integrity-score query heuristic (Stage 4)

  static final RegExp integrityKeywords = RegExp(normalizeArabic(
    'كيف ادائي|كم درجه النزاهه|درجه النزاهه|نقاط النزاهه|نزاهتي|كيف نزاهتي',
  ));

  static bool looksLikeIntegrityQuery(String text) =>
      integrityKeywords.hasMatch(normalizeArabic(text));

  // ── Remaining-budget query heuristic — deterministic, no LLM
  // (DEC-003: this is a pure calculation, not something the LLM
  // should ever answer in free-form chat).

  static final RegExp budgetQueryKeywords = RegExp(normalizeArabic(
    'كم باقي|باقي من مصروفي|باقي من الشهر|باقي من ميزانيتي|كم فاضل|فاضل لي|'
    'وش وضع ميزانيتي|وضعي المالي|كم متبقي|باقي مصروف|كم باقي ميزانيه',
  ));

  static bool looksLikeBudgetQuery(String text) =>
      budgetQueryKeywords.hasMatch(normalizeArabic(text));

  // ── Intent Classification ────────────────────────────────────
  /// Runs the cascade of local regex gates and returns the first
  /// match, or [GateDecision.generalChat] as fallback.
  ///
  /// This is purely regex-based — it never calls an LLM. The order
  /// matches the existing cascade in `_sendMessage`.
  static GateDecision classify(String text) {
    if (looksLikeSetupIntent(text)) return GateDecision.setupCommitment;
    if (looksLikeBuyIntent(text)) return GateDecision.buyIntent;
    if (looksLikeIntegrityQuery(text)) return GateDecision.integrityQuery;
    if (looksLikeBudgetQuery(text)) return GateDecision.budgetQuery;
    return GateDecision.generalChat;
  }
}
