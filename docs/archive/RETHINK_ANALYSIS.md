# RETHINK: Making the History-Leak Bug Class IMPOSSIBLE

## Executive Summary

After 5 patches, the root cause hasn't been addressed: **the system uses widget-local mutable state to track a cross-message pipeline, then applies a negative filter to hide things that aren't ready yet.** This is structurally fragile — any state reset (widget rebuild, navigation, disposal) and the filter collapses. The fix is architectural, not another patch.

---

## 1. What the 5 Previous Fixes Did (and Why They Failed)

| Attempt | What it did | Why it's still fragile |
|---------|------------|----------------------|
| Set placeholder `{}` immediately | Closes part of the timing window | Still widget-local — survives only as long as the widget |
| Drop transaction widgets from main response | Prevents Gemini from emitting transaction UI | Removes symptom, not cause — doesn't fix what Gemini THINKS |
| Dedicated `classifyTransaction()` with separate prompt | Isolates classification from conversation | Good architecture, but still feeds results into widget-local map |
| Filter history by `_storedClassifications` keys | Excludes pending messages from LLM context | Correct idea, wrong storage. Widget-local = volatile |
| `_isConfirming` / `_isUndoing` guards | Prevents double-tap | Side concern, unrelated to the leak bug |

**The pattern**: each fix adds a guard, a check, a filter — but never moves the state to the right place.

---

## 2. The Real Architecture Problem (in One Diagram)

```
User sends message
    │
    ▼
_sendMessage()
    ├── chatNotifier.addUserMessage(text)     ← adds to ChatState.messages (global, persistent)
    ├── _storedClassifications[id] = {}         ← widget-local map (VOLATILE)
    │
    ├── Filter history using _storedClassification keys  ← depends on volatile state
    ├── geminiService.sendMessage(filteredHistory)        ← main chat (dual-role prompt!)
    │
    ├── _tryAutoClassify(text)                ← separate Gemini call (correct)
    │       └── returns result or null
    │
    └── _storedClassifications[id] = result   ← writes back to volatile map
            │
            ▼
_confirmTransaction()
    └── reads _storedClassifications[id]       ← depends on volatile map not being cleared
```

**The structural flaw**: ChatState (global, persistent) and `_storedClassifications` (widget-local, volatile) track the same thing in two places, and the critical filter reads from the volatile one.

---

## 3. The Bug Class: What Makes It Possible

The bug class is: **"any async pipeline where intermediate state lives in widget memory and is consumed by a later step."**

The trigger conditions:
1. Widget gets disposed/rebuilt (navigation, rotation, theme change)
2. `initState()` runs → `_storedClassifications = {}` → all tracking lost
3. History filter now sees no entries → ALL user messages pass through
4. Gemini receives prior transaction messages in its conversation context

You cannot "patch" around widget lifecycle — that's fighting the framework. The fix must make the state survive widget lifecycle.

---

## 4. Challenging Each Assumption

### Assumption 1: "We need to send user messages as history to Gemini"

**Challenge**: The current `_buildContents` already only sends user messages, not bot messages (lines 158-163 of `gemini_service.dart`). So Gemini gets:
- Zero bot messages (skipped)
- Only the current user message (because all prior user messages are filtered out)

**The reality**: With the current filter, Gemini effectively gets ZERO conversation history — just the current message. This means the filter has already destroyed conversational context. The question isn't "should we send user messages" — the question is "why are we pretending to send history when we're actually sending none?"

**Recommendation**: Either send real conversation history (bot messages included) or be explicit about single-message context. The current half-state is the worst of both worlds.

### Assumption 2: "_storedClassifications belongs in widget state"

**Challenge**: It's a cross-message tracking structure. The widget's lifecycle is per-build, not per-conversation. This is fundamentally the wrong container.

**Answer**: Classification state MUST live in `ChatProvider` (a `StateNotifier` that survives widget rebuilds) as a field on `ChatMessage` itself.

### Assumption 3: "The dual-role prompt is harmless"

**Challenge**: `_systemPrompt` line 2: `تصنف المعاملات التي يرسلها المستخدم (فئة/فئة فرعية/نبرة: أخضر/رمادي/أحمر).`

