# Azdal — Product Requirements Document (PRD)

> **Status:** Locked — Pre-Implementation  
> **Stage:** Stage 0  
> **Hackathon MVP:** Tier 1 Coach ONLY  
> **Source:** Synthesized from `docs/archive/product-behavior-original.md` and `docs/archive/raw-ideas-brainstorming.md`

---

## Core Principle

**Azdal is not a tracking app. It's a financial transformation platform.**

It doesn't just record what happened. It takes you from debt to wealth — through behavioral science, AI, and a proven 3-tier progression system.

---

## PART 1: THE 3-TIER TRANSFORMATION SYSTEM

### Tier 1 — Coach (المستشار الذكي)

**License:** None required  
**Revenue:** Free (growth phase)

| Capability | Description |
|------------|-------------|
| AI watches behavior | Auto-classify, advise, prevent bad spending |
| Zero-friction tracking | Voice, OCR, chat — no manual entry |
| "Can I buy?" engine | Pre-purchase simulation before every buy decision |
| Commitment tracking | BNPL installments, recurring bills |
| Savings goals | Set goals, gap detection, progress tracking |
| Integrity Score | Transparency metric — how honest is user with system |
| Cold Start Intelligence | Never say "no data" — give value from first interaction |

**Gateway to Tier 2:** User must pass behavioral test:
- 3+ months consistent transaction logging
- Integrity Score above threshold (minimal gap between system data and user input)
- Spending patterns show improvement
- At least 1 savings goal in progress

### Tier 2 — Smart Lender (المُقرِض الواعي)

**License:** SAMA Consumer Finance License required

| Capability | Description |
|------------|-------------|
| Islamic Murabaha loans | Installment financing for qualified users |
| Behavior-based approval | Salary + behavioral data — not salary alone |
| Dynamic credit ceiling | Adjusts based on real-time spending behavior |
| AI monitoring | Behavior degrades → ceiling drops. Improves → rises |
| Better terms than BNPL | Lower risk = better rates for users |

**Gateway to Tier 3:** All bad debt repaid + first savings goal achieved + surplus detected

### Tier 3 — Wealth Builder (باني الثروة)

**License:** None (partnerships only)

| Capability | Description |
|------------|-------------|
| Surplus detection | AI identifies investable monthly excess |
| Investment routing | Match to partner platforms (Alinma, Tamra, Abyan) |
| Wealth tracking | Net worth dashboard alongside spending |
| Revenue | Referral commissions from investment platforms |

---

## PART 2: THE 5-PHASE TRANSFORMATION JOURNEY

### Phase 0 — The Wake-Up Call (الصدمة)
- **Duration:** First 5 minutes
- **No registration.** No forms. Just chat.
- 3 questions: Income, commitments, approximate spend
- Instant insight: "You spend 73% of your income before mid-month."
- CTA: "خليني أساعدك. سجل أول عملية — بالصوت أو الصورة."

### Phase 1 — Stabilization (الاستقرار)
- **Duration:** Months 1-3
- **Goal:** Stop the bleeding
- Silent triage: Routine transactions auto-classified — no interruption
- Smart intervention: Only for "gray" and "red" transactions
- Evening check-in: ONE message at 9 PM
- Weekly small wins: "هذا الأسبوع وفرت ٢٠٠ ريال"
- Zero investment talk

### Phase 2 — Awareness (الوعي)
- **Duration:** Months 3-6
- **Goal:** See the big picture
- Pattern reveals: "You spend 40% on restaurants and coffee."
- Smart alternatives: "Buy a coffee machine — recover cost in 7 weeks."
- First small goal: "Let's save 500 SAR for emergency fund."
- Integrity Score visible — gamified progress

### Phase 3 — Liberation (التحرر)
- **Duration:** Months 6-12
- **Goal:** Exit bad debt. Build first savings.
- Debt Avalanche: AI prioritizes high-interest debt
- Silver Tier promotion
- First 1,000 SAR emergency fund
- First soft investment mention

### Phase 4 — Growth (النمو)
- **Duration:** Months 12-18
- **Goal:** First investment
- Surplus confirmation: 3+ consecutive months with surplus
- First investment: 500 SAR — symbolic
- Gold Tier promotion
- Good debt only (mortgage, education, business)

### Phase 5 — Freedom (الحرية)
- **Duration:** Month 18+
- **Goal:** Financial independence
- Auto-invest surplus
- Net worth dashboard
- AI role shifts from "financial doctor" to "wealth coach"
- Platinum Tier

---

## PART 3: CORE BEHAVIORS

### 1. Compound Transaction Detection
- **Input:** "اشتريت بـ ٤٧٥ — قهوة وخضار ومطعم للعيال"
- **Output:** 3 categorized transactions with shared group_id
- **UI:** Compound split card with +/- adjusters per line

### 2. Recurring Commitment Intelligence
- **Input:** "عندي تمارا ١٠٠٠ ياخذون ٢٠٠ كل شهر"
- **Output:** Track remaining, auto-include in "Can I buy?", celebrate payoff
- **Detection:** Inference from SMS parsing or user declaration

