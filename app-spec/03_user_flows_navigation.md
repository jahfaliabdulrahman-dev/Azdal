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
AI returns verdict widget (one of 4 states — see §Verdict Widget States below):
  YES ✅ → "تقدر! باقي لك X فائض هذا الشهر." (X Dart-computed)
  WAIT ⚠️ → "إذا أجلت 15 يوم → توفر X ريال." (X Dart-computed)
  NO ❌ → "نسبة التزاماتك X% من دخلك — أعلى من الحد الآمن." (X Dart-computed)
  need-info ❓ → يسأل سؤالاً توضيحياً واحداً (مثلاً: الدخل غير معروف)
  User confirms, defers, or provides requested info
  ```


  ---

  ## Verdict Widget States — "Can I Buy?" تصميم حالات

  كل حالة من الحالات الأربع تستخدم **فقط** المكوّنات الموجودة في كتالوج الـ 6 Widgets (DEC-006). الأرقام تُحسب Dart-side، والنص العربي `reply` فقط هو من إخراج LLM (DEC-022: BRP).

  ### 1. YES ✅ — الشراء ممكن

  | الخاصية | القيمة |
  |----------|-------|
  | **المكوّنات** | `summary_card` + `action_buttons` |
  | **اللون** | Success Green `#2E7D32` — left border tone |
  | **المحتوى** | صفوف Summary تعرض: الدخل، الالتزامات، المصروف الحالي، الفائض |
  | **النص** | "تقدر! باقي لك X ريال." — `X` = الدخل − الالتزامات − المصروف (Dart-computed) |
  | **الأزرار** | زر واحد: `[تسجيل العملية ✓]` — Primary Cyan fill |

  ```json
  {
    "widget": "summary_card",
    "title": "نتيجة التحليل — شراء جوال",
    "tone": "success",
    "rows": [
      {"label": "الدخل الشهري", "value": "8,000 ريال", "tone": "neutral"},
      {"label": "الالتزامات", "value": "2,500 ريال", "tone": "neutral"},
      {"label": "المصروف هذا الشهر", "value": "2,300 ريال", "tone": "neutral"},
      {"label": "المبلغ المطلوب", "value": "3,000 ريال", "tone": "neutral"},
      {"label": "الفائض المتاح", "value": "3,200 ريال", "tone": "success"}
    ]
  }
  ```
  ```json
  {
    "widget": "action_buttons",
    "question": "تقدر تشتري! تبي نسجل العملية؟",
    "buttons": [
      {"label": "تسجيل العملية ✓", "value": "confirm_purchase", "type": "primary"}
    ]
  }
  ```

  **قاعدة الحساب (Dart-side):**
  ```
  remaining = income − commitments − current_month_spend − purchase_amount;
  verdict = (remaining >= 0) ? YES : …
  reply = "تقدر! باقي لك {remaining} ريال."
  ```

  ---

  ### 2. WAIT ⚠️ — تعارض مع هدف

  | الخاصية | القيمة |
  |----------|-------|
  | **المكوّنات** | `summary_card` + `action_buttons` |
  | **اللون** | Warning Amber `#B7791F` — left border tone |
  | **المحتوى** | صفوف Summary تعرض: الفائض، الأهداف النشطة، تأثير الشراء |
  | **النص** | "إذا أجلت X يوم → توفر Y ريال." — `X` و `Y` Dart-computed |
  | **الأزرار** | زران: `[تأجيل]` (Outlined) + `[شراء الآن]` (Primary) |

  ```json
  {
    "widget": "summary_card",
    "title": "انتبه — هدفك قريب!",
    "tone": "warning",
    "rows": [
      {"label": "الفائض هذا الشهر", "value": "1,200 ريال", "tone": "neutral"},
      {"label": "هدفك النشط: طارئ", "value": "4,200 / 5,000 ريال", "tone": "neutral"},
      {"label": "إذا اشتريت الآن", "value": "الهدف يتأخر 45 يوم", "tone": "warning"},
      {"label": "إذا أجلت 15 يوم", "value": "توفر 800 ريال", "tone": "success"}
    ]
  }
  ```
  ```json
  {
    "widget": "action_buttons",
    "question": "وش تبي تسوي؟",
    "buttons": [
      {"label": "تأجيل", "value": "defer", "type": "secondary"},
      {"label": "شراء الآن", "value": "buy_now", "type": "primary"}
    ]
  }
  ```

  **قاعدة الحساب (Dart-side):**
  ```
  savings_needed = active_goal.target − active_goal.current;
  days_delay = ceil(savings_needed / daily_surplus);
  savings_in_15_days = min(daily_surplus * 15, savings_needed);
  reply = "إذا أجلت 15 يوم → توفر {savings_in_15_days} ريال.";
  ```

  ---

  ### 3. NO ❌ — تجاوز حد الالتزامات الآمن

  | الخاصية | القيمة |
  |----------|-------|
  | **المكوّنات** | `summary_card` فقط (بدون أزرار — إعلامي) |
  | **اللون** | Danger Red `#D32F2F` — left border tone |
  | **المحتوى** | صفوف Summary تعرض: نسبة الالتزامات، الحد الآمن، التوصية |
  | **النص** | "نسبة التزاماتك X% من دخلك — أعلى من الحد الآمن (33%)." — `X` Dart-computed |

  ```json
  {
    "widget": "summary_card",
    "title": "الأفضل ما تشتري الآن",
    "tone": "danger",
    "rows": [
      {"label": "نسبة الالتزامات", "value": "X% من الدخل", "tone": "danger"},
      {"label": "الحد الآمن", "value": "33% من الدخل", "tone": "neutral"},
      {"label": "التوصية", "value": "انتظر حتى تنخفض التزاماتك", "tone": "danger"}
    ]
  }
  ```

  **قاعدة الحساب (Dart-side):**
  ```
  dti_ratio = (commitments / income) * 100;
  if (dti_ratio > 33) → verdict = NO;
  reply = "نسبة التزاماتك {dti_ratio}% من دخلك — أعلى من الحد الآمن.";
  ```

  ---

  ### 4. need-info ❓ — معلومات ناقصة

  | الخاصية | القيمة |
  |----------|-------|
  | **المكوّنات** | `quick_input_form` (حقل واحد فقط) |
  | **اللون** | Neutral (بدون tone خاص — هذه حالة وسيطة) |
  | **المحتوى** | نموذج بحقل واحد يسأل عن المعلومة الناقصة |
  | **النص** | "كم دخلك الشهري التقريبي؟" — المكان الوحيد الذي يظهر فيه السؤال نصاً من LLM |

  ```json
  {
    "widget": "quick_input_form",
    "title": "معلومة ناقصة",
    "_form_kind": "buy_verdict_clarification",
    "fields": [
      {"label": "الدخل الشهري التقريبي", "placeholder": "مثلاً: 8,000", "key": "income", "type": "number", "required": true}
    ],
    "submit_label": "احسب →"
  }
  ```

  **متى تُستخدم هذه الحالة:**
  - الدخل غير معروف (لم يمر Cold Start بعد)
  - المستخدم لم يجب على أسئلة Phase 0
  - أي مُدخل أساسي ناقص يمنع الحساب الدقيق

  **السلوك بعد الإرسال:** يُعاد تشغيل محرك الحساب كاملاً بالقيمة الجديدة → ينتقل إلى YES/WAIT/NO.

  ---

  ## Integrity Score Display — عرض نقاط النزاهة

  يُعرض داخل `summary_card`. **3 عوامل حقيقية** + **2 مقفلة** حتى الربط البنكي (DEC-025).

  ### التصميم

  | الصف | المصدر | الحالة |
  |------|--------|--------|
  | **النتيجة الكلية (0-100)** | `Dart: weightedAverage(3 active factors)` | كبير، Bold 20px، في رأس الكارد |
  | **تناسق التسجيل** | `Dart: loggedDays / totalDays` | نشط — يعرض النسبة |
  | **معدل رفع الإيصالات** | `Dart: receiptsUploaded / flaggedTransactions` | نشط — يعرض النسبة |
  | **معدل عدم الحذف** | `Dart: 1 − (deletedCount / totalCount)` | نشط — يعرض النسبة |
  | **دقة مطابقة البيانات** | مقفل | رمادي 🔒، "قادم مع الربط البنكي" |
  | **سرعة الاستجابة** | مقفل | رمادي 🔒، "قادم مع الربط البنكي" |

  ### JSON Schema

  ```json
  {
    "widget": "summary_card",
    "title": "نقاط نزاهتك — يوليو",
    "tone": "neutral",
    "rows": [
      {"label": "النتيجة", "value": "78 / 100", "tone": "success", "style": "large"},
      {"label": "تناسق التسجيل", "value": "22 / 30 يوم (73%)", "tone": "neutral"},
      {"label": "معدل رفع الإيصالات", "value": "8 / 12 عملية (67%)", "tone": "neutral"},
      {"label": "معدل عدم الحذف", "value": "95%", "tone": "neutral"},
      {"label": "دقة مطابقة البيانات", "value": "قادم مع الربط البنكي 🔒", "tone": "muted"},
      {"label": "سرعة الاستجابة", "value": "قادم مع الربط البنكي 🔒", "tone": "muted"}
    ]
  }
  ```

  ### قواعد القفل البصري

  | الخاصية | القيمة |
  |----------|-------|
  | **لون النص** | Muted `#6B7280` |
  | **الأيقونة** | 🔒 قفل (system emoji) |
  | **النص** | "قادم مع الربط البنكي" — ثابت، غير متغير |
  | **الشفافية** | 60% opacity على الصف بالكامل |
  | **التفاعل** | غير قابل للنقر (non-interactive) |

  ### الحساب (Dart-side)

  ```
  active_factors = {
    logging_consistency: (loggedDays / totalDays) * 100,    // وزن 30% → 50% بعد إعادة التوزيع
    receipt_upload_rate: (receiptsUploaded / flagged) * 100,  // وزن 20% → 33.3%
    no_deletion_rate: (1 − deletedCount/totalCount) * 100,   // وزن 10% → 16.7%
  };

  score = weightedAverage(active_factors, redistributed_weights);
  // الأوزان الأصلية: 30+20+10 = 60. تُمدد نسبياً إلى 100.
  ```

  > **ملاحظة:** عند إضافة العاملين المقفلين لاحقاً (بعد الربط البنكي)، تُعاد الأوزان إلى الأصلية: 30% + 25% + 20% + 15% + 10% = 100%.

  ### نطاقات النتيجة

  | النطاق | المستوى | اللون | التأثير |
  |--------|---------|-------|---------|
  | 90-100 | ممتاز | Success `#2E7D32` | Tier 2 متاح |
  | 70-89 | جيد | Success `#2E7D32` | Tier 2 قيد التقدم |
  | 50-69 | متوسط | Warning `#B7791F` | Tier 2 متأخر |
  | أقل من 50 | منخفض | Danger `#D32F2F` | Tier 2 مقفل |

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
AI calculates Integrity Score from 3 active + 2 locked factors (see §Integrity Score Display below)
  ↓
Bot displays summary_card widget:
  - Current score: 78/100 (Good) — Dart-computed from 3 active factors
  - Logging consistency: 22/30 days — Dart-computed
  - Receipt upload rate: 8/12 flagged — Dart-computed
  - No deletion rate: 95% — Dart-computed
  - دقة البيانات: قادم مع الربط البنكي (مقفل)
  - سرعة الاستجابة: قادم مع الربط البنكي (مقفل)
  ↓
Bot: "أداءك جيد! لو صورت 4 فواتير إضافية — توصل 85."

> **ملاحظة:** حسب DEC-025، عاملا `data_match_accuracy` و `response_time_factor` مقفلان حتى يتم تنفيذ الربط البنكي. المثال السابق "Data accuracy: 92% match" كان مثالاً مختلقاً (fabricated) وتم تصحيحه.
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
