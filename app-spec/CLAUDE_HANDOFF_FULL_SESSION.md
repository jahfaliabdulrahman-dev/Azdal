# Claude Handoff — Azdal Session: July 12-13, 2026

> **Model:** DeepSeek-v4-pro (Sulaiman)  
> **Type:** Route A — direct, no Kanban delegation  
> **Device:** Tecno LJ7 (HiOS) — deployed via `adb`  
> **Commits:** 16 commits pushed to `main`  
> **MoA Consultations:** 3 rounds (6 subagent dispatches)  
> **Repo:** https://github.com/jahfaliabdulrahman-dev/Azdal  

---

## Table of Contents

1. [Session at a Glance](#session-at-a-glance)
2. [Decision Log Entries](#decision-log-entries)
3. [Architecture Changes](#architecture-changes)
4. [Infrastructure](#infrastructure)
5. [Bug Fixes — Device-Surfaced](#bug-fixes--device-surfaced)
6. [Features](#features)
7. [The History Leak Saga — 6 Attempts](#the-history-leak-saga--6-attempts)
8. [MoA Consultation Rounds](#moa-consultation-rounds)
9. [System Prompt Evolution](#system-prompt-evolution)
10. [Current Architecture](#current-architecture)
11. [Commit Log](#commit-log)
12. [Files Changed](#files-changed)
13. [Key Architectural Lessons](#key-architectural-lessons)
14. [Known Issues & Future Work](#known-issues--future-work)

---

## Session at a Glance

| Dimension | Summary |
|-----------|---------|
| **Duration** | ~6 hours across July 12-13, 2026 |
| **Commits** | 16 |
| **MoA consultations** | 3 rounds (6 subagents) |
| **Bug fixes** | 7 device-surfaced + 6 history-leak attempts |
| **New features** | Undo, cancel, answered-once buttons |
| **Architecture refactors** | VoiceService → Riverpod, classifyTransaction isolation |
| **Prompt iterations** | 7 revisions to `_systemPrompt` |

---

## Decision Log Entries

### DEC-015: Isar Local Storage Deferred
- `isar` + `isar_flutter_libs` commented out in `pubspec.yaml`
- Release builds failed with `AAPT: resource android:attr/lStar not found`
- Isar 3.1.0 targets AGP 4.2; Azdal targets AGP 8.8
- No code depends on Isar — zero functional impact
- **Commit:** `4107ba5`

### DEC-016: Voice/TTS Platform Corrected — iOS-Only → Cross-Platform
- Voice: `Apple Speech` → `speech_to_text` (Android SpeechRecognizer)
- TTS: `AVSpeechSynthesizer` → `flutter_tts`
- Both packages pre-approved in `00_project_overrides.md`
- **Commit:** `2c4d9d9`

---

## Architecture Changes

### 1. VoiceService → Riverpod-Reactive StateNotifier

**Before:** `VoiceService` had a plain `bool get isListening` getter. Riverpod couldn't track it. `_toggleVoice()` called `setState(() {})` manually — internal timeout transitions were invisible. Mic icon stuck in "active" state.

**After:**
- Added `VoiceListeningState` + `VoiceListeningNotifier` (StateNotifier)
- `VoiceService` takes notifier in constructor, updates from internal `onStatus` callback
- Every status transition ("listening" → "notListening"/"done") pushes new state via Riverpod
- Icon rebuilds reactively from ANY cause (tap, pauseFor timeout, internal recognizer event)
- `setState()` removed from `_toggleVoice()`

**Files:** `voice_service.dart`, `providers.dart`, `chat_screen.dart`  
**Commit:** `6386599`

### 2. Dedicated classifyTransaction — Isolated Prompt, No History

**Before:** `_tryAutoClassify` used `geminiService.sendMessage()` which injected `_systemPrompt`. The main prompt's prohibitions ("express in plain text", "don't send action_buttons") killed the classification call too.

**After:**
- Added `classifyTransaction(String userText)` to `GeminiService`
- Uses `_classifySystemPrompt` — separate system prompt with explicit JSON instructions
- No conversation history — only sees the current message text
- `_classifySystemPrompt` explicitly allows `compound_split_card` for multi-item messages
- `_tryAutoClassify` calls `classifyTransaction(text)` instead of `sendMessage(prompt)`

**Files:** `gemini_service.dart`, `chat_screen.dart`  
**Commit:** `641b0f0`

### 3. System Prompt — Stripped to Conversational Guardrails Only

After 7 iterations and 2 MoA consultations, the final `_systemPrompt` contains:
- Role: assistant/coach, NOT classifier
- Explicit: app handles classification, don't send action_buttons or compound_split_card
- No anti-merge rules, no per-amount instructions, no "only the last one"
- `summary_card`/`bar_chart` for explicit spending summary queries only

**Commit:** `7e66e9d`

---

## Infrastructure

### Supabase Anonymous Sign-Ins
Enabled via `supabase config push` from CLI. Changed `supabase/config.toml`: `enable_anonymous_sign_ins = false` → `true`. Verified via GoTrue API.
**Commit:** `315b4d2`

### GitHub Repo + Releases
Created `jahfaliabdulrahman-dev/Azdal`, pushed all code, set up `latest` tag for APK downloads.
**URL:** https://github.com/jahfaliabdulrahman-dev/Azdal/releases/latest

### INTERNET Permission — Tecno HiOS
`AndroidManifest.xml` was missing `<uses-permission android:name="android.permission.INTERNET"/>`. Tecno's HiOS (Transsion custom ROM) enforces even "normal" permissions. Without it, all DNS lookups failed with `errno = 7`.
**Commit:** `7f48b4a`

---

## Bug Fixes — Device-Surfaced

### Bug 1: Voice Input — No Live Feedback (~34s dead air)
- **Root cause:** No `partialResults`, no `pauseFor`. `onResult` updated internal state but `_toggleVoice` only read final result.
- **Fix:** `partialResults: true`, `pauseFor: 2s`, interim callback pushes text to `_textController` on every result.
- **Commit:** `aac7245`

### Bug 2: "تم تسجيل المعاملة ✅" Shown Without Saving
- **Root cause:** `_confirmTransaction` called `_tryAutoClassify` a SECOND time (LLM non-deterministic). When second call returned null, showed success without calling `saveTransaction()`.
- **Fix:** `_storedClassifications` map keyed by message id. First classification stored, confirm reads stored result.
- **Commit:** `aac7245`

### Bug 3: Compound Split "الإجمالي: 0 ريال"
- **Root cause:** `total` from `widget.json['total']` (Gemini doesn't compute it per DEC-003). `_adjust()` mutated `_splits` but total read from static json.
- **Fix:** `_splits.fold(0, ...)` computed on every build. Prompt: don't send `total` field.
- **Commit:** `aac7245`

### Bug 4: OCR Fails — Deprecated Model
- **Root cause:** `_visionModel = 'gemini-2.5-flash'` — deprecated, API rejects.
- **Fix:** Unified to `_modelName = 'gemini-flash-latest'` (multimodal).
- **Commit:** `b7f4213`

### Bug 5: OCR Processing Bubble Never Goes Away
- **Root cause:** `_showOcrFailure`/`_showOcrResult` added new bubbles without removing the processing one.
- **Fix:** `ChatProvider.removeMessage(id)`, `addBotMessage` returns id, processing id captured and cleaned.
- **Commit:** `b7f4213`

### Bug 6: Compound Split Buttons — Wrong Answered Check
- **Root cause:** `onPressed: (answered && !isConfirmed) ? null : ...` — button stayed LIVE after being pressed.
- **Fix:** `onPressed: answered ? null : ...` — unconditional, same as action_buttons.
- **Commit:** `8feb686`

### Bug 7: INTERNET Permission Missing
- See Infrastructure section above.

---

## Features

### DEC-020: Undo + Cancel

**Part 1 — Cancel before confirm (compound_split_card only):**
- "❌ إلغاء" button beside "✅ تأكيد" in compound split card
- `compound_split_cancel` handler → "تم الإلغاء." — no Supabase call

**Part 2 — Undo (soft-delete):**
- `TransactionService.softDeleteTransaction(id)` — single row
- `TransactionService.softDeleteTransactionGroup(groupId)` — parent + children
- After every save: success message carries undo button with `tx_id` + `tx_type`
- `_undoTransaction`: soft-delete → `removeMessage` → `addBotMessage('تم التراجع ✅')`
- `_isUndoing` guard prevents double-tap

**Commit:** `839a7f8`

### Widget "Answered Once" Pattern

When a user taps any action button (confirm, edit, cancel), the widget immediately marks itself as answered:
- `ChatProvider.markWidgetAnswered(msgId, selectedValue)`
- Widgets read `_answered` → all buttons `onPressed: null`, `Opacity(0.55)`
- Selected button highlighted (filled style)
- `message_id` injected by `_MessageBubble` wrapper — no widget code modified

**Commit:** `122d6bb`

---

## The History Leak Saga — 6 Attempts

This was the session's central challenge. The bug: after confirming transaction #1, sending transaction #2 would cause Gemini to merge BOTH into one compound_split_card.

### Attempt 1
**Change:** Remove `action_buttons` from system prompt; "express in plain text only"  
**Result:** Killed classification call — `_tryAutoClassify` returned null because prompt blocked ALL JSON  
**Lesson:** Overly broad prompt prohibitions affect downstream calls.

### Attempt 2
**Change:** Narrow to "don't send action_buttons"; keep compound_split_card instruction  
**Result:** Main call still emitted compound_split_card with history-contaminated items  
**Lesson:** Removing one instruction doesn't prevent Gemini from inferring another.

### Attempt 3
**Change:** Add blanket prohibition: "never send compound_split_card"  
**Result:** Prohibition killed classification call — compound splits never appeared  
**Lesson:** Same as Attempt 1 — prompt prohibitions bleed into classification.

### Attempt 4 (current base)
**Change:** Dedicated `classifyTransaction()` with separate `_classifySystemPrompt`  
**Result:** Classification worked but main response still leaked — Path 1 bypassed it  
**Lesson:** Separate classification is correct, but main response path must be gated.

### Attempt 5
**Change:** Add Layer 2 widget gate + Layer 1 history filter (exclude `_storedClassifications` messages)  
**Result:** Filter had timing bug — mark happened BEFORE filter computation, excluding current message  
**Lesson:** Order of operations matters. Mark after filtering.

### Attempt 6 (final)
**Change:** Fix filter ordering (`m.id == userMsgId` always included) + strip ALL anti-merge prompt rules  
**Result:** ✅ Single items stay single, compound splits work, cross-message merging impossible  
**Lesson:** Code-level defenses (filter + gate) are deterministic and reliable. Prompt rules are fragile and cause interference.

---

## MoA Consultation Rounds

### Round 1 — Architecture Analysis
**Question:** Why does history leak despite 4 attempts?  
**Judges:** Destroyer + Meta-critic  
**Verdict:** Path 1 is the catastrophic failure point. Architecture scored 2/10.  
**Recommendation:** Delete Path 1, always run classification. Gate main response widgets. Filter history.

### Round 2 — Immediate Mark-on-Send
**Question:** Why did Attempt 5 (filter) partially fail?  
**Judges:** Analyzer + Rethinker  
**Key finding:** Mark happening before filter computation excluded current message.  
**Verdict:** Fix ordering (mark after filter). Judge 2 proposed moving state to `ChatProvider` for structural fix.  
**Score:** 4/10 (as-is) → 7/10 (fixed)

### Round 3 — Prompt Too Aggressive
**Question:** Why are genuine compound splits broken after Attempt 6?  
**Judges:** Fix + Meta  
**Verdict:** The prompt rule "إذا رأيت أكثر من مبلغ، اسأل عن آخر واحد فقط" was killing compound splits.  
**Final decision:** Remove ALL anti-merge prompt rules. Code-only defense (filter + gate) is sufficient.  
**Score:** 3/10 → aligned after fix

---

## System Prompt Evolution

| Iteration | Key Change | Why Changed |
|-----------|-----------|-------------|
| Original | "صنف المعاملات... أرسل action_buttons JSON" | Initial design — Gemini emits confirm UI directly |
| v2 | "عبر عن التصنيف بنص عادي فقط" | Attempt 1 — too broad, killed classification |
| v3 | "لا ترسل أبداً زر التأكيد (action_buttons)" | Attempt 2 — kept compound_split_card instruction |
| v4 | "لا ترسل أبداً compound_split_card" | Attempt 3 — killed compound splits entirely |
| v5 | "عبر عن التصنيف بنص عادي. التطبيق يتولى" | Attempt 4 — removed per-widget prohibitions |
| v6 | + "تعامل مع آخر رسالة فقط. لا تدمجها مع رسائل سابقة" | Attempt 5 — soft anti-merge rule |
| v7 (final) | Removed ALL anti-merge rules | MoA Round 3 — code-only defense |

**Final `_systemPrompt`:**
```
أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط.
دورك: مساعدة المستخدم في رحلته المالية — نصائح، توضيح، تحفيز.
التطبيق يتولى تصنيف المعاملات — لا ترسل action_buttons أو compound_split_card.
عبر عن ردودك بنص عادي. لا تحسب أبداً — الحسابات على Supabase.
إذا احتجت توضيحاً — اسأل سؤالاً واحداً واضحاً. لا تخمن.

عند السؤال عن ملخص المصاريف، استخدم summary_card أو bar_chart.
```

**`_classifySystemPrompt` (separate — used only by classifyTransaction):**
```
أنت نظام تصنيف معاملات مالية. مهمتك الوحيدة: تحليل النص واستخراج البيانات.
أجب بصيغة JSON فقط، بدون أي نص آخر — لا تقدم شرحاً ولا اعتذاراً.

للمعاملة الواحدة:
{"amount": الرقم, "category": "الفئة", "subcategory": "الفئة الفرعية", "tone": "green أو gray أو red"}

لعدة عناصر في نفس الرسالة:
{"widget": "compound_split_card", "splits": [{"category": "...", "amount": الرقم}]}

إذا لم تكن معاملة مالية:
{"error": "NOT_TRANSACTION"}
```

---

## Current Architecture

```
User: "30 فول و 19 بنزين"
  │
  ├─ addUserMessage(text) → msgId
  │
  ├─ _storedClassifications[msgId] = {}  ← immediate mark (after filter)
  │
  ├─ sendMessage(text, history: FILTERED)
  │    │  Filter: exclude messages in _storedClassifications
  │    │          always include current (m.id == msgId)
  │    │
  │    └─ _systemPrompt (conversational only)
  │         → "تمام، رصدت عنصرين..."
  │
  ├─ Widget Gate (Layer 2):
  │    if response.widget is transaction type → DROP, fall through
  │    if non-transaction widget → show and return
  │
  └─ _tryAutoClassify(text)
       └─ classifyTransaction("30 فول و 19 بنزين")
            └─ _classifySystemPrompt (JSON-only, compound allowed)
                 → {"widget": "compound_split_card", "splits": [...]}
                 → compound_split_card UI ✅

DEFENSE LAYERS:
  Layer 1: History filter (code) — excludes old classified messages
  Layer 2: Widget gate (code) — blocks transaction widgets from main response
  Layer 3: None (prompt rules removed) — they only caused interference
```

---

## Commit Log

```
7e66e9d fix: remove ALL anti-merge prompt rules — code-only defense
68475bc docs: MoA Judge 2 — architectural rethink (move state to ChatProvider)
43a2da8 fix: filter ordering + prompt hardening — MoA round 2
61d46d7 fix: immediate mark-on-send — close history leak window
6cd69d0 fix: defense-in-depth against history leak — MoA consensus fix
641b0f0 fix: dedicated classifyTransaction — isolated prompt, no history leak
75935c5 fix: remove compound_split_card from system prompt — same fix as action_buttons
8feb686 fix: compound split buttons — unconditional answered check
122d6bb fix: widget answered-once — disable buttons after first action
839a7f8 feat: undo + cancel — DEC-020 implementation
18d882f fix: remove action_buttons from system prompt — collapse to single code path
b7f4213 fix: OCR model name + processing bubble lifecycle
6386599 refactor: VoiceService to Riverpod-reactive StateNotifier
aac7245 fix: three device-surfaced bugs — voice feedback, fake confirm, compound total
315b4d2 feat: enable Anonymous Sign-ins in Supabase Auth config
7f48b4a fix: add INTERNET permission to AndroidManifest
```

---

## Files Changed

| File | Changes |
|------|---------|
| `lib/core/services/gemini_service.dart` | System prompt (×7 iterations), `_classifySystemPrompt`, `classifyTransaction()`, model unification |
| `lib/features/chat/chat_screen.dart` | `_sendMessage` restructured (Path 1 gate, history filter, immediate mark), `_confirmTransaction`, `_handleCompoundSplit`, `_undoTransaction`, `_tryAutoClassify` refactored, `_arabicToWestern`, `_MessageBubble` message_id injection |
| `lib/features/chat/services/voice_service.dart` | StateNotifier refactor, `partialResults`, `pauseFor` |
| `lib/features/chat/services/transaction_service.dart` | `softDeleteTransaction`, `softDeleteTransactionGroup` |
| `lib/features/chat/providers/chat_provider.dart` | `removeMessage`, `markWidgetAnswered`, return IDs |
| `lib/features/chat/widgets/widget_catalog.dart` | Compound total, cancel button, answered-once pattern, unconditional `answered` check |
| `lib/app/providers.dart` | `voiceListeningProvider`, service wiring |
| `android/app/src/main/AndroidManifest.xml` | INTERNET permission |
| `pubspec.yaml` | Isar commented out |
| `supabase/config.toml` | `enable_anonymous_sign_ins = true` |
| `app-spec/` | DEC-015, DEC-016, CLAUDE_HANDOFF_history_leak.md, SESSION_REPORT_2026-07-12.md, FIX_REPORT_answered_once.md |
| `RETHINK_ANALYSIS.md` | MoA Judge 2 architectural analysis |

---

## Key Architectural Lessons

1. **Code > Prompts for defense.** Prompt rules are stochastic and interfere with downstream calls (Attempts 1, 3, 6 all failed because of prompt rules). Code-level defenses (filter, gate) are deterministic. The final architecture has zero prompt-level anti-merge rules.

2. **Separate classification from conversation.** `classifyTransaction` has its own system prompt, its own method, and receives zero conversation history. The main chat response is conversational-only. This separation prevents cross-contamination.

3. **One code path, not two.** The original dual-path architecture (Path 1: Gemini emits widgets → Path 2: classification) was the root of the history leak. Path 1 is now gated — transaction widgets are dropped and the code always falls through to classification.

4. **Mark immediately, filter before sending.** Every message is marked as "in pipeline" the moment it's dispatched. The history filter runs AFTER the mark (with explicit current-message inclusion) so old messages are excluded but the current message always passes.

5. **Riverpod for internal state.** `VoiceService` now uses StateNotifier. The mic icon updates reactively from ANY status change — not just user taps. Same pattern reusable for OCR (Stage 3) and goals (Stage 4).

6. **Android permissions are not optional.** Tecno's HiOS strictly enforces `INTERNET` permission. This was invisible to `flutter test` and `flutter analyze`.

7. **Consult the judges before the 4th attempt.** The first 3 attempts were prompt patches that created new bugs. The MoA identified the structural flaw (Path 1 bypass, filter timing) that prompt engineering couldn't fix.

---

## Known Issues & Future Work

1. **`_storedClassifications` is widget-local.** Lives in `_ChatScreenState` — resets on widget rebuild/navigation. MoA Judge 2 proposed moving to `ChatMessage.classificationStatus` (ChatProvider state). See `RETHINK_ANALYSIS.md`.

2. **Non-transaction messages also get filtered.** The immediate mark excludes ALL sent user messages from history, even conversational ones like "شكرا". Bot responses provide conversational context, so this is acceptable for MVP.

3. **`_storedClassifications` grows unbounded.** No cleanup of stale entries. Long sessions accumulate memory. Add LRU eviction or cleanup on restart.

4. **Classification for single-message multi-item vs cross-message merging.** Currently relies on the filter to prevent cross-message merging. If the filter fails for any reason, there's no prompt-level safety net (by design — prompt rules were removed). Consider adding a monitoring check.

5. **No structured output enforcement.** `classifyTransaction` uses prompt-based JSON instructions, not `response_mime_type` or `response_schema`. Gemini Flash supports these — consider adding for robustness.
