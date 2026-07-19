# Golden Intent Matrix

> **Purpose:** Ground-truth intent classification matrix encoding the *current*
> router's behavior — every real Saudi-dialect phrasing mapped to its expected
> intent + gate + classification path. Phase 4 (QA Tester) will convert this to
> JSONL and run it against the harness.
>
> **This is the Phase 0.5 migration safety net** (DEC-050, timing note). It
> captures today's regex-gated router behavior so the tool-calling replacement
> can be verified to agree on every row — and to expose any regressions before
> they hit a real device.
>
> **Source-of-truth:** The current router code at
> `lib/features/chat/chat_screen.dart:47-100` (regex gates) and `:301-500`
> (`_sendMessage` dispatch). Read before modifying this file.

---

## 1. `expected_intent` Enum (10 values)

The 10-value enum maps 1:1 to the planned Phase 0.5 tool names (DEC-050). Each
value is the *finest-grained* intent a message can carry — the expected behavior
after all routing + classification completes.

| # | Enum value | Arabic label | What it means |
|---|-----------|-------------|---------------|
| 1 | `setup_commitment` | إضافة/عرض التزام | User wants to add, view, or edit a financial commitment (قسط، إيجار، تمارا…) |
| 2 | `setup_goal` | إضافة/عرض هدف | User wants to add, view, or edit a savings goal |
| 3 | `evaluate_purchase` | تقييم شراء | User wants the buy engine to evaluate a specific item+amount (\"Can I buy X at Y?\") |
| 4 | `buy_query` | استفسار شراء | User asks about a product/price without requesting affordability analysis |
| 5 | `view_integrity` | عرض درجة النزاهة | User asks for their integrity score (درجة النزاهة) |
| 6 | `view_budget` | عرض الميزانية | User asks how much budget is left this month |
| 7 | `log_expense` | تسجيل مصروف | User states a single expense (item + amount) to log |
| 8 | `log_compound_expense` | تسجيل مصروف مركب | User states multiple expenses in one message |
| 9 | `clarify` | توضيح | The classifier cannot determine intent and must ask for clarification |
| 10 | `general_chat` | محادثة عامة | Anything else — greeting, gratitude, off-topic, coaching question |

## 2. `GateDecision` Enum (5 values)

The GateDecision represents the **current router's first-level branching**
decision — which pre-filter path the message takes (or doesn't). This is the
router's output *before* any LLM classification refines it.

| # | Enum value | How the current router decides |
|---|-----------|-------------------------------|
| 1 | `setup_commitment` | `_looksLikeSetupIntent` regex matches → `classifySetupIntent` called |
| 2 | `buy_intent` | `_looksLikeBuyIntent` regex matches → `classifyBuyIntent` called (or safety-net call from the `'chat'` fallback) |
| 3 | `integrity_query` | `_looksLikeIntegrityQuery` regex matches → deterministic `_showIntegrityScore()` (no LLM) |
| 4 | `budget_query` | `_looksLikeBudgetQuery` regex matches → deterministic `_showRemainingBudget()` (no LLM) |
| 5 | `general_chat` | No regex gate matched → falls through to general path. If `hasDigit`: `classifyTransaction` runs (log_expense / log_compound_expense / clarify / chat). If no digit: `sendMessage` runs (free-form coach chat). |

### `requires_llm_classify` (bool)

A per-row flag indicating whether the **routing decision** involves an LLM call
(to confirm the gate or to further classify within the gate).

| GateDecision | requires_llm_classify | Why |
|-------------|----------------------|-----|
| `setup_commitment` | **true** | Regex pre-filter matched, but `classifySetupIntent` (LLM) must confirm the exact kind (commitment_add/view/edit, goal_add/view/edit, or none) |
| `buy_intent` | **true** | Regex pre-filter matched (or safety-net triggered), but `classifyBuyIntent` (LLM) must extract item/amount and confirm buy_intent vs buy_query vs none |
| `integrity_query` | **false** | Purely keyword → deterministic; no LLM call in the routing path |
| `budget_query` | **false** | Purely keyword → deterministic; no LLM call in the routing path |
| `general_chat` (digit-bearing) | **true** | `classifyTransaction` (LLM) runs to distinguish transaction/compound/clarify/chat |
| `general_chat` (no digit) | **false** | Goes directly to `sendMessage` (coach LLM) — no *classification* step, though the coach reply itself involves an LLM |

## 3. Golden Matrix Rows

Each row is one test case. The harness asserts that the current router produces
`expected_gate` and, within that gate, `expected_intent`. The `ground_truth`
column holds extracted figures as explicit literal data — never LLM-derived
(DEC-024).

**Coverage rule:** ≥2 rows per `expected_intent` value.

### Row ID convention
`GM-###` where ### is a zero-padded sequential number.

### 3.1 setup_commitment rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-001 | عندي قسط تمارا ٢٠٠ ريال | setup_commitment | setup_commitment | true | — | Commitment keyword + BNPL provider + amount |
| GM-002 | بضيف إيجار الشقة ٢٠٠٠ شهريا | setup_commitment | setup_commitment | true | — | Commitment keyword + recurring amount |
| GM-003 | ودي اسجل التزام جديد | setup_commitment | setup_commitment | true | — | Commitment keyword, no amount — classifier must return kind |
| GM-004 | وش التزاماتي الحين | setup_commitment | setup_commitment | true | — | View-commitments phrasing (classifier → commitment_view) |

### 3.2 setup_goal rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-005 | هدفي اوفر ١٠٠٠٠ ريال للسيارة | setup_goal | setup_commitment | true | — | Goal keyword + amount + target item |
| GM-006 | ابغى احط هدف للطوارئ | setup_goal | setup_commitment | true | — | Goal keyword, no amount |
| GM-007 | كم باقي لي عشان احقق هدفي | setup_goal | setup_commitment | true | — | Goal-view query (classifier → goal_view) |

### 3.3 evaluate_purchase rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-008 | ابي اشتري جوال بـ ٣٠٠٠ | evaluate_purchase | buy_intent | true | `{"item": "جوال", "amount": 3000}` | **LL-011 hamza-dropped**: "ابي" not "أبي" |
| GM-009 | أبي أشتري جوال بـ ٣٠٠٠ | evaluate_purchase | buy_intent | true | `{"item": "جوال", "amount": 3000}` | **LL-011 with-hamza variant** — same intent, different spelling |
| GM-010 | ودي اشتري لابتوب بـ ٤٠٠٠ ريال | evaluate_purchase | buy_intent | true | `{"item": "لابتوب", "amount": 4000}` | "ودي اشتري" = standard buy keyword |
| GM-011 | هل أقدر أشتري آيباد بـ ٢٥٠٠ | evaluate_purchase | buy_intent | true | `{"item": "آيباد", "amount": 2500}` | Interrogative buy phrasing — per DEC-037-B, any message naming an item is `buy_intent` regardless of interrogative form |
| GM-012 | ينفع اشتري ساعة بـ ٨٠٠ | evaluate_purchase | buy_intent | true | `{"item": "ساعة", "amount": 800}` | "ينفع اشتري" = buy keyword variant |
| GM-013 | بشتري تلفزيون بـ ٢٥٠٠ | evaluate_purchase | buy_intent | true | `{"item": "تلفزيون", "amount": 2500}` | "بشتري" = future-tense buy |

### 3.4 buy_query rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-014 | كم سعر ايفون ١٦ الحين | buy_query | buy_intent | true | `{"item": "ايفون ١٦"}` | Price query — no "اشتري", classifier → buy_query |
| GM-015 | وش رايك في سعر البلايستيشن ٥ | buy_query | buy_intent | true | `{"item": "بلايستيشن ٥"}` | Opinion-on-price query |

### 3.5 view_integrity rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-016 | كيف درجة النزاهة حقي | view_integrity | integrity_query | false | — | Direct integrity keyword |
| GM-017 | كم نقاط النزاهة | view_integrity | integrity_query | false | — | Variant: "نقاط" instead of "درجة" |
| GM-018 | نزاهتي | view_integrity | integrity_query | false | — | Short query — single keyword |

### 3.6 view_budget rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-019 | كم باقي من ميزانيتي | view_budget | budget_query | false | — | Standard budget keyword |
| GM-020 | باقي من المصروف | view_budget | budget_query | false | — | Short variant — "باقي من" keyword |
| GM-021 | كم فاضل لي ذا الشهر | view_budget | budget_query | false | — | "كم فاضل" + time context |

### 3.7 log_expense rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-022 | غداء ٣٥ ريال | log_expense | general_chat | true | — | Simple expense — digit-bearing, no buy/setup/integrity/budget keywords → classifyTransaction → transaction |
| GM-023 | قهوة ١٢ | log_expense | general_chat | true | — | Simple expense, no unit/category word — classifier must infer |
| GM-024 | بنزين ٢٠٠ | log_expense | general_chat | true | — | Simple expense, Arabic-Indic digits (٢٠٠ = 200) |

### 3.8 log_compound_expense rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-025 | مقاضي ٢٠٠ وبنزين ١٥٠ وعشاء ٨٠ | log_compound_expense | general_chat | true | — | Three items, digit-bearing → classifyTransaction → compound |
| GM-026 | فطور ٣٠ وغدا ٥٠ وقهوة ١٥ | log_compound_expense | general_chat | true | — | Three items with amounts |

### 3.9 clarify rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-027 | ١٢ | clarify | general_chat | true | — | Bare digit — no parseable item, classifier should return clarify |
| GM-028 | اشتريت شيء | clarify | general_chat | true | — | Digit-less transaction attempt — classifier cannot extract amount |

### 3.10 general_chat rows

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-029 | شكرا لك | general_chat | general_chat | false | — | No-digit gratitude — straight to coach LLM |
| GM-030 | كيف حالك اليوم | general_chat | general_chat | false | — | No-digit greeting |
| GM-031 | وش تنصحني اسوي بفلوسي | general_chat | general_chat | false | — | Coaching question — no digit, no keyword match |

### 3.11 Multi-intent row (DEC-039a — documented limitation)

| ID | message (Saudi dialect) | expected_intent | expected_gate | requires_llm_classify | ground_truth | notes |
|----|------------------------|-----------------|---------------|----------------------|-------------|-------|
| GM-032 | جوال بـ ٢٠٠٠ ودراجة بـ ٨٠٠ | evaluate_purchase | buy_intent | true | `{"items": [{"item": "جوال", "amount": 2000}, {"item": "دراجة", "amount": 800}]}` | **DEC-039a multi-intent**: the current single-item classifier extracts only the first item. Sending as two separate messages works correctly. Documented limitation — Phase 0.5 tool-calling router resolves this via parallel calls (DEC-050). |

## 4. Matrix Summary

| expected_intent | Row count | Row IDs |
|-----------------|-----------|---------|
| setup_commitment | 4 | GM-001–004 |
| setup_goal | 3 | GM-005–007 |
| evaluate_purchase | 6 | GM-008–013 |
| buy_query | 2 | GM-014–015 |
| view_integrity | 3 | GM-016–018 |
| view_budget | 3 | GM-019–021 |
| log_expense | 3 | GM-022–024 |
| log_compound_expense | 2 | GM-025–026 |
| clarify | 2 | GM-027–028 |
| general_chat | 3 | GM-029–031 |
| multi-intent (DEC-039a) | 1 | GM-032 |
| **Total** | **32** | |

## 5. FakeGeminiService Interface Spec

The Phase 4 harness needs a `FakeGeminiService` that returns **pinned responses**
for `requires_llm_classify=true` rows, so the harness can assert `expected_gate`
and `expected_intent` without a real LLM (or an internet connection).

### 5.1 Interface shape

```dart
/// Pinned-response fake for the harness. Pre-loaded with a
/// message→response map from the golden matrix rows that have
/// requires_llm_classify=true.
abstract class FakeGeminiService {
  /// Load pinned responses from a Map<String, PinnedResponse>.
  /// Key = exact user message text (as stored in the matrix).
  void loadResponses(Map<String, PinnedResponse> responses);

  /// Mirrors the real GeminiService.classifySetupIntent signature.
  /// Returns the pinned response for [text] if loaded; throws
  /// [UnpinnedMessageException] otherwise (the harness must
  /// pre-load every requires_llm_classify row before running).
  Future<GeminiResponse> classifySetupIntent(String text);

  /// Mirrors the real GeminiService.classifyBuyIntent signature.
  Future<GeminiResponse> classifyBuyIntent(String text);

  /// Mirrors the real GeminiService.classifyTransaction signature.
  Future<GeminiResponse> classifyTransaction(String text);

  /// Mirrors the real GeminiService.sendMessage signature.
  /// Only needed for general_chat rows where requires_llm_classify=false;
  /// the harness asserts that these messages NEVER hit a classifier.
  Future<GeminiResponse> sendMessage(String text, {List<ChatMessage>? history});
}
```

### 5.2 `PinnedResponse` shape

```dart
class PinnedResponse {
  /// The widget payload the real service would return.
  /// Must include at minimum:
  ///   - classifySetupIntent: {'kind': 'commitment_add'|'goal_add'|...|'none'}
  ///   - classifyBuyIntent:   {'kind': 'buy_intent'|'buy_query'|'none', 'item': ..., 'amount': ...}
  ///   - classifyTransaction: {'kind': 'transaction'|'compound'|'clarify'|'chat', ...}
  final Map<String, dynamic>? widget;

  /// Plain-text reply (for general_chat / fallback paths).
  final String? text;

  /// Whether the fake should simulate an error.
  final bool hasError;
  final String? error;

  const PinnedResponse({this.widget, this.text, this.hasError = false, this.error});
}
```

### 5.3 Loading — which rows need pinned responses

The harness must pre-load `FakeGeminiService` with every row where
`requires_llm_classify=true`. The pinned response must return the widget
that causes the router to reach `expected_intent`:

| Row ID | Fake method to pin | Pinned `widget['kind']` | Notes |
|--------|-------------------|------------------------|-------|
| GM-001–004 | `classifySetupIntent` | `commitment_add`, `commitment_view`, etc. | Match the expected intent |
| GM-005–007 | `classifySetupIntent` | `goal_add`, `goal_view` | Setup gate dispatches based on kind |
| GM-008–013 | `classifyBuyIntent` | `buy_intent` | With extracted item + amount |
| GM-014–015 | `classifyBuyIntent` | `buy_query` | Item only, no amount |
| GM-022–024 | `classifyTransaction` | `transaction` | With category, amount, tone, reply |
| GM-025–026 | `classifyTransaction` | `compound` | With splits array |
| GM-027–028 | `classifyTransaction` | `clarify` | Reply text asking for clarification |
| GM-032 | `classifyBuyIntent` | `buy_intent` | First item only (current limitation) |

Rows where `requires_llm_classify=false` (GM-016–021, GM-029–031) must NOT
trigger any classifier call. The harness asserts that these messages bypass
the LLM entirely and reach their deterministic handler (integrity/budget/coach)
via keyword match or fallthrough.

### 5.4 Harness assertion contract

For each golden row, the harness:

1. Feeds `message` to the router (wired to `FakeGeminiService`).
2. Asserts the router reaches `expected_gate`.
3. Within that gate, asserts the router reaches `expected_intent`.
4. For `requires_llm_classify=true` rows: asserts the correct fake method
   was called with the exact message text.
5. For `requires_llm_classify=false` rows: asserts NO fake method was called.
6. For rows with `ground_truth`: asserts the extracted data matches the
   stored ground_truth values exactly.

## 6. LL-011 Coverage Confirmation

The hamza-dropped issue (LL-011, DEC-037-B) is explicitly covered:

| Row | Variant | Spelling |
|-----|---------|----------|
| GM-008 | Hamza-dropped | `ابي اشتري` |
| GM-009 | With hamza | `أبي أشتري` |

Both must route identically to `evaluate_purchase` / `buy_intent`. The current
router's `_normalizeArabic()` (which maps `أ`→`ا`) should handle this — the
golden matrix confirms it does.

## 7. DEC-024 Compliance

All `ground_truth` values in §3 are stored as **explicit JSON literals** in
this file. They are never computed by an LLM at classification time. The
harness compares extracted figures against these stored values directly.

---

## MVP Compliance Check

- [x] Feature maps to approved Feature ID in 01_prd.md (Phase 0 — golden intent matrix per 21_personal_build_plan.md:102-108, :145-156)
- [x] Within MVP scope boundaries (Phase 0 foundation — migration safety net)
- [x] No scope creep introduced (no router/tool-calling/firebase_ai — Phase 0.5 only)
- [x] Monetization rules respected (File 02 — not applicable; this is test infrastructure)

---

## Traceability

| Artifact | Reference |
|----------|-----------|
| Source files read | `app-spec/21_personal_build_plan.md`, `app-spec/12_decision_log.md` (DEC-024, DEC-037-B, DEC-039, DEC-048, DEC-050), `app-spec/00_lessons_learned.md` (LL-010, LL-011), `lib/features/chat/chat_screen.dart:47-100`, `:301-500` |
| MVP features referenced | Phase 0 Foundation (21_personal_build_plan.md §Phase 0) |
| Features NOT in MVP that were excluded | Phase 0.5 router redesign (explicitly excluded), DEC-039 fixes (explicitly excluded), test code (explicitly excluded) |
| Conflicts found with existing specs | none |
| Row count | 32 |
| Enum values | expected_intent: 10, GateDecision: 5 |
| Scope leak check | No firebase_ai, no router design, no DEC-039 fixes, no test code |
