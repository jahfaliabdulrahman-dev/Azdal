---
version: alpha
name: Azdal (أزدل)
locale: ar-SA
direction: rtl

colors:
  primary: "#001F5E"
  secondary: "#32C2FF"
  surface: "#1B1B1F"
  inputBar: "#161B22"
  onSurface: "#E6E1E5"
  muted: "#8B949E"
  success: "#3FB950"
  warning: "#D29922"
  danger: "#F85149"
  border: "#30363D"
  cardBg: "#161B22"
  input: "#1B1B1F"
  userBubble: "#30363D"
  botBubble: "#001F5E"

typography:
  fontFamily: Cairo
  headline:
    fontSize: 20px
    fontWeight: 700
  body:
    fontSize: 14px
    fontWeight: 400
  caption:
    fontSize: 12px
    fontWeight: 400
  button:
    fontSize: 13px
    fontWeight: 600

rounded:
  bubble: 16px
  card: 16px
  button: 20px
  input: 24px
  circle: 50%

spacing:
  chatPadding: 16px
  bubblePadding: "12px 16px"
  cardPadding: 14px
  inputBarPadding: "10px 16px"
  widgetGap: 12px
---

# Azdal — Design System (Single Screen + Widgets)

## Architecture

**ONE screen only.** The chat interface. No navigation. No tab bars. No screen transitions.

Everything else (cards, charts, buttons, forms) are **widgets embedded inline in the chat flow.** The AI agent generates them via JSON schema from a fixed widget catalog.

## Screen Structure

```
┌─────────────────────────────┐
│ Status Bar                  │
│  🜔  أزدل                  │  ← fixed header
├─────────────────────────────┤
│                             │
│  [chat messages scroll]     │  ← scrollable
│  [bot messages]            │
│  [embedded widgets]        │
│  [cards, charts, buttons]  │
│                             │
├─────────────────────────────┤
│ 📷 │  اكتب مصروف...    │ ↑ │  ← input bar (always visible)
└─────────────────────────────┘
```

## Input Bar (Fixed)

Three elements, always at the bottom:
1. **Camera button** `📷` — opens camera or gallery. Also accepts images shared via system share sheet.
2. **Text input** — rounded, placeholder: "اكتب مصروف... أو اسأل سؤال"
3. **Send button** `↑` — cyan circle, sends message

## Widget Catalog (6 Widgets)

All widgets are rendered inline inside bot message bubbles. The agent sends JSON, Flutter renders from catalog.

### 1. `summary_card`
Card with rows of label/value pairs. Supports tones: success (green), warning (yellow), danger (red).

### 2. `bar_chart`
Horizontal bar chart for category comparisons. Each bar has value label on top, category label below.

### 3. `action_buttons`
Row of rounded pill buttons. Selection sends event back to agent.

### 4. `quick_input_form`
Inline form with 1-2 fields. Submit sends data back to agent.

### 5. `goal_progress_card`
Card with progress bar, percentage, monthly amount, status indicator.

### 6. `compound_split_card`
Split transaction card with +/- adjusters per category line. Total verification row.

## Image Input — Two Methods

### Method A: Camera button (in-app)
User taps `📷` → camera or gallery → image sent to Gemini Vision OCR

### Method B: System Share Sheet (from outside)
User is in Gallery/Bank app → taps Share → selects "Azdal" → app opens directly to chat with OCR processing

```dart
// Flutter: receive_sharing_intent package
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void initShareHandler() {
  ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> files) {
    final image = files.first.path;
    processReceiptOCR(image);
  });
}
```

```xml
<!-- Android: AndroidManifest.xml intent filter -->
<activity android:name=".ReceiptShareActivity">
    <intent-filter>
        <action android:name="android.intent.action.SEND" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="image/*" />
    </intent-filter>
</activity>
```

## States

### Empty State (First Use)
- Logo 🜔 centered
- Headline: "أهلاً بك في أزدل"
- Subtitle: brief explanation
- No messages yet
- Input bar visible

### Active State
- Chat messages scrollable
- Widgets embedded in bot messages
- Input bar always visible

## Do's
- ✅ Single chat screen only
- ✅ Widgets inline in chat flow
- ✅ Camera button + share sheet integration
- ✅ Dark mode only
- ✅ Cairo font exclusively
- ✅ Western numerals (1,2,3)
- ✅ RTL layout
- ✅ Guest-first: no login

## Don'ts
- ❌ No separate screens for reports, goals, etc.
- ❌ No tab bars or navigation
- ❌ No light mode
- ❌ No Eastern Arabic numerals
- ❌ No registration wall
- ❌ No decorative illustrations
