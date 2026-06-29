# Azdal — Creative Ideation: The Investor Money Angle

> **Status:** Ideation output — for team review before AMAD pitch
> **Method:** SCAMPER (Bob Eberle, 1971, on Osborn's 1953 checklist) — applied to Azdal's revenue model, not its features
> **Generated:** 2026-06-29
> **Purpose:** Give the judging panel (investors) a credible, fast, defensible answer to the only question they truly ask: *"كيف يكسب التطبيق فلوس؟ ومتى؟"*

---

## How to read this file

The judges are investors. Investors do not score features — they score **the path to revenue and the size of the moat around it**. The current spec answers "how Azdal helps users." This file answers the harder question: **how Azdal turns user behavior into money before Year 3, without waiting for a SAMA license.**

Method discipline: I ran all 7 SCAMPER operators internally. Most produced slop and were discarded. The obvious ideas I **refused** are listed first so the team knows what *not* to pitch. Then the survivors, each with a concrete mechanism, a revenue number, and an honest failure mode.

---

## Ideas refused (the slop the judges have heard 100 times)

A pitch that contains these reads as average. Do not say them:

1. ❌ **"Premium subscription tier"** — contradicts the "free forever" moat and signals you don't trust the B2B engine. Investors see a SaaS clone.
2. ❌ **"We'll sell ads / sponsored offers"** — destroys the trust moat (an app that prevents bad spending cannot be paid to encourage spending). Judges will catch the contradiction instantly.
3. ❌ **"AI-powered financial wellness platform"** — two trending nouns, zero mechanism. This is the exact sentence every other team will say.
4. ❌ **"Marketplace connecting users to lenders"** — a two-sided-marketplace pitch shape from 2014; needs both sides at scale before earning a riyal.
5. ❌ **"Cashback / rewards points"** — encourages spending, capital-intensive, and a solved commodity (every bank app does it).

---

## The survivors — 7 ideas, ordered by how fast they make money

### 1. 🟢 GROUNDED — "The Default Insurance" pre-purchase API (Substitute + Put-to-other-uses)

**The move:** Instead of selling a *static behavioral credit score* (Phase 2, the slow path that needs partner integration cycles), sell a single live API call at the **moment of purchase decision** — the same "Can I Buy?" engine you already built for users, exposed to the lender as a real-time **transaction-level approval signal**.

**Mechanism:** Tabby's checkout fires a query: *"User X wants 800 SAR, 4 installments."* Azdal answers in <300ms: `APPROVE / HOLD / DECLINE` + one-line reason ("user is 73% through monthly income, 6 days to salary, two active commitments"). This is not a credit score (which is regulated and static) — it's an **affordability verdict on one cart, right now.** The user already gets this verdict for free; you're charging the lender for the same compute.

**Why it makes money fast:** Per-decision pricing, not per-month. At 0.50 SAR/call and 90% margin, a single mid-size BNPL doing 200K decisions/month = **100,000 SAR/month from one partner.** And you can demo it live at the hackathon with a mock lender — judges *see* revenue, they don't imagine it.

**Failure mode:** Lenders may treat it as "nice-to-have" unless you prove default reduction. Mitigation: pitch it as a free 90-day pilot where you only get paid on the loans your DECLINE signal would have saved. You take the downside risk — investors love a founder who bets on their own model.

**First step (buildable in the 9-day sprint):** A single REST endpoint `POST /affordability-check` that wraps the existing "Can I buy?" logic and returns a verdict JSON. One screen in the demo shows "Tabby's view" of an Azdal user.

---

### 2. "Pay-on-Saved" — the revenue model that needs no one's permission (Reverse)

**The move:** Reverse who pays and when. Today: B2C is free, B2B pays later. Instead: the **user pays Azdal a small cut of money Azdal provably saved them** — but only *after* the saving is realized, deposited into their own goal.

**Mechanism:** When the "Can I Buy?" engine says WAIT and the user complies, and that 800 SAR lands in their emergency-fund goal at month-end, Azdal takes **3% of the verified saving (24 SAR)** as a success fee — opt-in, transparent, framed as "tip your shield." This is success-based pricing: the user only pays when richer. Behaviorally it's the Progress Principle (Amabile) monetized — paying *feels* like winning because it's a fraction of a win.

**Why it makes money fast:** B2C revenue from Day 1, no SAMA license, no B2B sales cycle. If 1,000 active users save and route 500 SAR/month each → 500K SAR saved → **15,000 SAR/month at 3%** from a 1K user base. That breaks the "negative margin until Year 3" story that scares investors.

**Failure mode:** "Verified saving" is hard to attribute — did Azdal cause it, or would they have saved anyway? Counterfactual is fuzzy. Mitigation: only charge on savings that flowed through a WAIT/DECLINE the user explicitly accepted in-app (clear causal chain, logged). Conservative attribution protects trust.

---

### 3. "Salary-Day Liquidity" — earn the float, not the loan (Eliminate the license)

**The move:** Eliminate the part of lending that needs the SAMA license (you holding the credit risk) while keeping the part that earns. Azdal doesn't lend — it **brokers a 5-day bridge** between a partner bank's idle liquidity and a Tier-1 user the model has already cleared.

**Mechanism:** A user with a 95 Integrity Score hits a 400 SAR gap 4 days before salary. Azdal doesn't lend; it routes a pre-cleared micro-advance from a *licensed* partner (e.g. a bank's existing consumer-finance arm) and takes an **origination/scoring fee** for delivering a borrower with a measured 2% default probability instead of the market's 18%. The bank holds the license and the risk; Azdal holds the signal and the fee.