This tells Gemini in the MAIN conversation mode that it is a classifier. Even though `_sendMessage` drops transaction widgets from the response (lines 338-340), the LLM's behavior is still shaped by classification instructions. It may:
- Try to classify normal conversation as transactions
- Confuse coaching with classifying
- Produce less natural conversational responses

**This IS a root cause of downstream confusion**, even if not the direct cause of the leak bug. The prompt should describe Azdal as purely a coach. Classification is handled by a completely separate Gemini call with its own prompt.

### Assumption 4: "Classification and conversation must share a pipeline"

**Challenge**: They already DON'T share a pipeline. `classifyTransaction()` uses `_classifySystemPrompt` and sends NO history. `sendMessage()` uses `_systemPrompt` with filtered history. They're already separated at the Gemini level.

The problem is that the RESULTS of classification flow back into the conversation pipeline through a widget-local map, creating the coupling.

**Recommendation**: Complete the separation. Classification results should be written to `ChatMessage` fields in `ChatState`, not to a widget map that the conversation pipeline reads from.

### Assumption 5: "The prompt should say 'you only see the last message'"

**Challenge**: The `_classifySystemPrompt` already receives only a single message — no history is sent. Adding this instruction would be redundant and wouldn't prevent the actual bug (which is about the conversation history, not the classification history).

---

## 5. The Solution: Make This Bug Class IMPOSSIBLE

### Principle: Classification state is message-level, not widget-level. Store it where the message lives.

### Step 1: Add classification fields to `ChatMessage`

```dart
enum ClassificationStatus { none, pending, completed, failed }

final class ChatMessage {
  // ... existing fields ...
  
  /// Whether this user message has been classified.
  /// Bot messages and unprocessed user messages default to [ClassificationStatus.none].
  final ClassificationStatus classificationStatus;
  
  /// The classification result if [classificationStatus] is [ClassificationStatus.completed].
  final Map<String, dynamic>? classificationResult;
  
  // ... updated copyWith ...
}
```

### Step 2: Add classification mutators to `ChatProvider`

```dart
final class ChatProvider extends StateNotifier<ChatState> {
  /// Mark a user message as "classification in progress."
  void beginClassification(String messageId) {
    _updateMessage(messageId, (m) => m.copyWith(
      classificationStatus: ClassificationStatus.pending,
      classificationResult: null,
    ));
  }
  
  /// Store the classification result for a user message.
  void completeClassification(String messageId, Map<String, dynamic>? result) {
    _updateMessage(messageId, (m) => m.copyWith(
      classificationStatus: result != null 
        ? ClassificationStatus.completed 
        : ClassificationStatus.failed,
      classificationResult: result,
    ));
  }
  
  // Helper to update a single message by ID
  void _updateMessage(String messageId, ChatMessage Function(ChatMessage) transform) {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    final updated = [...state.messages];
    updated[index] = transform(updated[index]);
    state = state.copyWith(messages: updated);
  }
}
```

### Step 3: Simplify the history filter

Replace the widget-level filter (lines 300-311 of `chat_screen.dart`) with:

```dart
/// Build conversation context for Gemini.
/// Includes:
///   - All bot messages (Gemini's own responses — context)
///   - User messages that have completed classification (safe for context)
/// Excludes:
///   - User messages still pending classification (could be transactions)
///   - User messages whose classification failed
List<ChatMessage> getConversationContext(ChatState state) {
  return state.messages.where((m) {
    if (m.isBot) return true;
    if (m.isUser) {
      // Only include user messages whose classification is DONE.
      // This is a positive filter ("include completed") rather than
      // a negative filter ("exclude pending"), making the default
      // safe: a newly added message is 'none', not 'completed',
      // so it's automatically excluded.
      return m.classificationStatus == ClassificationStatus.completed;
    }
    return false;
  }).toList();
}
```

**Why this makes the bug impossible**:
- `classificationStatus` defaults to `none` → automatically excluded
- Only `completed` messages pass → no leak window exists
- The state is in `ChatProvider` (global Riverpod `StateNotifier`) → survives widget rebuilds, navigation, disposal
- No separate map to get out of sync → single source of truth
- Positive filter (include) not negative (exclude) → safer default

