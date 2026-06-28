# Azdal — Build Plan (3-Day Hackathon MVP)

> **Source:** Claude's exported Build Plan (May 16, 2026)
> **File:** `~/Downloads/Build Plan AI Expense Agent (H.docx`
> **Status:** Ready to execute

---

## Objective

Build a hackathon-winning MVP that proves:
> An Arabic AI Agent for expense management is not a hallucination — it's a practical, high-value solution.

Requirements:
- Financial accuracy (zero math hallucination)
- WOW demo experience
- Clean architecture — expandable post-hackathon without rebuild

---

## Architectural North Star

> **LLM understands and decides — NEVER calculates, NEVER stores.**

| Function | Who |
|----------|-----|
| Language understanding | LLM ✅ |
| Math & financial logic | SQL / Python ✅ |
| Display | Declarative UI (GenUI/A2UI) ✅ |
| Storage | Deterministic database ✅ |

---

## High-Level Architecture

```
┌─────────────────────────────────────────┐
│              Flutter App                 │
│  Chat UI + Voice + Image Upload         │
│  GenUI Renderer (JSON → Widgets)        │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│        Agent Orchestrator                │
│  Gemini Flash (Arabic NLU)              │
│  Intent Router + Guardrails             │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           Tools Layer                    │
│  OCR Tool | SQL Insert/Query            │
│  Python Calculator | Chart Config       │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           PostgreSQL                     │
│  Transactions / Categories / Budgets    │
└─────────────────────────────────────────┘
```

---

## Components

### 1. Frontend — Flutter
- Chat UI (RTL + Arabic)
- Voice Input (on-device Apple Speech)
- Image Picker (receipt camera)
- GenUI Renderer: receives JSON UI Schema → renders from widget catalog
- ⚠️ FORBIDDEN: any dynamic code execution

### 2. Brain — LLM (Gemini Flash)
**Responsibilities:**
- Understand Arabic (colloquial + formal)
- Intent classification: `add_transaction | analyze_spending | can_i_buy`
- Tool selection

**Non-Responsibilities:**
- ❌ Addition / subtraction / calculation
- ❌ Final financial decisions

### 3. Guardrails (Non-negotiable)
- ❌ LLM never calculates numbers
- ✅ All numbers = SQL or Python
- ✅ Fixed Data Dictionary for categories
- ✅ Soft Delete only

### 4. Tools Layer
- **SQL Tool:** insert_transaction, query_monthly_summary
- **Python Tool:** budget simulation, cashflow projection
- **OCR Tool:** image → JSON (amount, date, merchant)
- **UI Generator:** converts calculation results to GenUI JSON

---

## Killer Feature: "Can I Buy This?"

**Flow:**
1. User asks: "هل أقدر أشتري آيفون بـ 4500؟"
2. LLM identifies intent = `can_i_buy`
3. SQL pulls: income, commitments, current spend
4. Python simulates purchase scenario
5. GenUI renders: verdict card + before/after chart

**Why it wins:** Financial accuracy + intelligent experience — the "WOW" moment.

---

## 3-Day Execution Plan

### Day 1 — Foundation
- [ ] Flutter Chat UI
- [ ] Gemini Flash connection
- [ ] `add_transaction` (text input)
- [ ] **Output:** "صرفت ٥٠ ريال قهوة" → stored in DB

### Day 2 — Visual Intelligence
- [ ] OCR receipt scanning
- [ ] `analyze_spending`
- [ ] Charts via GenUI
- [ ] **Output:** "كيف صرفي هالشهر؟" → dynamic chart

### Day 3 — The Knockout Punch
- [ ] `can_i_buy` workflow
- [ ] Arabic response refinement
- [ ] Demo Script + Pitch
- [ ] **Output:** Feature that wins

---

## Demo Script (3 Minutes)

| Time | Segment | Content |
|------|---------|---------|
| 30s | Problem | "Every expense app fails — 85% of users quit within a month" |
| 90s | Live Demo | Voice: "صرفت ٢٠٠ ريال" → Receipt photo → "Can I buy?" → Visual verdict |
| 30s | Moat | "First Arabic AI financial agent. Understands your dialect. Reads your receipts. Calculates your Zakat." |
| 30s | Vision | Open Banking integration, automatic SMS parsing |

---

## Scope Control (CRITICAL)

### Build:
- ✅ Chat + Voice
- ✅ OCR receipt scanning
- ✅ Smart analysis
- ✅ "Can I buy?" workflow

### Do NOT build:
- ❌ Open Banking now
- ❌ Custom ML models
- ❌ 24/7 background agent
- ❌ SMS parsing (mention as future)

---

## Ready-to-Build Checklist

- [ ] Flutter project created
- [ ] Gemini API key configured
- [ ] Supabase database provisioned
- [ ] Prompt templates loaded
- [ ] Demo data prepared (pre-seeded transactions for demo)

---

## Next Step

```
Next: Prompts
→ System Prompt for agent brain
→ Intent Router prompt
→ Tool calling prompts
→ Cold Start behavior prompts
```

Full Prompt Pack available in Claude's conversation export.
