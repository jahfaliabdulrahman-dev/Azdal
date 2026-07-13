# Claude Handoff — Azdal Conversational Redesign (July 13, 2026)

> **Type:** Route A — direct instruction  
> **Designed by:** Opus 4.8 (3 rounds), reviewed by Claude  
> **Implemented by:** Sulaiman (DeepSeek-v4-pro)  
> **Device:** Tecno LJ7 — deployed via `adb`  
> **Commit:** `0d1a84d` — 438 insertions, 565 deletions (net negative)  

---

## Table of Contents

1. [Why This Change](#why-this-change)
2. [Architecture Before → After](#architecture-before--after)
3. [File-by-File Changes](#file-by-file-changes)
4. [Decision Log Entries](#decision-log-entries)
5. [Prompt Inventory](#prompt-inventory)
6. [Deleted Code](#deleted-code)
7. [Hard Invariants](#hard-invariants)
8. [Verification](#verification)
9. [Definition of Done](#definition-of-done)

---

## Why This Change

The previous session's "history leak" fix (16 commits, verified working) isolated transaction classification from conversation history to stop cross-message rebundling. That fix was correct but had two side effects found via live device testing:

1. **Amounts without "ريال" stopped classifying** (e.g. "50 بيض" failed, "50 ريال بيض" worked) — the isolated classify prompt lost implicit few-shot learning, and was never given an explicit currency-default rule.

2. **Responses became incoherent** — a conversational reply ("وش تقصد بـ 50 بيض؟") and a separate hardcoded "هل التصنيف صحيح؟" confirm widget appeared in the same bubble, contradicting each other, because they came from two uncoordinated Gemini calls stitched together after the fact.

This redesign fixes both by collapsing transaction-shaped input into a single history-free call that returns text + structured data together.

---

## Architecture Before → After

### Before (16-commit history leak fix)

```
User: "50 بيض"
  │
  ├─ sendMessage(text, history) — coach call, receives all conversation
  │    → "وش تقصد؟" or some conversational response
  │
  └─ _tryAutoClassify(text) — separate classification call
       → {amount: 50, category: "...", tone: "..."}
       → Hardcoded confirm UI: "هل التصنيف صحيح؟ ✅/🔄"
       
  PROBLEM: Two uncoordinated calls → incoherent bubble
```

### After (router-first)

```
User: "50 بيض"
  │
  ├─ hasDigit? YES → classifyTransaction(text) — single router call
  │    └─ _classifySystemPrompt (history-free, explicit JSON)
  │         → {"kind":"transaction","amount":50,"category":"بيض","tone":"gray",
  │            "reply":"تم تسجيل 50 ريال — بيض 🥚"}
  │         → Auto-saved immediately (DEC-021), no confirm tap
  │
User: "مرحبا"
  │
  ├─ hasDigit? NO → sendMessage(text, history) — coach call
  │    └─ _systemPrompt (conversational only, no widget instructions)
  │         → "هلا فيك! جاهز تسجل أول مصروف اليوم؟"
```

### Router `kind` Taxonomy

| `kind` | Meaning | Action | Widget |
|--------|---------|--------|--------|
| `transaction` | Single clear expense | Auto-save immediately | `↩️ تراجع` undo button only |
| `compound` | Multi-item split | Show card, wait for confirm | `compound_split_card` with ❌/✅ |
| `clarify` | Ambiguous, need more info | Ask one clear question | None (text only) |
| `chat` | Not a transaction | Fall through to coach prompt | None |

---

## File-by-File Changes

### `lib/core/services/gemini_service.dart` — Full Rewrite

| Section | Change |
|---------|--------|
| `_systemPrompt` | Replaced. Coach-only. Removed all widget instructions. No `summary_card`/`bar_chart` (they'd fabricate numbers per DEC-003). Contains 4 concrete few-shot examples. |
| `_classifySystemPrompt` | Replaced. Router prompt with 4 `kind` types. Explicit SAR-default rule ("50 بيض" = 50 SAR). Contains 3 few-shot examples per kind. |
| `_coldStartReactionPrompt` | New. History-free by construction — takes only two Dart-computed numbers. 3 concrete input→output examples. |
| `_extractJsonObject()` | New shared helper. Strips fences, greedily matches `{...}`, returns `Map<String, dynamic>?`. |
| `classifyTransaction()` | Simplified. Now uses `_extractJsonObject` instead of `_extractWidget`. Returns raw JSON map as `widget`. |
| `reactToColdStart()` | New. Takes `spendRatio` + `disposableAfterCommitments` (Dart-computed, zero user text). Returns LLM-authored `reply` string. |
| `ocrReceipt` prompt | Updated. Added `reply` field for descriptive receipt caption. 3 contextual few-shot examples. |

### `lib/features/chat/chat_screen.dart` — Major Restructure

| Section | Change |
|---------|--------|
| `_sendMessage()` | **Rewritten.** Router-first with digit gate. `hasDigit` → classifyTransaction. `!hasDigit` → coach path. Single call per message, no post-stitching. |
| `_saveAndAnnounceTransaction()` | **New.** Auto-saves immediately, shows undo button. Replaces `_confirmTransaction`. |
| `_handleColdStartSubmit()` | **Updated.** Now calls `reactToColdStart()` for personalized LLM reaction. Falls back to `_coldStartFallback(spendRatio)` on failure. |
| `_coldStartFallback()` | **New.** Hardcoded fallback — same two templates as before. |
| `_handleWidgetAction()` | **Trimmed.** Deleted `confirm`/`edit` action_buttons cases. Only `undo_transaction` survives. Compound split and OCR cases unchanged. |
| `_showOcrResult()` | **Updated.** Added `reply` parameter for OCR caption. Uses it as bubble text with verbatim fallback. |
| `_storedClassifications` | **Repurposed.** Now used ONLY for Layer 1 history filter. Classification results don't live here for simple transactions anymore (auto-save bypasses confirm). |
| `_isConfirming` field | **Deleted.** No confirm tap exists. |
| `_isUndoing` field | **Preserved.** Still guards undo double-tap. |

### Deleted Code

| Symbol | Reason |
|--------|--------|
| `_confirmTransaction(ChatProvider)` | Superseded by `_saveAndAnnounceTransaction` |
| `_isConfirming` field + guards | No confirm step exists |
| `_tryAutoClassify(String)` | Superseded by inline `kind` switch in `_sendMessage` |
| `action_buttons` handler: `value == 'confirm'` | No button with this value is ever produced |
| `action_buttons` handler: `value == 'edit'` | No button with this value is ever produced |

### `app-spec/12_decision_log.md`

- **DEC-021:** Auto-Save Simple Transactions, Drop Confirm Tap
- **DEC-022:** Bounded Reply Pattern (BRP) — Mandatory for All LLM-Authored Text Fields

### `app-spec/03_user_flows_navigation.md`

- Transaction Entry flow rewritten: auto-save, compound split distinction, undo note, Western numerals

---

## Decision Log Entries

### DEC-021: Auto-Save Simple Transactions, Drop Confirm Tap

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Single-item transactions save immediately on classification; the ✅ صحيح / 🔄 تعديل confirm step is removed. `↩️ تراجع` (DEC-020) is the safety net. |
| **Rationale** | The app's tagline promises "بدون تعب" — a mandatory confirm-tap contradicts that. The old "🔄 تعديل" never did real inline editing. Undo-then-retype is cleaner. |
| **Impact** | `compound_split_card` (multi-item) unaffected — keeps real ❌ إلغاء / ✅ تأكيد step. |

### DEC-022: Bounded Reply Pattern (BRP)

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Any LLM-authored text must be: (1) a single named JSON field; (2) explicit purpose; (3) tone/length bounds; (4) 2-3 few-shot examples in-prompt; (5) deterministic Dart fallback. |
| **Rationale** | 7 prompt iterations in the prior session drifted because no standing rule existed. BRP gives future edits a checklist. |

---

## Prompt Inventory

### 1. `_systemPrompt` — Coach (conversational chat, no-digit messages only)

| Property | Value |
|----------|-------|
| Role | Friendly Saudi financial coach |
| Widgets | **None.** No `action_buttons`, `compound_split_card`, `summary_card`, `bar_chart` |
| Arithmetic | Forbidden (DEC-003) |
| Length | 1-2 sentences, varied |
| Examples | 4 (greeting, performance question, purchase intent, summary request) |
| BRP compliance | ✅ (field: free-form text; bounded by tone/length/examples; fallback: Dart hardcoded) |

### 2. `_classifySystemPrompt` — Router (digit-containing messages, history-free)

| Property | Value |
|----------|-------|
| Role | Classification + reply formulation engine |
| Input | Single user message, no history |
| Output | JSON with `kind` + type-specific fields |
| `kind` values | `transaction`, `compound`, `clarify`, `chat` |
| Currency default | Any number with spending context = SAR |
| `reply` field | Bounded: Saudi dialect, warm, varied, 1 sentence, includes emoji |
| Examples | 3 per kind (in-prompt, never from history) |
| BRP compliance | ✅ (field: `reply`; bounded by tone/emoji/no-total; 3 examples per kind; fallback: Dart `'تم تسجيل N ريال — category'`) |

### 3. `_coldStartReactionPrompt` — Cold Start (numbers-only, history-free)

| Property | Value |
|----------|-------|
| Role | Personalized cold start reaction |
| Input | Two Dart-computed numbers as JSON |
| Output | `{"reply": "..."}` |
| Constraints | No invented numbers, no derived math, 1-2 sentences, Saudi dialect |
| Examples | 3 (85%/2000, 35%/4000, 100%/-500) |
| BRP compliance | ✅ (field: `reply`; Dart fallback: `_coldStartFallback(spendRatio)`) |

### 4. `ocrReceipt` prompt — OCR caption

| Property | Value |
|----------|-------|
| New field | `reply` — descriptive caption without totals |
| Constraints | No total, no sum, Saudi dialect, varied |
| Examples | 3 (supermarket, restaurant, gas station) |
| BRP compliance | ✅ (field: `reply`; Dart fallback: `'تم استخراج N بنود من الإيصال:'`) |

---

## Hard Invariants

These must not be violated by any future change:

1. **Transaction classification never receives conversation history** — this makes cross-message rebundling structurally impossible.
2. **Coach call's widget output is never trusted for transaction widgets** (`action_buttons`, `compound_split_card`) — those are always Dart-built from classification.
3. **No prompt contains anti-merge language** ("ignore previous messages", "only the last number", etc.) — three prior attempts proved fragile. Merge safety comes from code structure (history isolation).
4. **LLM never performs arithmetic** (DEC-003) — every sum/total is Dart-computed.
5. **All LLM-authored text follows BRP** (DEC-022) — single named JSON field, bounded, few-shot examples, Dart fallback.

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | Info-level `avoid_print` only (pre-existing pattern) |
| `flutter test` | 16/16 pass |
| `flutter build apk --release` | 58.7MB, successful |
| Device deployment | Tecno LJ7 via `adb install -r` |

---

## Definition of Done

Device-level verification required (not automatable from CI):

1. **Bare-number parsing:** send `50 بيض` (no "ريال") → auto-save as amount=50, undo button visible, no confirm tap.
2. **Coherent response:** send just `50` (ambiguous) → exactly one clarifying question, no undo/confirm widget.
3. **Compound split still works:** send multi-item message → compound_split_card with adjustable splits, Dart-computed total, explicit confirm required.
4. **Rebundling regression:** send two single-item transactions sequentially → each gets independent auto-save + undo, never merged. Verify via Supabase query.
5. **Undo works on auto-save:** tap ↩️ تراجع → `is_deleted = true`, bubble replaced.
6. **Coach chat unaffected:** send greeting/advice (no digit) → warm, varied reply, no widget.
7. **Summary request no longer fabricates:** send "لخص لي مصاريفي" → deferral text with NO invented numbers, NO summary_card/bar_chart.
8. **Cold Start reaction:** two different input profiles → distinct personalized reactions. Break API to verify hardcoded fallback.
9. **OCR caption:** two different receipt types → distinct descriptive captions, no totals in caption text.
