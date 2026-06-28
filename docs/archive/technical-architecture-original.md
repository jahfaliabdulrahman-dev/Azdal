# Azdal — Technical Architecture & Feasibility

> **Date:** 2026-05-22 (Updated — Hybrid Verification + B2B Credit Scoring)
> **Author:** Sulaiman (Hermes) + Claude + Gemini — multi-agent validation
> **Hardware context:** M4 Mac mini (24GB RAM), Apple Silicon
> **Target:** Flutter mobile app (iOS/Android), Arabic-first

---

## 1. Is It Technically Feasible?

**Yes. Unanimous across multiple AI agents.**

| Component | Status | Notes |
|-----------|--------|-------|
| Conversational AI (chat) | ✅ Ready | Gemini Flash (primary), Gemini Pro (complex) |
| OCR (receipt scanning) | ✅ Ready | Gemini Vision — best Arabic OCR |
| Voice-to-text | ✅ Ready | Apple Speech on-device (free, instant) |
| Text-to-speech | ✅ Ready | AVSpeechSynthesizer on-device (natural Arabic) |
| Dynamic UI (GenUI) | ✅ Ready | Flutter GenUI SDK + A2UI protocol |
| Mobile app (Flutter) | ✅ Ready | Cross-platform, single codebase, RTL built-in |
| Backend/Database | ✅ Ready | Supabase PostgreSQL |
| Financial calculations | ✅ Ready | SQL + Python — LLM FORBIDDEN from math |
| Behavioral Credit Scoring | 🔨 Designing | Hybrid verification architecture (below) |
| Bank integration | ⚠️ Emerging | SAMA Open Banking licensing started Mar 2026 |
| B2B API (Credit Score) | 🔮 Future | Phase 2 — post-hackathon |

---

## 2. The Architecture Decision (Final)

### LLM understands and routes — but NEVER calculates, NEVER stores, NEVER makes final financial decisions.

| Layer | Runs On | Technology |
|-------|---------|------------|
| Voice → Text (STT) | Device | Apple Speech |
| Text → Voice (TTS) | Device | AVSpeechSynthesizer |
| Chat understanding + Intent routing | Cloud | Gemini Flash |
| Complex financial reasoning | Cloud | Gemini Pro (20% of queries) |
| OCR receipt scanning | Cloud | Gemini Vision |
| All calculations | Server | SQL + Python |
| Data storage | Server | Supabase PostgreSQL |
| Dynamic UI rendering | Device | Flutter GenUI/A2UI |
| Caching recent responses | Device | SQLite |
| Financial Knowledge Layer | Server | Rule engine + `Financial Knowledge Layer.md` |

---

## 3. Hybrid Verification Architecture (NEW)

### The Problem

For B2B Behavioral Credit Scoring to be viable, data must be trustworthy. User self-reporting alone is insufficient — Goodhart's Law: "When a measure becomes a target, it ceases to be a good measure."

### The Solution: Hybrid Verification Architecture

```
┌──────────────────────────────────────────────┐
│              GROUND TRUTH LAYER               │
│  Open Banking API (deterministic data)        │
│  Bank says: 350 SAR, Panda, May 21, 14:30    │
│  THIS CANNOT BE FAKED                         │
├──────────────────────────────────────────────┤
│              ENRICHMENT LAYER                  │
│  User adds context (voice/OCR):               │
│  "Milk, bread, diapers"                       │
│  AI cross-validates total vs bank amount      │
├──────────────────────────────────────────────┤
│              VALIDATION LAYER                  │
│  Integrity Score = match rate between layers   │
│  Spoofing detection: mismatch → penalty       │
│  Consistency check: does story match history?  │
├──────────────────────────────────────────────┤
│              BEHAVIORAL SCORE LAYER            │
│  Built from: spending patterns + commitment   │
│  history + goal progress + Integrity Score    │
│  = The first behavioral credit score in MENA  │
└──────────────────────────────────────────────┘
```

### For the Hackathon: MOCK this architecture

- Generate mock bank transactions (deterministic ground truth)
- User enriches via voice/OCR (demo flow)
- System shows Integrity Score calculation
- Demonstrate spoofing detection: user claims "50 SAR" but bank says "500 SAR" → penalty

### For Production (Phase 2):

- Real SAMA Open Banking integration
- Real Integrity Score engine
- Real B2B API: `GET /v1/score?user_hash={hash}` → {score, confidence, factors}

---

## 4. B2B Behavioral Credit Scoring API (Future — Phase 2)

