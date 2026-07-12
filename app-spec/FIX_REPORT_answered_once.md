# Fix Report — Widget "Answered Once" Pattern

> **Type:** Correctness fix — proven duplicate-save risk  
> **Scope:** `action_buttons` + `compound_split_card` widgets  
> **Excluded:** `↩️ تراجع` undo button (already self-consuming via `removeMessage`)  
> **Commit:** _pending verification_

---

## Root Cause

Once a message's `action_buttons` or `compound_split_card` widget renders, it stays **fully interactive forever**, even after its action has already been handled.

**Proven live:** Cancelling a `compound_split_card` via "❌ إلغاء" left the same "✅ تأكيد" button still tappable — re-tapping it would attempt the save it was just cancelled to avoid.

The root cause is that the widget JSON on the `ChatMessage` never records that an action was taken. Each tap dispatches a fresh action to `_handleWidgetAction`. Guard booleans like `_isConfirming` protect against concurrent double-taps (milliseconds apart), but do nothing for a second tap minutes later on the same now-orphaned widget.

The `↩️ تراجع` undo button already solved this correctly via `removeMessage` + replacement — the button physically disappears after use. But confirm/edit/cancel buttons on normal messages don't self-destruct and shouldn't — the user should still see what they tapped, just not be able to re-trigger it.

---

## Design

### Data Flow

```
User taps button
       │
       ▼
widget_catalog.dart dispatches:
  { action, widget, value, label, ...}
       │
_MessageBubble injects message_id ──┐
       │                            │
       ▼                            ▼
_handleWidgetAction receives:
  { action, widget, value, label, ..., message_id }
       │
       ▼
chatNotifier.markWidgetAnswered(msgId, value)   ← BEFORE any async work
       │
       │  merges { _answered: true, _selectedValue: <value> }
       │  into ChatMessage.widget map in-place via state.copyWith
       │
       ▼
Riverpod pushes updated ChatState
       │
       ▼
widget_catalog.dart rebuilds:
  - reads json['_answered'] == true
  - all buttons → onPressed: null (genuinely non-interactive)
  - container → Opacity(0.55)
  - selected button → highlighted (filled _cyan / _success background)
```

### Key design decisions

1. **Mark first, work later.** `markWidgetAnswered` is called synchronously BEFORE any `await` — the widget visibly dims and disables instantly, before the network call even begins. If the network call fails, the widget stays answered (the user already made their choice).

2. **message_id injection at the edge.** `_MessageBubble` wraps `onAction` to inject `message_id` into every payload — no widget needs to know about or forward message ids. Single change, covers all widget types in perpetuity.

3. **Widget map, not new field.** The answered state lives in the existing `widget` map (`_answered`, `_selectedValue`) rather than a new `ChatMessage` field. This avoids schema changes and keeps the pattern contained to widgets that already read from `json`.

4. **Undo untouched.** The `↩️ تراجع` button already self-consumes via `removeMessage` → `addBotMessage('تم التراجع ✅')`. It bypasses `markWidgetAnswered` entirely because the message is physically replaced, not marked.

---

## File-by-File Changes

### 1. `lib/features/chat/providers/chat_provider.dart`

**Added: `markWidgetAnswered(String messageId, String selectedValue)`**

```dart
void markWidgetAnswered(String messageId, String selectedValue) {
  final index = state.messages.indexWhere((m) => m.id == messageId);
  if (index == -1) return;
  final message = state.messages[index];
  final updatedWidget = <String, dynamic>{
    ...?message.widget,
    '_answered': true,
    '_selectedValue': selectedValue,
  };
  final updated = <ChatMessage>[...state.messages];
  updated[index] = message.copyWith(widget: updatedWidget);
  state = state.copyWith(messages: updated);
}
```

Finds the message by id, merges `_answered` + `_selectedValue` into its widget map, replaces it in the immutable list via `copyWith`. Triggers a Riverpod state update — all watchers rebuild.

### 2. `lib/features/chat/chat_screen.dart`

**Changed: `_MessageBubble.build()` — inject `message_id`**

```dart
// Before:
renderCatalogWidget(message.widget!, onAction: onWidgetAction);

// After:
renderCatalogWidget(
  message.widget!,
  onAction: onWidgetAction != null
      ? (action) => onWidgetAction!({
          ...action,
          'message_id': message.id,
        })
      : null,
);
```

Every action dispatched from any widget now carries the originating message's id. No widget code modified — the injection happens at the `_MessageBubble` level.

**Changed: `_handleWidgetAction()` — `action_buttons` case**

