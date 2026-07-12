# Azdal — Monetization & Entitlements

> **Status:** Strategy Locked — Revised [2026-07-12] per team review ahead of AMAD
> **Source:** Synthesized from `docs/business/business-model-canvas.md` and `docs/business/pitch-deck.md`
> **Change log:** Replaced the original "Free Forever B2C" model with a freemium model (free core + paid subscription + pay-per-course) to give the product a Day-1 revenue story for judges/investors. B2B and lending streams unchanged in substance, reorganized by timeline. Investment referrals pulled forward from Phase 4 into Phase 2 since they don't require a lending license. Added Corporate Wellness B2B and a future Advisor Marketplace stream.

---

## Revenue Model — Phased

### Phase 1: Coach — Freemium (Hackathon → Year 1)

| Stream | Model | Price |
|--------|-------|-------|
| B2C Free core | Expense tracking, receipt scan/OCR, chat input | $0 |
| B2C Premium subscription | Unlocks: unlimited AI financial advisor (future prediction, custom plans — home purchase, marriage, retirement), full behavioral analysis, advanced monthly PDF reports (strengths, saving opportunities, financial health index) | 49–79 SAR/month |
| Pay-per-Course | In-app educational store, segmented price per course. Sold independently of the subscription — a non-subscriber can buy one urgent course. | Distress-topic courses (debt elimination, commitment management): **29 SAR**. Growth-topic courses (investing for beginners, stocks, REITs): **59 SAR**. Both under the subscription price so courses don't cannibalize it. |

**Rationale:** Gives the product real, demonstrable Day-1 revenue instead of "free forever, monetize eventually." Directly answers the "no revenue/sustainability" criticism from past AMAD judging. Core tracking stays free — this is a freemium upsell, not a paywall on the core value prop.

---

### Phase 2: Affiliate, Lead-Gen & B2B Insights (Year 1-2)

| Stream | Model | Price |
|--------|-------|-------|
| Bank / investment referral | Smart, behavior-triggered commission — refer users who are ready (per their budget + surplus) to open savings accounts or investment portfolios | Commission per conversion |
| Installment company referral | Route users to installment platforms within their computed "safe limit," or to budget-fitting product recommendations | Commission per conversion |
| B2B Behavioral Credit Score (API) | BNPL/non-bank financing companies query the Integrity Score before approving a loan, to assess creditworthiness and cut default risk | 5-15 SAR/query |
| B2B Behavioral Credit Score (subscription) | Up to 1,000 queries/month | 5,000 SAR/month |
| B2B Enterprise | Unlimited queries + dashboard | Custom |
| Corporate Wellness (B2B) | Annual subscription — large employers offer Azdal to staff as a benefit, to raise financial literacy and reduce financial stress | Custom/annual |

**Target customers (credit score):** Tabby, Tamara, إمكان, النايفات, bank credit card divisions
**Target customers (investment referral):** Alinma funds, Tamra, Abyan, Derayah

**Revenue target (credit score line):** 10 partners × 5,000 SAR/month = **50,000 SAR/month**

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

### Phase 4 (Future Plans): Financial Advisor Marketplace

| Stream | Model |
|--------|-------|
| Booking commission | Connect users with licensed human financial advisors/planners for paid 1:1 consultations; Azdal takes a percentage of each booking |

**Status:** Reminder slide for judges — not scoped for build, signals long-term platform ambition beyond AI-only advice.

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

## Pricing Strategy — Freemium B2C + B2B

| Tier | Price | Entitlements |
|------|-------|-------------|
| Tier 1 — Coach (free core) | FREE | Tracking, receipt scan/OCR, chat input, "Can I buy?", goals, Integrity Score |
| Tier 1 — Coach Premium | 49–79 SAR/month | Everything in free core + unlimited AI advisor, predictive planning, advanced monthly PDF reports |
| Add-on — Courses | 29 SAR (distress topics) / 59 SAR (growth topics) | Available to free AND premium users, sold independently |
| Tier 2 — Smart Lender | Murabaha margins only | Loan access + better rates than BNPL |
| Tier 3 — Wealth Builder | Commissions only | Investment routing + wealth tracking |

**Core stays free.** The subscription and course store are upsells on top of a genuinely useful free product — not a paywall on the core value prop. B2B (credit score, corporate wellness) and lending remain the larger long-term revenue engines.

---

## Entitlement Rules

| Feature | Available In | License Required |
|---------|-------------|-----------------|
| Chat + transaction input | Tier 1 (free) | None |
| "Can I buy?" engine | Tier 1 (free) | None |
| Integrity Score | Tier 1 (free) | None |
| Savings goals | Tier 1 (free) | None |
| Unlimited AI advisor + predictive planning | Tier 1 Premium | None |
| Advanced monthly PDF reports | Tier 1 Premium | None |
| Courses | Add-on purchase (any tier) | None |
| Behavioral Credit Score (sold to partners) | B2B (Phase 2) | None (insights) |
| Corporate Wellness | B2B (Phase 2) | None |
| Installment loans | Tier 2 | SAMA Consumer Finance |
| Investment routing | Tier 3 | None (referrals) |
| Advisor Marketplace booking | Phase 4 (future) | None (commission) |

**Rule:** Backend validates ALL entitlement. Client is UX-only. Hackathon MVP build implements only the free Tier 1 entitlements above — Premium/Courses/B2B rows are monetization narrative for the pitch, not build scope for the 9-day sprint.

---

## Business Model Canvas Summary

> **Free-core AI financial coach for Saudi consumers, with a premium subscription and course store for immediate revenue → Behavioral data for credit scoring → Sell insights to BNPL/finance companies and corporates → Become the smart lender.**
>
> المستخدم يدخل مديونًا — ويخرج مستثمرًا.

---

## Related
- `00_product_discovery.md` — Full product vision
- `01_prd.md` — Feature catalog
- `19_financial_model_unit_economics.md` — Detailed unit economics
