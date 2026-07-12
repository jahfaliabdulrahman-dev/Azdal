# Claude Handoff Report — Transaction History Leak

> **Date:** 2026-07-13  
> **Project:** Azdal — أزدل  
> **Bug Class:** History contamination → transaction merging  
> **Consultation:** Triple-Chinese MoA (2-round light protocol)  
> **4 Previous Attempts:** All failed (summarized below)  

---

## Problem

When a user sends transaction #2 after confirming/saving transaction #1, Gemini's main chat response sometimes merges the already-saved transaction #1 with the new #2 — showing either a compound_split_card with items from both messages, or textually describing "two transactions" when only one is new.

**User's exact report:** "ارسلت الاولى وحفظتها وبعدها ارسلت الثانية ولكنه دمجها مع الاولى... اعطاني رسالة جيمني بأنه رصد معاملتين وجاري تسجيلهم وكتب تفاصيل المعاملتين"

---

## Root Cause (Confirmed by MoA)

The `_buildContents` method in `gemini_service.dart` sends **ALL recent user messages** into the main Gemini chat call:

```dart
for (final msg in recentHistory) {
  if (msg.isUser) {
    contents.add(Content.text(msg.content));  // ← ALL prior transactions sent
  }
}
```

When user sends transaction #2 ("٣٠ ريال غداء"), Gemini's main call receives **both** amounts:
- History: "٥٠ ريال قهوة" (already saved)
- Current: "٣٠ ريال غداء" (new)
- System prompt: "عند السؤال عن ملخص المصاريف، استخدم summary_card أو bar_chart"

Gemini sees two amounts and thinks "this is a spending summary context" → pattern-matches to emit `compound_split_card`. Since `response.widget != null`, Path 1 fires and the widget is shown directly — **`_tryAutoClassify` is never called**.

Bot messages are stripped from history (line 163), so the "تم تسجيل المعاملة بنجاح ✅" confirmation is invisible — Gemini has NO WAY to know transaction #1 was already handled.

**MoA Verdict (Destroyer):** Architecture scored 2/10. "The fix with the highest ROI: Delete Path 1. ALWAYS run `_tryAutoClassify`."

---

## Four Failed Attempts

| # | Approach | Why It Failed |
|---|----------|--------------|
| 1 | Remove `action_buttons` from system prompt; "express in plain text only" | Killed classification call — `_tryAutoClassify` returned null because prompt blocked ALL JSON |
| 2 | Narrow to "don't send action_buttons"; keep compound_split_card instruction | Main call still emitted compound_split_card with history-contaminated items |
| 3 | Remove compound_split_card instruction; add blanket prohibition: "never send compound_split_card" | Prohibition killed `_tryAutoClassify` — compound splits never appeared even for genuine multi-item messages |
| 4 | Create dedicated `classifyTransaction()` with separate prompt; simplify main prompt to "express in plain text, app builds widgets" | Main prompt still says "use summary_card or bar_chart" — this legitimizes widget emission. Gemini infers compound_split_card is OK for multi-amount contexts. Path 1 still fires. |

**Common failure mode:** Each attempt treated a symptom (prompt wording) while leaving the structural flaw intact — the main chat response is trusted as a transaction authority even though it receives history-contaminated input.

---

## MoA Recommendations (Synthesized)

Both judges converge on the same architectural principle:

> **The main `sendMessage` response must NEVER be the authority on transaction classification. Classification is the gatekeeper; the main chat response provides conversational text only.**

### Consensus Fix (Defense in Depth — 2 layers)

#### Layer 1 — Filter history (root cause)
In `_buildContents`: exclude user messages that have been classified and confirmed. Only send unprocessed messages to Gemini's main call.

#### Layer 2 — Widget gate (defense)
In `_sendMessage` Path 1: if `response.widget['widget']` is `'compound_split_card'` or `'action_buttons'`, **drop it** and fall through to `_tryAutoClassify`. Only non-transaction widgets (summary_card, bar_chart, quick_input_form) pass through.

This is defense in depth:
- Layer 1 blocks the data that causes the problem (Gemini never sees old transactions)
- Layer 2 is the safety net — even if Gemini somehow emits a transaction widget, it's blocked

### Additional Recommendations

From the Destroyer:
- Optional: enforce `response_mime_type: 'application/json'` on `classifyTransaction` for structured output guarantee
- Optional: strip `summary_card`/`bar_chart` from `_systemPrompt`; handle spending summaries as separate post-processing calls
- Keep `_classifySystemPrompt` as-is — it's the only component that scored well (6/10)

From the Meta-critic:
- Option C (invert flow: classify first, then chat) is architecturally cleanest but higher risk for this session — implement as follow-up
- Option A (widget gate) is the immediate 5-line fix with zero risk

---

## Architecture After Fix

```
User: "٣٠ ريال غداء"
  │
  ├─ _buildContents with FILTERED history:
  │    Only includes unprocessed user messages
  │    → Gemini main call sees ONLY "٣٠ ريال غداء"
  │
  ├─ sendMessage(text, history: filtered) → _systemPrompt
  │    → "تمام، تصنيف: غذاء، ٣٠ ريال — النبرة رمادية"
  │    → response.widget == null (no widget instruction in prompt)
  │
  ├─ IF response.widget IS compound_split_card or action_buttons:
  │    → DROP IT (Layer 2 defense) → fall through
  │
  └─ _tryAutoClassify(text) → classifyTransaction(text)
       → _classifySystemPrompt (isolated, JSON-only)
       → {"amount": 30, "category": "غذاء", "tone": "gray"}
       → action_buttons confirm UI ✅
```

---

## Key Insight

> **"عدة عقول تنتج إجابات عظيمة"** — Several minds produce great answers.

The user's intuition was correct: "ماذا لو ان كل رسالة نجاوب عليها تحذف من الرسائل علشان ما يشوفها جيمني" — this is exactly the Layer 1 fix the MoA identified independently. The filtered history + widget gate combination is the defense-in-depth solution neither my initial analysis nor the judges arrived at individually — it emerged from the dialogue.

---

## What NOT to Change

- `classifyTransaction()` — scored 6/10, working correctly, properly isolated
- `_classifySystemPrompt` — explicit JSON instructions, no conflicts
- `_tryAutoClassify` parsing — working, handles both simple and compound
- Undo/cancel flow — unrelated to this bug class
- `ChatProvider` — no changes needed

---

## Files to Modify

1. `lib/core/services/gemini_service.dart`:
   - `_buildContents`: filter out confirmed user messages
   - `_systemPrompt`: keep clean ("express in plain text"), remove widget instructions entirely
2. `lib/features/chat/chat_screen.dart`:
   - `_sendMessage` Path 1: add widget type gate (block transaction widgets)
