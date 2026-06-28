# Azdal — Business Model Canvas (BMC)

> **Date:** 2026-05-22 (Updated — BNPL credit scoring focus)
> **Purpose:** Complete business model for hackathon + post-hackathon phases

---

## The Canvas

```
┌─────────────────────┬─────────────────────┬─────────────────────┐
│ KEY PARTNERS        │ KEY ACTIVITIES       │ VALUE PROPOSITION   │
│                     │                     │                     │
│ • Google (Gemini)   │ • AI coach dev       │ "أول برنامج تأهيل    │
│ • Supabase          │ • Arabic NLP tuning  │  مالي متدرج"        │
│ • SAMA (Phase 2-3)  │ • Behavioral scoring │                     │
│ • Saudi banks       │   engine             │ ٣ مراحل:            │
│   (Open Banking)    │ • Integrity Score     │ مستشار → مقرض واعي  │
│ • BNPL companies    │ • Financial rules    │ → مستثمر            │
│   (Tabby, Tamara)   │   engine              │                     │
│ • Finance companies │ • User testing       │ الوحيد اللي:        │
│   (إمكان, النايفات)  │                     │ • يفهم عاميتك       │
│ • Investment platforms│ KEY RESOURCES       │ • يقرأ فواتيرك      │
│   (Alinma, Tamra)   │                     │ • يمنع الشراء السيء  │
│                     │ • Gemini API keys    │ • يقرضك بوعي        │
│                     │ • Flutter codebase   │ • يستثمر لك         │
│                     │ • Supabase DB        │                     │
│                     │ • Financial Knowledge│ بدون تعب.            │
│                     │   Layer (23 refs)    │ بدون إدخال بيانات.  │
│                     │ • Domain expertise   │                     │
│                     │   (17yr Saudi Energy)│                     │
├─────────────────────┴─────────────────────┴─────────────────────┤
│ CUSTOMER RELATIONSHIPS       │ CUSTOMER SEGMENTS                │
│                              │                                  │
│ • Chat-based (primary)       │ B2C:                             │
│ • Behavioral UX — Hook Model │ • Saudi employees 22-35          │
│ • Proactive (evening check-in)│ • Income 5K-15K SAR              │
│ • Self-service onboarding    │ • No savings, BNPL users         │
│ • Trust via Islamic branding │ • Arabic-first, tech-savvy       │
│ • Community (X/Telegram)     │                                  │
│                              │ B2B (Phase 2):                   │
│                              │ • BNPL companies (Tabby, Tamara) │
├──────────────────────────────┤ • Finance companies (إمكان)       │
│ CHANNELS                     │ • Bank credit card divisions     │
│                              │ • Investment platforms           │
│ • App Store / Google Play    │                                  │
│ • X.com (organic)            │                                  │
│ • Word of mouth              │                                  │
│ • Hackathon visibility       │                                  │
│ • FinTech Saudi network      │                                  │
├──────────────────────────────┴──────────────────────────────────┤
│ COST STRUCTURE                         │ REVENUE STREAMS         │
│                                        │                        │
│ • Gemini API: ~$1.50/user/month        │ PHASE 1: Coach         │
│ • Supabase: Free → $25/month           │ • B2C: FREE            │
│ • Apple/Google: 0% (free app)          │                        │
│ • Development: Solo/small team         │ PHASE 2: B2B Insights  │
│ • Marketing: Organic X + hackathon     │ • Behavioral Credit    │
│ • Total MVP burn: ~$50-100/month       │   Score API per query  │
│                                        │ • Monthly subscription │
│                                        │   for lending partners │
│                                        │                        │
│                                        │ PHASE 3: Smart Lender  │
│                                        │ • Murabaha margins     │
│                                        │                        │
│                                        │ PHASE 4: Wealth        │
│                                        │ • Investment referral  │
│                                        │   commissions          │
└────────────────────────────────────────┴────────────────────────┘
```

---

## 1. Customer Segments

### Primary B2C — "The Disappearing Salary"

| Attribute | Profile |
|-----------|---------|
| Age | 22-35 |
| Income | 5,000 - 15,000 SAR/month |
| Location | Saudi Arabia (urban) |
| Pain point | Salary disappears. BNPL debt accumulating unconsciously. No savings. |
| Current solution | Nothing effective. Maybe bank app. |
| Why Azdal? | First app that prevents bad spending before it happens — in Arabic. |

