# Azdal — User Flows & Navigation

> **Status:** Locked  
> **Source:** Synthesized from `docs/design/design-system-original.md`

---

## Core Architecture Decision

**ONE screen only.** The chat interface. No navigation. No tab bars. No screen transitions.

Everything (cards, charts, buttons, forms) are **widgets embedded inline in the chat flow.** The AI agent generates them via JSON schema from a fixed widget catalog.

---

## Screen Structure

```
┌─────────────────────────────┐
│ Status Bar                  │
│  🜔  أزدل                  │  ← fixed header (36px)
├─────────────────────────────┤
│                             │
│  [chat messages scroll]     │  ← scrollable ListView
│  [bot messages]            │
│  [embedded widgets]        │
│  [cards, charts, buttons]  │
│                             │
├─────────────────────────────┤
│ ↑ │  اكتب مصروف...    │ 🎤 📷 │  ← input bar (fixed, 56px)
└─────────────────────────────┘
```

---

## Input Bar (Fixed, Always Visible)

| Element | Position | Behavior |
|---------|----------|----------|
| Camera button `📷` | Start (RTL: right) | Opens camera or gallery. Accepts share sheet images. |
| Mic button `🎤` | Start-adjacent (RTL: right, next to camera) | Activates voice input via `speech_to_text`. One-tap to start recording, tap again to stop. Primary input method for Arabic users. |
| Text input | Center (flex) | Placeholder: "اكتب مصروف... أو اسأل سؤال". Rounded 24px. |
| Send button `↑` | End (RTL: left) | Cyan circle. Sends text, transcribed voice, and/or image to AI. |

---

## Widget Catalog (6 Widgets)

All widgets rendered inline inside bot message bubbles. AI sends JSON → Flutter renders from catalog.

### 1. `summary_card`
Card with rows of label/value pairs. Tones: success (green), warning (yellow), danger (red).

```json
{
  "widget": "summary_card",
  "title": "ملخص مصاريفك — يوليو",
  "rows": [
    {"label": "المجموع", "value": "3,450 ريال", "tone": "neutral"},
    {"label": "مقارنة بالشهر الماضي", "value": "▼ 12%", "tone": "success"}
  ]
}
```

### 2. `bar_chart`
Horizontal bar chart for category comparisons.

```json
{
  "widget": "bar_chart",
  "title": "أين تذهب مصاريفك؟",
  "bars": [
    {"label": "مطاعم", "value": 1200, "max": 3500, "color": "warning"},
    {"label": "مقاضي", "value": 800, "max": 3500, "color": "neutral"}
  ]
}
```

### 3. `action_buttons`
Row of rounded pill buttons. Selection sends event back to AI.

```json
{
  "widget": "action_buttons",
  "question": "هل هذه العملية تعليمية أم ترفيهية؟",
  "buttons": [
    {"label": "دورة تدريبية", "value": "education", "type": "primary"},
    {"label": "ترفيه", "value": "entertainment", "type": "secondary"}
  ]
}
```

### 4. `quick_input_form`
Inline form with 1-2 fields. Submit sends data to AI.

```json
{
  "widget": "quick_input_form",
  "title": "سجل هدف ادخار",
  "fields": [
    {"label": "اسم الهدف", "placeholder": "مثلاً: طارئ", "key": "name"},
    {"label": "المبلغ", "placeholder": "5,000 ريال", "key": "amount", "type": "number"}
  ],
  "submit_label": "ابدأ الادخار"
}
```

### 5. `goal_progress_card`
Card with progress bar, percentage, monthly amount.

```json
{
  "widget": "goal_progress_card",
  "goal_name": "صندوق الطوارئ",
  "current": 1250,
  "target": 5000,
  "monthly_saving": 500,
  "months_remaining": 8
}
```

### 6. `compound_split_card`
Split transaction card with +/- adjusters per category.

```json
{
  "widget": "compound_split_card",
  "total": 475,
  "splits": [
    {"category": "مقهى", "amount": 150, "max": 475},
    {"category": "خضار وفواكه", "amount": 175, "max": 475},
    {"category": "مطعم", "amount": 150, "max": 475}
  ]
}
```

---

## Image Input — Two Methods

### Method A: Camera Button (In-App)
1. User taps `📷`
2. Camera or gallery picker opens
3. Image sent to Gemini Vision OCR
4. OCR result appears as bot message
5. User confirms/edits via compound split card

### Method B: System Share Sheet
1. User in Gallery/Bank app
2. Taps Share → selects "Azdal"
3. App opens directly to chat
4. Image processed via Gemini Vision OCR
5. Flutter: `receive_sharing_intent` package

---

## States

### Empty State (First Use)
- Logo 🜔 centered
- Headline: "أهلاً بك في أزدل"
- Subtitle: "مساعدك المالي الذكي. بدون تعب. بدون إدخال بيانات."
- No messages yet
- Input bar visible with placeholder: "اكتب أول مصروف... أو صور الفاتورة"

### Active State
- Chat messages scrollable
- Widgets embedded in bot messages
- Input bar always visible
- Typing indicator when AI is processing