### 3. "Can I Buy?" — Purchase Decision Engine
- **Inputs:** Income + commitments + current spend + days to salary + active goals
- **Output:** YES ✅ / WAIT ⚠️ / NO ❌ with explanation + alternatives
- **Example:** "إذا اشتريت الآن → هدفك يتأخر 8 أشهر. إذا أجلت → توصل أسرع."

### 4. Cold Start Intelligence
- **Rule:** Never say "no data"
- **Strategy:** Use income brackets, general estimates, confidence levels
- **Output:** "بناءً على دخلك المقدر وتاريخك — أنت في المسار الصحيح."
- **Evolution:** As user adds data, become more precise and confident

### 5. Gap Detection (Data vs Reality)
- **Trigger:** User says "ما يبقى معي شيء" but data shows surplus
- **Response:** Humble approach — 3 gap-filling questions
- **Real recalculation:** Adjust estimates based on user feedback

---

## PART 4: INTEGRITY SCORE

| Factor | Weight | How Measured |
|--------|--------|-------------|
| Logging Consistency | 30% | Days with transaction / total days |
| Receipt Upload Rate | 20% | Receipts uploaded vs gray transactions |
| Data Match Accuracy | 25% | User input vs Open Banking ground truth |
| Response Time | 15% | Speed of evening check-in response |
| No Deletion Rate | 10% | Transactions not later deleted |

| Score Range | Effect |
|------------|--------|
| 90-100 | Platinum. Tier 2 unlocked. |
| 70-89 | Good. Tier 2 in progress. |
| 50-69 | Moderate. Tier 2 delayed. |
| Below 50 | Low trust. Tier 2 locked. |

**Anti-gaming:** If user claims "50 SAR" but Open Banking shows "500 SAR" → penalty. Integrity is NEVER the only factor.

---

## PART 5: BEHAVIORAL UX FRAMEWORK

### The Silent Triage Protocol

| Type | Examples | AI Action |
|------|----------|-----------|
| Green (Routine) | Gas 200, Electricity 350, Supermarket 300-500 | Auto-classify. Silent. No notification. |
| Gray (Ambiguous) | Jarir 800, Extra 1200 | Flag for evening check-in. Frame as opportunity. |
| Red (Impulse) | Multiple purchases/2hr, late-night, new store high amount | Immediate notification: "يبدو أنك تشتري بشكل اندفاعي اليوم." |

### The Framing Effect

| Wrong | Right |
|-------|-------|
| "تم خصم 800 ريال. الرجاء إدخال تفاصيل الفاتورة." | "بطل! عملية بـ 800 ريال. إذا كانت 'دورة تدريبية' — تراها ترفع مؤشر جدارتك." |
| "أنت صرفت كثير هذا الأسبوع." | "مصاريفك هذا الأسبوع أعلى من المعتاد بـ 15%. تبي نشوف ليش؟" |
| "لا تشتري هذا." | "إذا اشتريت الآن → هدفك يتأخر 8 أشهر. إذا أجلت → توصل أسرع. الخيار لك." |

### The Hook Model

| Element | Implementation |
|---------|---------------|
| External Trigger | Bank notification → Azdal asks for context |
| Action | Voice response (3 seconds) |
| Variable Reward | Integrity Score changes, tier progress, insight revealed |
| Investment | Goals, linked accounts, history — sunk cost deepens |

---

## Hackathon MVP Scope

### BUILD (Tier 1 Complete)
- [x] Conversational chat with AI (Arabic)
- [x] Voice + OCR transaction input
- [x] "Can I buy?" purchase simulation engine
- [x] Commitment tracking (BNPL installments)
- [x] Savings goals with gap detection
- [x] Integrity Score tracker
- [x] Cold Start Intelligence
- [x] Tier 2 gateway simulation

### DO NOT BUILD
- ❌ Real bank integration
- ❌ Actual lending/installment processing
- ❌ B2B API
- ❌ SMS parsing (Android only)
- ❌ Investment routing

---

## What Azdal Is vs What It Isn't

| NOT This | THIS |
|----------|------|
| Expense tracker | Financial transformation platform |
| Manual data entry | Voice, OCR, chat — zero friction |
| Post-spend reports | Pre-spend prevention |
| Fixed categories | AI classification + user refinement |
| Dumb lender (Tabby) | Smart lender — behavior-based |
| App abandoned in 3 days | App that improves life over 18 months |

---

## Academic Foundation

Built on: BJ Fogg (B=MAP), Nir Eyal (Hook Model), Teresa Amabile (Progress Principle), Kahneman & Tversky (Prospect Theory), Richard Thaler (Mental Accounting), Robert Cialdini (Commitment & Consistency), James Clear (Atomic Habits).

Full references: `docs/research/financial-knowledge-layer.md`

---

## Related
- `00_product_discovery.md` — Product vision and competitive moat
- `02_monetization_entitlements.md` — Revenue model
- `03_user_flows_navigation.md` — UX flows and widget catalog
- `07_flutter_architecture.md` — Technical architecture