### Why BNPL Companies Need This

| BNPL Risk | How Azdal Score Helps |
|-----------|----------------------|
| No salary assignment (تحويل راتب) | Score predicts repayment from actual behavior |
| Customer self-reports income | Azdal verifies spending consistency |
| High default rates | Behavioral screening reduces defaults |
| SAMA regulatory pressure | Azdal provides "responsible lending" compliance |

### API Design (Future)

```yaml
Endpoint: GET /v1/behavioral-score
Params:
  user_hash: string (anonymized)
  purpose: "installment" | "credit_card" | "micro_loan"
Returns:
  score: 0-100
  tier: "platinum" | "gold" | "silver" | "bronze"
  confidence: 0-1 (based on data completeness)
  factors:
    - debt_to_income_ratio
    - impulse_spending_frequency
    - logging_consistency
    - savings_rate
    - goal_progress
  recommendation: "approve" | "review" | "decline"
  max_safe_installment: amount in SAR
```

### Pricing Model

| Tier | Price |
|------|-------|
| Per query | 5-15 SAR per score lookup |
| Monthly subscription (up to 1,000 queries) | 5,000 SAR/month |
| Enterprise (unlimited) | Custom |

---

## 5. Financial Knowledge Layer Integration

The AI's decision-making is grounded in `Financial Knowledge Layer.md`:

- **Hard Rules:** 50/30/20, emergency fund (3-6 months), DTI ≤ 33%
- **Debt Classification:** Asset-backed (good) vs consumption (bad) — decision matrix
- **Prioritization:** Debt Avalanche (highest interest first) for Saudi context
- **Investment Hierarchy:** Emergency fund → debt repayment → long-term investing → speculative
- **Simulation Engine:** "If you invest X in fund Y for Z years at rate R..."

The AI never invents financial rules. It references the Knowledge Layer.

---

## 6. PDPL & SAMA Compliance

### Hackathon MVP
Ignore SAMA entirely. We are an educational tool. NO regulated activity.

### Phase 2 — B2B Credit Insights
- Sell anonymized behavioral scores, not raw data
- No PII stored: names, national IDs, bank account numbers
- PDPL: explicit consent, data minimization, right to delete

### Phase 3 — Smart Lender (Post-License)
- SAMA Consumer Finance License required
- Capital reserve requirements apply
- Islamic financing: Murabaha structure

---

## 7. Cost Analysis

| Model | Input (1M tokens) | Output (1M tokens) |
|-------|-------------------|---------------------|
| Gemini 2.5 Flash | $0.30 | $2.50 |
| Gemini 2.5 Pro | $1.25 | $10.00 |
| DeepSeek V3.2 | $0.25 | $0.38 |

Active user: 20 msgs/day → ~$1.50/month on Gemini Flash.

---

## 8. Development Stack

```yaml
Frontend:
  Framework: Flutter 3.x (Dart)
  State Management: Riverpod
  UI: Material 3 (Arabic RTL)
  Dynamic UI: Flutter GenUI SDK + A2UI

Backend:
  Database: Supabase (PostgreSQL)
  API Layer: Supabase Edge Functions
  Calculations: Python (SQL + Polars)

AI:
  Primary: Gemini 2.5 Flash
  Vision: Gemini 2.5 Pro Vision
  Fallback: DeepSeek V3.2
  Knowledge: Financial Knowledge Layer (rules engine)
```

---

## 9. Key Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| LLM math hallucination | CRITICAL | LLM NEVER calculates — SQL/Python only |
| Goodhart's Law (user gaming) | HIGH | Hybrid verification — Open Banking ground truth |
| BNPL regulatory changes | MEDIUM | Phase 1 = no license needed. Phase 2 = insights, not lending |
| Cold start: no transaction history | HIGH | Progressive Intelligence — never say "no data" |
| User retention | HIGH | Behavioral UX — Hook Model + Progress Principle |
| Open Banking delays in KSA | MEDIUM | SMS parsing (Android) as bridge |

---

## 10. Final Verdict

**Hackathon MVP:** Build Tier 1 (Coach) + simulate Tier 2 gateway. Prove the AI can assess financial health from behavior.

**Post-hackathon:** Build B2B credit scoring API. Sell to BNPL companies.

**Long-term:** Apply for SAMA license. Become the smart lender.

**Architecture:** Hybrid — LLM understands, SQL calculates, GenUI displays, Financial Knowledge Layer guides all decisions.
