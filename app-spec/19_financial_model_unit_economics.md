# Azdal — Financial Model & Unit Economics

> **Status:** Draft — detailed projections  
> **Source:** Synthesized from `docs/business/business-model-canvas.md` and `docs/business/pitch-deck.md`

---

## 1. MVP Cost Structure (Hackathon — 0 users to launch)

| Line Item | Monthly Cost | Annual | Notes |
|-----------|-------------|--------|-------|
| Gemini Flash API | $30 | $360 | Dev + demo usage, ~$1.50/active user/month |
| Gemini Vision OCR | $10 | $120 | Receipt scanning (dev only) |
| Supabase | $0 | $0 | Free tier (500MB, 2GB bandwidth) |
| Apple Developer Program | $8.25 | $99 | Annual |
| Google Play Console | $0 | $25 | One-time |
| Domain (azdal.app) | $1 | $12 | Annual |
| **Total MVP** | **~$50/month** | **~$616/year** |

---

## 2. Unit Economics — Per Active User

### Revenue (Free Tier)

| Source | Per User/Month | Notes |
|--------|---------------|-------|
| B2C Direct | $0 | Free forever |
| B2B Credit Score (Phase 2) | $0.50-$1.50 | Per query, varies by partner |

### Cost Per User/Month

| Cost Component | Per User/Month | Calculation |
|---------------|---------------|-------------|
| Gemini API (20 msgs/day) | $1.50 | Flash: $0.30/M input + $2.50/M output |
| Supabase (storage + compute) | $0.10 | At scale, pooled |
| **Total Cost/User** | **~$1.60** | |

### Contribution Margin (B2C Only, Phase 1)
- Revenue: $0
- Cost: $1.60
- **Margin: -$1.60/user/month** (growth phase — intentional)

---

## 3. B2B Revenue Model (Phase 2)

### Behavioral Credit Score Pricing

| Plan | Price | Queries/Month | Per Query |
|------|-------|-------------|-----------|
| Starter | 5,000 SAR/month (~$1,333) | Up to 1,000 | 5 SAR |
| Growth | 15,000 SAR/month (~$4,000) | Up to 5,000 | 3 SAR |
| Enterprise | Custom | Unlimited | Negotiated |

### B2B Economics Per Partner

| Metric | Value |
|--------|-------|
| Avg partner revenue | 5,000-15,000 SAR/month |
| Avg cost per query (compute) | ~0.50 SAR |
| Gross margin per query | ~90% |
| **Partner CAC:** | Low — direct sales to known BNPL/finance companies |

### Break-Even Analysis

| Scenario | Users | B2B Partners | Monthly Revenue | Monthly Cost | Profit |
|----------|-------|-------------|-----------------|-------------|--------|
| MVP (1K users) | 1,000 | 0 | $0 | $50 | -$50 |
| Growth (10K users) | 10,000 | 1 | $1,333 | $1,500 | -$167 |
| Profit (10K users) | 10,000 | 5 | $6,665 | $1,500 | +$5,165 |
| Scale (50K users) | 50,000 | 10 | $13,330 | $5,500 | +$7,830 |

**Key insight:** Break-even with just 5 B2B partners at 10K users.

---

## 4. CAC (Customer Acquisition Cost)

| Channel | Cost | Users/Acquired | CAC |
|---------|------|----------------|-----|
| X.com (organic) | $0 | Variable | $0 |
| Hackathon visibility | $0 | Initial spike | $0 |
| FinTech Saudi network | $0 | B2B warm intros | $0 |
| Word of mouth | $0 | Organic growth | $0 |
| App Store presence | $0 | Organic discovery | $0 |
| **Phase 1 CAC** | **$0** | **Organic only** | **$0** |

---

## 5. LTV (Lifetime Value)

| Phase | Revenue Stream | LTV Estimate |
|-------|---------------|-------------|
| Phase 1 (Coach) | $0 B2C | $0 (growth phase) |
| Phase 2 (B2B insights) | Per-query fees | $45/user/year (avg 30 queries/year/partner) |
| Phase 3 (Smart Lender) | Murabaha margins | Market rate — varies by loan size |
| Phase 4 (Referrals) | Commission | 0.5-1% of AUM routed |

**LTV:CAC ratio (Phase 2+):** LTV > $45, CAC = $0 → **infinite/undefined** (organic growth)

---

## 6. Key Metrics Dashboard

| Metric | Phase 1 Target | Phase 2 Target |
|--------|---------------|----------------|
| MAU (Monthly Active Users) | 1,000 | 10,000 |
| DAU/MAU ratio | 40% | 50% |
| Avg transactions/user/day | 8-10 | 12-15 |
| "Can I buy?" queries/user/month | 5-8 | 10-15 |
| Integrity Score avg | — | 65-75 |
| B2B partners | 0 | 10 |
| Monthly revenue | $0 | $13,330+ |
| Monthly burn | $50 | $1,500 |
| Runway | N/A (self-funded) | Infinite (profitable) |

---

## 7. Unit Economics Validation

| Assumption | Validation Source |
|-----------|-----------------|
| 20 msgs/user/day | Comparable to Cleo/Origin usage patterns |
| Gemini Flash $1.50/user/month | Google AI pricing (2026) |
| BNPL pricing 5,000 SAR/month | Market research — what Tabby/Tamara pay for SIMAH |
| 10K users in Year 1 | Conservative — Saudi market size + zero competition |
| $0 CAC | Organic + hackathon + X.com — validated by similar Saudi apps |

---

## 8. Risk to Financial Model

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Gemini raises prices 2x | Cost/user doubles to $3.20 | DeepSeek fallback ($0.38/M output). Multi-model strategy. |
| BNPL partners slow to adopt | Revenue delayed 6-12 months | Runway from hackathon funding + self-funded |
| User growth slower than projected | Delayed B2B data quality | Focus on engagement over acquisition — quality > quantity |

---

## Related
- `02_monetization_entitlements.md` — Revenue model phases
- `00_product_discovery.md` — Competitive moat
- `docs/business/business-model-canvas.md` — Full BMC
