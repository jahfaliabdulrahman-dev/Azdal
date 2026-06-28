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
│ 📷 │  اكتب مصروف...    │ ↑ │  ← input bar (fixed, 56px)
└─────────────────────────────┘
```

---

## Input Bar (Fixed, Always Visible)

| Element | Position | Behavior |
|---------|----------|----------|
| Camera button `📷` | Start (RTL: right) | Opens camera or gallery. Accepts share sheet images. |
| Text input | Center (flex) | Placeholder: "اكتب مصروف... أو اسأل سؤال". Rounded 24px. |
| Send button `↑` | End (RTL: left) | Cyan circle. Sends text and/or image to AI. |

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
Voice: "سجل ١٥٠ ريال عشاء"
OCR: Photo of receipt processed
Text: "150 عشاء"
  ↓
Gemini Flash classifies and enriches:
  - Category: مطاعم
  - Subcategory: عشاء
  - Amount: 150 SAR
  - Tone: Green (routine)
  ↓
Bot confirms: "تم تسجيل ١٥٠ ريال — عشاء 🍽️"
  ↓
Evening check-in: "عندك 3 عمليات تحتاج تصنيفها."
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