**Why it makes money:** This is Phase 3 revenue (lending margins) pulled forward to Phase 1, because you're the *scoring layer*, not the lender. Fee of 15 SAR per cleared advance × 2,000 advances/month = **30,000 SAR/month.**

**Failure mode:** You need one licensed partner to say yes, which is a sales dependency. Mitigation: this is a *vision slide* for the hackathon (clearly labeled "post-pilot"), not a demo claim. Investors reward a credible bridge between free Tier-1 and licensed Tier-2.

---

### 4. "The Anti-Score" — sell the data lenders are legally forbidden to collect (Put-to-other-uses)

**The move:** Banks see "Carrefour — 350 SAR." Azdal sees "milk, diapers, no cigarettes, no late-night impulse buys." Repurpose the *granularity* itself — not as a credit score, but as a **stability signal** for products that aren't loans: takaful (Islamic insurance) pricing, and rental/employer trust checks.

**Mechanism:** An insurer pricing auto-takaful for a 26-year-old has almost no behavioral signal today. Azdal sells an opt-in, user-consented **"financial stability index"** (0–100, no raw transactions ever leave) that correlates with claim/default risk. The user clicks "share my stability index with [insurer]" to get a lower premium — the user *wants* to share because it saves them money.

**Why it's a moat, not just revenue:** This is a market *no MENA competitor touches* and it sidesteps SAMA's lending perimeter entirely (insurance and tenancy are different regulators). It also makes the data engine multi-buyer — the same signal sells to lenders, insurers, and landlords.

**Failure mode:** PDPL/consent is the whole game — one privacy misstep kills the trust moat. Mitigation: the index is computed on-device or in-enclave; only the *number* and the *user's explicit per-recipient consent* ever transmit. Build the consent ledger before the index.

---

### 5. "White-Label Shield" — license the engine to the people who fear you (Combine + Substitute)

**The move:** Combine Azdal's behavioral engine with the distribution of the banks who would otherwise build a competitor. Instead of fighting Alinma/Al Rajhi for users, **license the "Spend Aware" coach as a white-label module inside their apps.**

**Mechanism:** A bank embeds Azdal's "Can I Buy?" + Integrity Score as a screen in their own app, branded as theirs, paying Azdal a **per-active-user SaaS fee (2–4 SAR/MAU/month).** The bank gets retention and lower default; Azdal gets distribution to millions without spending on CAC.

**Why it makes money at scale:** One bank with 500K active users at 3 SAR = **1.5M SAR/month.** This is the "boring" enterprise line that makes the financial model bankable — investors love a B2B2C SaaS line with a fixed per-seat price.

**Failure mode:** Long enterprise sales cycle (6–18 months) and risk of the bank cloning you after a pilot. Mitigation: keep the *behavioral model weights and the Integrity-gaming defenses* as the proprietary core they can't easily rebuild; license the UI, never the model.

---

### 6. "Zakat & Goal Round-Up Float" — monetize patience, not interest (Modify/Minify)

**The move:** Minify the unit of money to the riyal level. Round every transaction up to the nearest 5 SAR, sweep the difference into the user's goal — and Azdal earns the **float and the partner fee** on aggregated micro-savings, including an auto-Zakat calculation layer.