### Primary B2B (Phase 2) — BNPL & Finance Companies

| Segment | Why Azdal? | Urgency |
|---------|-------------|---------|
| **Tabby, Tamara** | No salary assignment. Need behavioral screening to reduce defaults. | HIGH — SAMA tightening regulations |
| **Finance companies (إمكان, النايفات)** | Same problem — lend without full financial picture | HIGH |
| **Bank credit card divisions** | Credit cards have highest NPL. Behavioral scoring reduces risk. | MEDIUM |
| **Investment platforms (Tamra, Abyan)** | Want qualified investors. Azdal identifies users with surplus. | MEDIUM |

---

## 2. Value Proposition

### B2C — The Transformation Promise

| Stage | What User Gets |
|-------|---------------|
| Day 1 | Instant insight: "73% of your income gone before mid-month." |
| Month 1-3 | Stabilization: spending under control. First surplus. |
| Month 3-6 | Awareness: patterns revealed. First savings goal. |
| Month 6-12 | Liberation: bad debt repaid. Integrity Score rising. |
| Month 12-18 | Growth: first investment made. Gold tier. |
| Month 18+ | Freedom: auto-investing. Wealth tracking. |

### B2B — The Behavioral Credit Score

| For BNPL Companies | Value |
|-------------------|-------|
| Before Azdal | Approve based on salary + SIMAH only |
| After Azdal | Approve based on salary + SIMAH + ACTUAL SPENDING BEHAVIOR |
| Result | Lower default rates. SAMA compliance. Better portfolio quality. |

---

## 3. Revenue Streams (Phased)

### Phase 1: Hackathon MVP — Free
No revenue. Focus = validation + winning.

### Phase 2: B2B Behavioral Credit Insights (Year 1-2)

| Stream | Model | Price |
|--------|-------|-------|
| **API per query** | BNPL company queries score before approving loan | 5-15 SAR/query |
| **Monthly subscription** | Up to 1,000 queries/month | 5,000 SAR/month |
| **Enterprise** | Unlimited queries + dashboard | Custom |

Target: 10 BNPL/finance partners × 5,000 SAR/month = 50,000 SAR/month.

### Phase 3: Smart Lending (Year 3+)

| Stream | Model |
|--------|-------|
| Murabaha margins | Islamic installment financing to Tier 2 users |
| Lower default rate → higher effective margin than competitors |

### Phase 4: Investment Referrals (Year 3+)

| Stream | Model |
|--------|-------|
| Referral commission | Route users with surplus to investment platforms |
| Per-user fee | Partners pay for qualified investor leads |

---

## 4. Cost Structure

### MVP (Hackathon)

| Item | Monthly |
|------|---------|
| Gemini Flash API | $10-30 |
| Supabase (free tier) | $0 |
| Apple Developer | $8.25 |
| **Total** | **~$50/month** |

### At Scale (10K users)

| Item | Monthly |
|------|---------|
| Gemini Flash API | $1,200 |
| Supabase Pro | $25 |
| **Total** | **~$1,500/month** |

Key insight: ONE B2B client at 5,000 SAR/month covers all costs.

---

## 5. Key Resources

| Resource | Critical? |
|----------|-----------|
| Gemini API (Flash + Vision) | ✅ Core AI brain |
| Flutter codebase | ✅ Mobile app |
| Financial Knowledge Layer | ✅ AI decision foundation (23 refs) |
| Behavioral Credit Scoring Engine | ✅ B2B product |
| Integrity Score Algorithm | ✅ Anti-gaming protection |
| Supabase DB | ✅ Data storage |
| Domain expertise (17yr Saudi Energy) | ✅ Founder advantage |

---

## 6. Key Partners

| Partner | Phase | Role |
|---------|-------|------|
| Google (Gemini) | MVP → | AI provider |
| Supabase | MVP → | Backend |
| SAMA | Phase 2 | Open Banking data |
| BNPL companies | Phase 2 | Credit score customers |
| Finance companies | Phase 2 | Credit score customers |
| Investment platforms | Phase 3 | Referral partners |
| FinTech Saudi | Post-hackathon | Accelerator, funding |

---

## BMC Summary

> **Free AI financial coach for Saudi consumers → Behavioral data for credit scoring → Sell insights to BNPL/finance companies → Become the smart lender.**
>
> **المستخدم يدخل مديونًا — ويخرج مستثمرًا.**