### Cold Start State
- "صباح الخير! عشان أقدر أساعدك — ٣ أسئلة بس:"
- Quick input form widget for: income, major commitments, approximate monthly spend
- Instant insight displayed after submission

### OCR State 1 — Uploading / Processing
**Trigger:** User captures photo via camera button or share sheet.
**Visual:** Image thumbnail displayed with processing overlay — NOT a full-screen spinner.

```
┌─────────────────────────────┐
│                             │
│  ┌─────────────────────┐   │
│  │                     │   │
│  │   [image thumbnail] │   │  ← Card White #FFFFFF, 16px radius
│  │                     │   │
│  │  ⬤◉⬤  جاري تحليل    │   │  ← Navy semi-transparent overlay
│  │      الإيصال...     │   │     (Navy #001F5E at 70% opacity)
│  │                     │   │     3 animated dots (Cyan #32C2FF, pulse)
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Thumbnail container | Card White `#FFFFFF`, border-radius 16px, subtle shadow |
| Overlay BG | Navy `#001F5E` at 70% opacity, covers bottom 30% of image |
| Processing text | Arabic: "جاري تحليل الإيصال…" — Body 14px, Card White `#FFFFFF` |
| Dots animation | 3 dots, Cyan `#32C2FF`, pulse 800ms stagger — reuses typing indicator pattern |
| Dismissible | No — auto-transitions to next state |
| Timeout | After 10s, transitions to State 3 (failure) |

**Behavior:**
- Thumbnail appears as a user message bubble (Light Navy Tint `#E3E8F5` BG) with the image inside
- Processing overlay slides up from bottom of thumbnail (300ms ease-out)
- AI response arrives as a bot message when processing completes → transitions to compound_split_card (State 2) or failure message (State 3)

---

### OCR State 2 — Low-Confidence / Partial Extraction
**Trigger:** Gemini Vision extracted SOME items successfully but flagged others as uncertain (e.g., smudged text, ambiguous amounts).
**Visual:** compound_split_card widget variant — confirmed items editable + uncertain items highlighted with manual entry fields.

```
┌───────────────────────────────────┐
│  📄 تحليل الإيصال               │  ← Title 18px Bold
│                                   │
│  ┌─ Confirmed ────────────────┐  │
│  │ 🍽️ مطعم          150  ✓  │  │  ← Normal rows, Success green check
│  │ 🛒 مقاضي          200  ✓  │  │     Editable — tap to modify
│  └─────────────────────────────┘  │
│                                   │
│  ┌─ Uncertain ⚠️ ─────────────┐  │  ← Amber #B7791F left border
│  │ ??? _______________ [✓]   │  │  ← Manual entry field, dotted placeholder
│  │     اكتب المبلغ             │  │     Caption 12px Muted below field
│  │ ??? _______________ [✓]   │  │
│  │     اكتب المبلغ             │  │
│  └─────────────────────────────┘  │
│                                   │
│  المجموع: 350 + ?? ريال         │  ← Partial total, Muted `#6B7280`
│                                   │
│  [ تأكيد الكل ✓ ]               │  ← Primary button, Cyan fill
└───────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Card container | Card White `#FFFFFF`, 16px radius, border `#E1E4E8` |
| Title | "تحليل الإيصال" — Title 18px Bold, On Surface `#1B1B1F` |
| Confirmed section header | Caption 12px SemiBold, Success `#2E7D32` |
| Confirmed rows | Body 14px, editable (tap to modify), ✓ checkmark in Success green |
| Uncertain section header | Caption 12px SemiBold, Warning `#B7791F`, ⚠️ icon |
| Uncertain left border | 3px solid Amber `#B7791F` on the section card |
| Uncertain row field | Input 24px pill, Border Gray `#E1E4E8`, placeholder "???", fills with user entry |
| Hint text | Caption 12px, Muted `#6B7280`: "اكتب المبلغ" |
| Confirm button | Pill button, Cyan `#32C2FF` fill, Button 13px SemiBold: "تأكيد الكل ✓" |
| Partial total | Body 14px, Muted `#6B7280`: "المجموع: 350 + ?? ريال" |

**Behavior:**
- Confirmed items can be tapped to edit (inline TextField replaces row value)
- Uncertain rows: each has a number-pad input field. User fills missing amounts → ✓ appears green
- "تأكيد الكل" button disabled (Muted, 40% opacity) until all uncertain fields are filled
- On confirm → AI processes the completed data → summary_card confirmation bot message

---

### OCR State 3 — "Couldn't Read" Failure Fallback
**Trigger:** Photo too blurry, not a receipt, or Gemini returned zero usable data after timeout.
**Visual:** Error message bubble in chat + inline quick_input_form for manual entry. Implements PRD Cold Start Intelligence principle — never say "no data."