**Mechanism:** 47.50 SAR coffee → 50 SAR charged, 2.50 SAR to the emergency fund. Aggregated across users, this micro-capital sits in a partner Islamic savings/sukuk vehicle; Azdal earns a referral/management share (Phase 4 logic) **without anyone consciously investing.** The Zakat layer auto-computes the 2.5% obligation on held wealth — a uniquely Saudi feature that no Western app (Cleo, Origin) can copy, and it deepens trust (religious alignment) while creating a natural reason to know the user's total balance.

**Why it fits Azdal specifically:** Round-up is a known mechanic; the **Zakat automation is the non-obvious, un-clonable, culturally-native twist.** It turns a commodity feature into a moat.

**Failure mode:** Round-up alone is commoditized and low-margin; without the Zakat + Islamic-vehicle wrapper it's slop. Don't pitch the round-up — pitch the Zakat-aware wealth float.

---

### 7. "The Honesty Bounty" — turn the Integrity Score into a B2B currency (Reverse)

**The move:** Reverse the data relationship. Today Azdal *measures* user honesty to gate Tier 2. Instead, let **users sell verified honesty as a tradable trust certificate** to any institution that needs to de-risk them.

**Mechanism:** A user with a 90+ Integrity Score earned over 6 months holds a cryptographically signed, time-stamped **"Azdal Verified" badge.** A landlord, a car-leasing company, or an employer's payroll-advance program can request verification (user consents per-request); Azdal charges the *requesting institution* a verification fee (10–25 SAR/check). The user's good behavior becomes their own portable asset — and the moat is that the score is *non-fakeable* (it's validated against Open Banking ground truth, with anti-gaming penalties already specced).

**Why it's the deepest moat:** It makes Azdal infrastructure, not an app — the "credit bureau of behavior" for the un-scored. The Integrity Score stops being an internal gate and becomes a **market-priced signal** with network effects (more requesters → more user incentive to keep the score high → more data → better signal).

**Failure mode:** Chicken-and-egg — needs both a base of high-score users *and* institutions willing to query. Mitigation: bootstrap with one tenancy or employer-advance partner where the pain (no signal on young, thin-file Saudis) is acute. This is a Year-2 vision slide, not a demo — but it's the line that makes an investor think "category-defining," not "feature."

---

## The one-slide answer for the judges

If Saja has 30 seconds to answer *"how do you make money?"*, the sequence is:

> **"We make money three ways, on three timelines — and the first one earns from Day 1, with no license:**
> 1. **Now (B2C, no license):** users pay a 3% success fee on money we provably help them save — we only earn when they get richer.
> 2. **Year 1 (B2B, no license):** lenders pay us per real-time affordability verdict — we cut their defaults; we get paid per decision, 90% margin.
> 3. **Year 2+ (infrastructure):** our Integrity Score becomes a portable, sellable trust certificate — insurers, landlords, and lenders pay to verify the un-scored.
>
> **We are not waiting for a SAMA license to be profitable. We are the scoring layer everyone else needs — and the only one in MENA reading behavior, not just salary."**

---

## What to actually build for the demo (9-day sprint priority)

| Idea | Demo-able in sprint? | What to show |
|------|---------------------|--------------|
| #1 Affordability API | ✅ Yes — wrap existing engine | A "lender's view" screen + live verdict JSON |
| #2 Pay-on-Saved | ✅ Yes — UI only | A "tip your shield" card after a successful WAIT |
| #6 Zakat round-up | 🟡 Partial — calc layer | Auto-Zakat number on the goals screen |
| #3, #4, #5, #7 | ❌ Vision slides | One clean diagram each in the deck |

**Rule:** Demo the two that are buildable (#1, #2) as *working software* — investors believe what they can tap. Pitch the other five as the *revenue roadmap* — investors fund a roadmap, not a feature.

---

## Method note & attribution

Generated with **SCAMPER** (Bob Eberle, 1971; built on Alex Osborn's *Applied Imagination*, 1953). The strongest cells were **Reverse** (#2, #7), **Eliminate-the-license** (#3), and **Put-to-other-uses** (#1, #4) — consistent with the method's known behavior that Eliminate and Reverse yield the least-obvious results. Five obvious operator outputs (premium tier, ads, cashback, generic marketplace, "AI wellness") were generated and discarded as slop per the anti-slop discipline. Each surviving idea carries a concrete mechanism, a revenue figure, and a named failure mode — because an idea without a stated failure mode is one no one has thought hard about.