```dart
case 'action_buttons':
  final value = action['value'] as String?;
  final msgId = action['message_id'] as String?;
  if (value == null || msgId == null) break;
  if (_isConfirming) break;

  // Mark consumed FIRST — before any async work.
  chatNotifier.markWidgetAnswered(msgId, value);

  if (value == 'confirm') { ... }
  else if (value == 'edit') { ... }
  else if (value == 'undo_transaction') { ... }
```

`markWidgetAnswered` is called synchronously before `await _confirmTransaction` or any other async handler. The widget dims instantly.

**Changed: `_handleWidgetAction()` — `compound_split_card` case**

```dart
case 'compound_split_card':
  final msgId = action['message_id'] as String?;
  if (msgId == null) break;

  if (actionType == 'compound_split_cancel') {
    chatNotifier.markWidgetAnswered(msgId, 'compound_split_cancel');
    chatNotifier.addBotMessage('تم الإلغاء.');
    break;
  }

  chatNotifier.markWidgetAnswered(msgId, 'compound_split_confirm');
  await _handleCompoundSplit(action, chatNotifier);
```

Both cancel and confirm paths mark the widget before proceeding. If cancelled, no further action is possible. If confirmed, the card stays visible but inert with the confirm button highlighted.

### 3. `lib/features/chat/widgets/widget_catalog.dart`

**Changed: `_ActionButtonsWidget.build()`**

```dart
final answered = json['_answered'] == true;
final selectedValue = json['_selectedValue'] as String?;
```

When `answered` is true:
- Container wrapped in `Opacity(opacity: 0.55)`
- Every button: `onPressed: null` (non-interactive)
- The button matching `_selectedValue`: `backgroundColor: _cyan` + `foregroundColor: _navy` (filled/selected style)
- Non-selected buttons: retain their normal inactive style

**Changed: `_CompoundSplitCardWidgetState.build()`**

```dart
final answered = widget.json['_answered'] == true;
final selectedValue = widget.json['_selectedValue'] as String?;
final isCancelled = answered && selectedValue == 'compound_split_cancel';
final isConfirmed = answered && selectedValue == 'compound_split_confirm';
```

When `answered` is true:
- Container wrapped in `Opacity(opacity: 0.55)`
- Cancel button: `onPressed: null` unless it was the selected action (in which case it stays highlighted)
- Confirm button: `onPressed: null` unless it was the selected action; changes to `backgroundColor: _success` (green) when confirmed
- All non-selected buttons are inert

---

## Supported Action Types

| Widget | Action | `_selectedValue` | Highlight |
|--------|--------|-----------------|-----------|
| `action_buttons` | `confirm` | `"confirm"` | Primary button filled cyan |
| `action_buttons` | `edit` | `"edit"` | Secondary button filled cyan |
| `compound_split_card` | `compound_split_cancel` | `"compound_split_cancel"` | Cancel button remains active-style |
| `compound_split_card` | `compound_split_confirm` | `"compound_split_confirm"` | Confirm button turns green |

`undo_transaction` is NOT handled by this pattern — it uses `removeMessage` + `addBotMessage` to physically replace the widget.

---

## Edge Cases Covered

1. **Double-tap within milliseconds:** `_isConfirming` guard still active for concurrent taps. `markWidgetAnswered` makes the button inert regardless.

2. **Tap, wait, tap again minutes later:** Widget shows `_answered: true` → `onPressed: null`. Second tap impossible.

3. **Scroll away and back:** `_answered` persists in `ChatMessage.widget` → Riverpod rebuilds with the same state → buttons remain disabled.

4. **Network failure after mark:** Widget stays answered. If the user needs to retry, the `ErrorBubble` provides a retry path — the answered buttons don't re-activate.

5. **Undo after confirm:** Undo uses `removeMessage` to physically delete the answered message. No stale answered state to worry about.

---

## What Was NOT Changed

- `↩️ تراجع` undo button: already self-consuming via `removeMessage`, correctly pathed through `_undoTransaction`, no change needed.
- `quick_input_form`: not an action_buttons/compound_split_card widget, no duplicate-tap risk in its current usage.
- `ocr_failure` / `ocr_processing`: not affected by this pattern.
- `ChatMessage` model: no new fields added — `_answered`/`_selectedValue` live in the existing `widget` map.

---

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `flutter test` | 16/16 pass |
| `flutter build apk --release` | 58.7MB, successful |

### DoD Items (real device)
- [ ] Tap "✅ صحيح" — both buttons immediately dim/disable, selected one highlighted
- [ ] Tap disabled buttons — nothing happens, no crash, no duplicate save
- [ ] Cancel compound split — "تأكيد" becomes inert
- [ ] Scroll to old answered message — stays answered (not reset by rebuild)