```
┌───────────────────────────────────┐
│                                   │
│  ⚠️ لم أستطع قراءة الإيصال      │  ← Bot bubble, Danger Red #D32F2F icon
│     الصورة مش واضحة أو مو فاتورة │     Body 14px, On Surface #1B1B1F
│                                   │
│  ┌─────────────────────────────┐  │
│  │ أدخل المبلغ يدوياً:        │  │  ← quick_input_form widget
│  │                             │  │     Card White #FFFFFF, 16px radius
│  │ المبلغ                       │  │
│  │ [  ____________ ]  ريال    │  │  ← Number input, 24px pill
│  │                             │  │
│  │ التصنيف                      │  │
│  │ [  ____________ ]          │  │  ← Text input, optional
│  │                             │  │
│  │ [ سجل العملية ✓ ]          │  │  ← Primary button, Cyan fill
│  └─────────────────────────────┘  │
│                                   │
└───────────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Error bubble | Bot bubble (Navy `#001F5E` BG), 16px radius, Danger Red `#D32F2F` ⚠️ icon |
| Error title | "لم أستطع قراءة الإيصال" — Body 14px Bold, On Surface text |
| Error subtitle | "الصورة مش واضحة أو مو فاتورة" — Body 14px Regular, Muted `#6B7280` |
| Form container | Card White `#FFFFFF`, 16px radius, border `#E1E4E8` — reuses quick_input_form widget |
| Form title | "أدخل المبلغ يدوياً:" — Title 18px Bold, On Surface `#1B1B1F` |
| Amount field | Number input, 24px pill, key: `amount`, required, keyboard type: number |
| Category field | Text input, 24px pill, key: `category`, optional, placeholder: "مطاعم، مقاضي…" |
| Submit button | "سجل العملية ✓" — Pill 20px, Cyan `#32C2FF` fill, Button 13px SemiBold |
| Submit disabled | Until amount field is non-empty |

**Behavior:**
- Error bubble appears as bot message with Danger Red ⚠️ icon
- quick_input_form rendered inline below — user NEVER hits a dead end
- User fills amount → taps "سجل العملية" → AI processes → confirms with standard transaction confirmation: "تم تسجيل ١٥٠ ريال — عشاء 🍽️"
- User can also tap 📷 to retake photo — error bubble remains visible as context
- Fallback form always available even if retake succeeds — user can switch between OCR and manual

---

## Flow: "Can I Buy?" Purchase Decision

```
User: "أبي أشتري جوال بـ ٣٠٠٠"
  ↓
AI extracts: item, amount, implicit goal
  ↓
AI calculates: income - commitments - current spend - days to salary - active goals
  ↓
AI returns verdict widget:
  YES ✅ → "تقدر! باقي لك 2,000 فائض هذا الشهر."
  WAIT ⚠️ → "إذا أجلت 15 يوم → توفر 500 ريال."
  NO ❌ → "عندك هدف ادخار 5,000. إذا اشتريت → يتأخر 8 أشهر."
  ↓
User confirms or changes decision
```

---

## Flow: Transaction Entry

```
User taps camera or types text
  ↓
Voice: "سجل 150 ريال عشاء"
OCR: Photo of receipt processed
Text: "150 عشاء"  ← a bare number + spending-context word defaults to SAR;
                     writing "ريال" explicitly is optional, not required (DEC-021)
  ↓
Gemini classifies AND writes the transaction directly — no confirm tap
for a single, clear item (DEC-021: auto-save simple transactions):
  - Category: مطاعم
  - Subcategory: عشاء
  - Amount: 150 SAR
  - Tone: Green (routine)
  ↓
Transaction saved. Bot confirms in ONE message:
  "تم تسجيل 150 ريال — عشاء 🍽️"  +  [↩️ تراجع]
  ↓
(only if the message has MULTIPLE items in one turn, e.g. a receipt or
"150 مقهى + 175 خضار": Gemini extracts the split → bot shows
compound_split_card with adjustable amounts → user taps
❌ إلغاء or ✅ تأكيد → only then is anything written)
  ↓
Evening check-in: "عندك 3 عمليات تحتاج تصنيفها."  ← Future (not in MVP) —
  no scheduling/batch-classification exists in the code today.
```

---

## Flow: Integrity Score Reveal

```
User asks: "كيف أدائي؟" or weekly auto-report triggers
  ↓
AI calculates Integrity Score from 5 factors
  ↓
Bot displays summary_card widget:
  - Current score: 78/100 (Good)
  - Logging consistency: 22/30 days
  - Receipt upload rate: 8/12 flagged
  - Data accuracy: 92% match
  ↓
Bot: "أداءك جيد! لو صورت 4 فواتير إضافية — توصل 85."
```

---

## Navigation Rules

| Rule | Details |
|------|---------|
| NO tabs | Single screen — chat only |
| NO drawer | No hamburger menu |
| NO bottom nav | Chat input bar IS the bottom |
| RTL only | All Arabic text RTL-aligned |
| Back button | Android — exit confirmation. iOS — swipe back. |

---

## Related
- `04_ui_design_system.md` — Design tokens and visual specs
- `01_prd.md` — Complete product requirements
- `07_flutter_architecture.md` — GenUI/A2UI implementation