### Step 4: Fix the dual-role prompt

**Current `_systemPrompt` (flawed)**:
```
أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط.
تصنف المعاملات التي يرسلها المستخدم (فئة/فئة فرعية/نبرة: أخضر/رمادي/أحمر).
عبر عن التصنيف بنص عادي. التطبيق يتولى بناء الأزرار والواجهات بنفسه.
لا تحسب أبداً — الحسابات على Supabase.
إذا احتجت توضيحاً — اسأل. لا تخمن.
```

**Proposed `_systemPrompt` (coach-only)**:
```
أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط.
دورك: مساعدة المستخدم في تتبع وفهم عاداته المالية، وتقديم نصائح مفيدة.
التطبيق يتولى تصنيف المعاملات وحفظها — لا دخل لك بذلك.
لا تحسب أبداً — الحسابات على Supabase.
إذا احتجت توضيحاً — اسأل. لا تخمن.

عند السؤال عن ملخص المصاريف، استخدم summary_card أو bar_chart.
```

Key changes:
- Removed: `تصنف المعاملات` — classification is not your job
- Added: `التطبيق يتولى تصنيف المعاملات وحفظها — لا دخل لك بذلك` — make it explicit
- Added: `دورك: مساعدة المستخدم في تتبع وفهم عاداته المالية` — positive framing of coach role

### Step 5: Move `_tryAutoClassify` to a service (optional, cleaner architecture)

Currently `_tryAutoClassify` is a widget method. It should be either:
- A `ChatProvider` method, or
- A dedicated `ClassificationService`

This removes the widget's responsibility for business logic and makes testing easier.

---

## 6. Why This Fix Is Different From the Previous 5

| Aspect | Previous Fixes | This Fix |
|--------|---------------|----------|
| Where state lives | Widget-local `Map` | `ChatProvider` (global `StateNotifier`) |
| Type of filter | Negative (exclude if in map) | Positive (include if completed) |
| Default behavior | Include everything (leak!) | Exclude everything (safe) |
| Survives widget rebuild | ❌ No | ✅ Yes |
| Survives navigation | ❌ No | ✅ Yes |
| Dual-role prompt | Still instructs Gemini to classify | Purely a coach |
| Source of truth | Two places (messages + map) | One place (message fields) |

---

## 7. The Order of Operations

Based on the user's instruction: "المفترض لها ترتيب معين" (the responses must have a specific order):

1. **First**: Fix `ChatMessage` model — add `classificationStatus` and `classificationResult` fields
2. **Second**: Add mutators to `ChatProvider` — `beginClassification`, `completeClassification`
3. **Third**: Replace the widget filter with `getConversationContext` — positive filter, provider-level
4. **Fourth**: Update `_sendMessage` to use provider methods instead of widget-local map
5. **Fifth**: Fix `_systemPrompt` — remove classification instructions
6. **Sixth**: Update `_confirmTransaction` to read from `ChatMessage.classificationResult` not `_storedClassifications`
7. **Seventh**: Verify: no reference to `_storedClassifications` remains in the codebase

---

## 8. What Was Already Done Right

To be clear — some things ARE already well-designed:

- ✅ `classifyTransaction()` has its own `_classifySystemPrompt` — no dual-role confusion in classification
- ✅ `classifyTransaction()` sends NO history — each classification is isolated
- ✅ Transaction widgets from main chat response are dropped (lines 338-340) — defense in depth
- ✅ The placeholder `{}` pattern was clever — just in the wrong storage location
- ✅ `_isConfirming` guard prevents double-confirm — good UX

These should be preserved. We're moving the state, not throwing out the good patterns.

---

## 9. One More Radical Option: Don't Send User Messages at All

The simplest possible approach: Gemini's conversation context is ONLY bot messages. User messages are never in history. This means:
- Zero chance of transaction text leaking
- Gemini sees its own responses → maintains conversation flow
- Simplest possible code — no filtering needed

The trade-off: Gemini loses the user's exact wording for follow-up questions. But with bot messages as context, it can still maintain conversational coherence.

This is worth considering if the coaching conversations are short and don't require exact recall of prior user messages.
