# Azdal — Product Discovery

> **Status:** 🟡 Strategy Locked — Pre-Implementation  
> **Stage:** Stage 0 — Specification & Planning  
> **Hackathon:** AMAD, Financial Education Track, July 16-18, 2026

---

## Identity

| Element | Value |
|---------|-------|
| Name | أزدل (Azdal) |
| Origin | الأزد — Arab tribe of honor and resilience |
| Pattern | وزن "أفعل" — superlative |
| Tagline AR | أزدل — درعك المالي |
| Tagline EN | Azdal — Spend Aware |
| Primary | Navy #001F5E |
| Accent | Cyan #32C2FF |
| Symbol | 🜔 Solomon's Seal |
| Domain | azdal.app |

---

## Vision

**Azdal is the first financial rehabilitation program that transforms users from debt-trapped consumers into conscious investors through a 3-tier progression system.**

We are not a budgeting app. We are not a BNPL clone. We are a **financial transformation platform**.

> المستخدم يدخل مديونًا — ويخرج مستثمرًا.

---

## The Real Problem

### Consumer Pain (B2C)

| Problem | Root Cause | Azdal's Answer |
|---------|------------|----------------|
| 79% shop unconsciously (SAMA study) | BNPL apps encourage spending without awareness | Pre-purchase AI coach: "Can I buy?" before every decision |
| Salary "disappears" | Small daily expenses accumulate invisibly | Zero-friction tracking via voice, OCR, SMS |
| BNPL debt spiral | Tabby/Tamara approve based on salary — not behavior | Behavioral credit scoring: lend only to the ready |
| No path from debt to wealth | No app combines prevention + lending + investment | 3-tier transformation journey |
| 77% abandon finance apps in 3 days | Manual data entry is exhausting | Voice, camera, chat — zero manual entry |

### Business Pain (B2B)

| Problem | Who Has It | Azdal's Answer |
|---------|------------|----------------|
| High default rates on BNPL | Tabby, Tamara, finance companies | Behavioral Credit Score — assess REAL spending behavior |
| No salary assignment (تحويل راتب) | BNPL & micro-finance companies | Score predicts repayment from behavior |
| SAMA tightening BNPL regulations | All BNPL providers | Helps them comply by lending only to creditworthy |
| Can't distinguish good vs bad borrowers | All lenders | Behavioral data is the missing signal |

---

## The Solution — Three Engines

### Engine 1: B2C — Zero-Friction Consumer App

**Input methods:**
- 🎤 Voice: "سجل 150 ريال عشاء" — ambient capture
- 📷 Vision OCR: Photo of receipt → extracted line items
- 💬 Chat: Natural conversation with AI financial assistant
- 📱 SMS parsing (Android): Auto-read bank transaction messages

**AI capabilities:**
- Auto-classification of transactions (Green/Gray/Red triage)
- Proactive "Can I buy this?" purchase simulation
- Generative UI via GenUI/A2UI widget catalog
- Impulse spending detection and pattern alerts
- Cold Start Intelligence: never say "no data"
- Integrity Score tracking (transparency metric)
- Compound transaction splitting
- Recurring commitment intelligence (BNPL tracking)

### Engine 2: B2B — Behavioral Credit Scoring

- API endpoint: banks & BNPL query "Azdal Behavioral Score"
- Score built from: spending patterns, commitment history, Integrity Score, goal progress
- Deterministic validation: Open Banking ground truth + AI enrichment + cross-validation
- Revenue: per-query fee or monthly subscription

### Engine 3: B2B2C — Smart Liquidity Routing (Future)

- Detect investable surplus after debt repayment
- Match user to investment products (Alinma funds, Tamra, Abyan)
- Revenue: referral commission
- Vision: user enters in debt → exits with investments

---

## The Three Tiers

```
┌─────────────────────────────────────────────────────────┐
│  TIER 1 — COACH (المستشار)                               │
│  Zero license required                                  │
│  AI watches behavior. Advises. Prevents bad spending.    │
│  User builds "Integrity Score" through honest tracking.  │
│  Gateway: Pass behavioral test → Unlock Tier 2           │
├─────────────────────────────────────────────────────────┤
│  TIER 2 — SMART LENDER (المُقرِض الواعي)                  │
│  SAMA license required                                  │
│  Installment loans — ISLAMIC (Murabaha)                 │
│  Approval based on: BEHAVIOR + SALARY — not salary alone│
│  Dynamic credit ceiling. AI monitors & adjusts.          │
│  Gateway: First savings goal achieved → Unlock Tier 3    │
├─────────────────────────────────────────────────────────┤
│  TIER 3 — WEALTH BUILDER (باني الثروة)                    │
│  Partnership phase — no additional license               │
│  Zero debt milestone. Investment guidance.               │
│  AI routes surplus to partner platforms.                 │
│  Revenue: referral fees from investment platforms        │
└─────────────────────────────────────────────────────────┘
```

---

## Phase Strategy (Time-Based)

| Phase | Timeline | Product | Revenue | License |
|-------|----------|---------|---------|---------|
| Phase 1: Coach | Hackathon → Year 1 | Free B2C AI financial coach | $0 (growth) | None |
| Phase 2: B2B Insights | Year 1-2 | Behavioral Credit Scores to BNPL companies | B2B subscriptions + per-query fees | None (insights only) |
| Phase 3: Smart Lender | Year 3+ | Become the lender — lend only to Tier-verified users | Murabaha margins | SAMA Consumer Finance License |
| Phase 4: Wealth Builder | Year 3+ | Route surplus to investment platforms | B2B2C referral fees | None |

---

## Competitive Moat

1. **Behavioral Credit Scoring:** No one in MENA assesses creditworthiness from actual spending behavior
2. **Data granularity:** Banks see "Carrefour — 350 SAR." Azdal sees "milk, tomatoes, diapers."
3. **UX as moat:** Conversational + voice + zero-friction = users stay
4. **Trust as moat:** Islamic branding, privacy-first, PDPL-compliant, Arabic-native
5. **Behavioral science foundation:** Every feature grounded in academic behavioral economics (23 refs)
6. **Regulatory moat:** Phase 1 needs NO license. Phase 2 leverages SAMA Open Banking.

---

## Hackathon MVP Scope

### What We Build (Tier 1 COMPLETE)
- Conversational chat with AI (Arabic-first)
- Voice + OCR transaction input
- "Can I buy?" purchase simulation engine
- Commitment tracking (including BNPL installments)
- Savings goals with gap detection
- Integrity Score (transparency metric)
- Cold Start Intelligence
- Tier 2 gateway simulation

### What We DO NOT Build (Hackathon)
- Real bank integration (mock for demo)
- Actual lending/installment processing
- B2B API (vision slide only)
- SMS parsing (Android only, skip for demo)
- Investment routing (vision slide only)

---

## Academic Foundation

Built on proven behavioral science: BJ Fogg (B=MAP), Nir Eyal (Hook Model), Teresa Amabile (Progress Principle), Kahneman & Tversky (Prospect Theory), Richard Thaler (Mental Accounting), Robert Cialdini (Commitment & Consistency).

Full references: `docs/research/financial-knowledge-layer.md`

---

## Related
- `01_prd.md` — Product Behavior & Tier System
- `07_flutter_architecture.md` — Technical Architecture
- `02_monetization_entitlements.md` — Business Model
- `docs/business/hackathon-strategy.md` — Full hackathon plan
