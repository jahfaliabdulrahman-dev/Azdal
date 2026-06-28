# Azdal — Final Architecture Decision (Locked)

> **Date:** 2026-05-16
> **Decision by:** Eng. Abdulrahman + Sulaiman (Hermes) + Claude
> **Status:** LOCKED — no further architecture changes before MVP

---

## The Decision After 3-Agent Validation

After 35+ technical documents from Claude, Red Team critique from Sulaiman, and final consensus:

**We strip to MVP essentials. One month build window.**

---

## Final Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Frontend | Flutter (Material 3, RTL) | Single codebase iOS/Android |
| Dynamic UI | GenUI/A2UI (beta) OR native Flutter widgets | Same JSON schemas, swap renderer if needed |
| Voice input | Apple Speech → text only | Optional. Text-first. |
| AI | Gemini Flash (primary) | Arabic NLU + Vision OCR |
| AI Fallback | Rule-based regex | If Gemini fails: repair once, then regex |
| Backend | Supabase (PostgreSQL) | Single table only |
| State | Session + SharedPreferences | Guest-first, no login |
| Calculations | Python (Supabase Edge Functions) | LLM NEVER calculates |

---

## Database — Single Table

```sql
CREATE TABLE transactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    TEXT NOT NULL,
  amount_sar    NUMERIC(10,2) NOT NULL CHECK (amount_sar > 0),
  category      TEXT NOT NULL CHECK (category IN (
    'سكن','مواصلات','طعام','قهوة','تسوق','صحة','تعليم',
    'فواتير','ترفيه','اشتراكات','سفر','صدقة/زكاة','أخرى'
  )),
  merchant      TEXT,
  tx_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  source        TEXT DEFAULT 'manual',
  is_deleted    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tx_session_month 
  ON transactions(session_id, tx_date) 
  WHERE is_deleted = FALSE;
```

**No profiles table. No categories table. No joins.**

---

## User Data Strategy

| Data | Storage | Persists? |
|------|---------|-----------|
| Transactions | Supabase | ✅ Across sessions |
| Income | SharedPreferences | ✅ On device |
| Commitments | SharedPreferences | ✅ On device |
| Days to salary | SharedPreferences | ✅ On device |
| Active session state | In-memory | ❌ Session only |

Flow:
```
App start → Read SharedPreferences → Populate Session
User interacts → Update Session → Save to SharedPreferences
```

Result: User feels "the app remembers me" without login.

---

## What We CUT (Post-MVP Roadmap)

| Cut Component | Why | When to Add |
|---------------|-----|-------------|
| Trace Logger | Debug tool, not product | Post-hackathon |
| Confidence Engine | Complex formulas, untested | Phase 2 |
| State Machine (8 states) | 3 states suffice | Phase 2 |
| Voice Assistant (TTS) | Latency + UX risk | Phase 3 |
| Demo Fallback Engine | Duplicates work | Only if needed |
| profiles table | Guest-first, no login | When adding accounts |
| categories table | CHECK constraint enough | When needing icons/translations |

---

## What We KEEP (MVP Core)

1. **Chat UI** — text input, Arabic NLU via Gemini Flash
2. **OCR Receipt** — camera → Gemini Vision → JSON → transaction
3. **"Can I Buy?"** — simple Python calculator, deterministic
4. **Quick Buttons** — 3 types: category picker, amount picker, period picker
5. **Cold Start Intelligence** — "never say no data"
6. **Guardrails** — LLM never calculates, soft delete, fixed categories, double delete confirmation

---

## Gemini Failure Strategy (3 Lines)

1. **Invalid JSON:** Repair once → fallback to rule-based keyword mapping
2. **Wrong intent:** Show Intent Disambiguation UI (4 buttons)
3. **Timeout >5s:** Show Quick Buttons immediately, skip LLM

---

## GenUI/A2UI Plan B

If Flutter GenUI SDK (beta) fails:
- Keep the same JSON schemas
- Swap renderer to native Flutter widgets
- `action_buttons` → `Wrap` of `ElevatedButton`
- `summary_card` → `Card` widget
- `quick_input_form` → `TextField`

---

## Voice — Decision

- **Text-first** is the primary MVP interface
- Voice = optional `Speech→Text` layer only
- No TTS, no streaming, no voice assistant
- User ALWAYS sees the transcript before sending

---

## Build Plan (4 Weeks)

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1 | Chat UI + Router + Quick Buttons | add_transaction flow working |
| 2 | OCR + Gemini Vision integration | Receipt → transaction |
| 3 | "Can I buy?" calculator + UI | Purchase decision engine |
| 4 | Polish + Demo prep + Judge Q&A | Show-ready |

---

## Golden Rule

> Anything not visible in the demo = don't build it now.
