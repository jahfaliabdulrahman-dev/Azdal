# Azdal — Monetization & Entitlements

> **Status:** Strategy Locked  
> **Source:** Synthesized from `docs/business/business-model-canvas.md` and `docs/business/pitch-deck.md`

---

## Revenue Model — Phased

### Phase 1: Coach (Hackathon → Year 1)

| Stream | Model | Price |
|--------|-------|-------|
| B2C App | FREE | $0 |

**Rationale:** Build user base + behavioral data. Zero cost to users. Focus on growth and validation.

---

### Phase 2: B2B Behavioral Credit Insights (Year 1-2)

| Stream | Model | Price |
|--------|-------|-------|
| API per query | BNPL company queries score before approving loan | 5-15 SAR/query |
| Monthly subscription | Up to 1,000 queries/month | 5,000 SAR/month |
| Enterprise | Unlimited queries + dashboard | Custom |

**Target customers:** Tabby, Tamara, إمكان, النايفات, bank credit card divisions

**Revenue target:** 10 partners × 5,000 SAR/month = **50,000 SAR/month**

**Why they pay:**
- No salary assignment (تحويل راتب) → need alternative credit assessment
- SAMA tightening BNPL regulations → Azdal helps compliance
- Behavioral scoring reduces default rates → direct ROI

---

### Phase 3: Smart Lending (Year 3+)

| Stream | Model |
|--------|-------|
| Murabaha margins | Islamic installment financing to Tier 2 users |
| Competitive advantage | Lower default rate → higher effective margin than competitors |

**Prerequisite:** SAMA Consumer Finance License

---

### Phase 4: Investment Referrals (Year 3+)

| Stream | Model |
|--------|-------|
| Referral commission | Route users with surplus to investment platforms |
| Per-user fee | Partners pay for qualified investor leads |

**Target partners:** Alinma funds, Tamra, Abyan, Derayah

---

## Cost Structure

### MVP (Hackathon)

| Item | Monthly Cost |
|------|-------------|
| Gemini Flash API | $10-30 |
| Supabase (free tier) | $0 |
| Apple Developer | $8.25 |
| **Total Burn** | **~$50/month** |

### At Scale (10K users)

| Item | Monthly Cost |
|------|-------------|
| Gemini Flash API | $1,200 |
| Supabase Pro | $25 |
| **Total** | **~$1,500/month** |

**Key insight:** ONE B2B client at 5,000 SAR/month covers ALL costs.

---

## AI Cost Analysis

| Model | Input (1M tokens) | Output (1M tokens) |
|-------|-------------------|---------------------|
| Gemini 2.5 Flash | $0.30 | $2.50 |
| Gemini 2.5 Pro | $1.25 | $10.00 |
| DeepSeek V3.2 | $0.25 | $0.38 |

**Active user estimate:** 20 messages/day → ~$1.50/month on Gemini Flash

---

## Pricing Strategy — "Free Forever" B2C

| Tier | Price | Entitlements |
|------|-------|-------------|
| Tier 1 — Coach | FREE | Full AI coach, tracking, "Can I buy?", goals, Integrity Score |
| Tier 2 — Smart Lender | Murabaha margins only | Loan access + better rates than BNPL |
| Tier 3 — Wealth Builder | Commissions only | Investment routing + wealth tracking |

**No premium subscription.** B2C is permanently free. Revenue comes from B2B and lending.

---

## Entitlement Rules

| Feature | Available In | License Required |
|---------|-------------|-----------------|
| Chat + transaction input | Tier 1 (free) | None |
| "Can I buy?" engine | Tier 1 (free) | None |
| Integrity Score | Tier 1 (free) | None |
| Savings goals | Tier 1 (free) | None |
| Behavioral Credit Score | B2B (Phase 2) | None (insights) |
| Installment loans | Tier 2 | SAMA Consumer Finance |
| Investment routing | Tier 3 | None (referrals) |

**Rule:** Backend validates ALL entitlement. Client is UX-only.

---

## Business Model Canvas Summary

> **Free AI financial coach for Saudi consumers → Behavioral data for credit scoring → Sell insights to BNPL/finance companies → Become the smart lender.**
>
> المستخدم يدخل مديونًا — ويخرج مستثمرًا.

---

## Related
- `00_product_discovery.md` — Full product vision
- `01_prd.md` — Feature catalog
- `19_financial_model_unit_economics.md` — Detailed unit economics
