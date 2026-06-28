# Azdal — Raw Ideas & Brainstorming

> **Captured:** 2026-05-14 to 2026-05-22
> **Source:** Abdulrahman's voice notes + Colleague discussion + Triple-Agent Brainstorming + Team Session (Saja, Deema, Gemini)

---

## Abdulrahman's Original Thoughts (v1)

- "لما تقول اشتري بوعي انت تقتل المتعه" — Key insight: don't position as restriction
- Most searched-for category: deals/offers (العروض)
- Problem with offers: they feel random, searching is exhausting
- Personal example: "أبغى أتحكم في مصاريفي ولكن يزعجني اني استخدم التطبيق في كل مره"
- Success condition: something that simplifies life without committing to steps
- Friction kills adoption: opening app + typing price + photographing product = too much work
- Available apps for this purpose are many and unused

---

## Abdulrahman's Thoughts (v2)

- Core problem: data acquisition. How to ensure continuous data flow?
- More data categories → better predictions
- Data inputs: income (user), periodic spending (automated), detailed purchases (user + OCR)
- With time + seasonal patterns → superior predictions
- B2B angle: if users provide SKU-level data → massive B2B opportunity
- App form factor: chat interface with AI — like a messaging app

---

## Colleague's Concept (Pre-Saja)

- Smart financial assistant that analyzes BEFORE purchase
- Counter-position to BNPL apps (Tabby, Tamara) that encourage spending
- Helps people buy consciously and avoid debt
- Features: financial awareness score, impulse detection, alternatives, future simulation, "Ask before buying"
- Target: youth, new employees, students, BNPL users
- Business model: premium subscription, bank partnerships, corporate version

---

## Synthesis — Where Visions Merge

| Aspect | Abdulrahman | Colleague | Merged |
|--------|------------|-----------|--------|
| Core problem | Friction kills apps | Overspending/BNPL trap | Both — frictionless + guardrails |
| Input method | Voice, OCR, SMS | Manual entry, bank link | Zero-friction wins |
| Positioning | Don't kill the joy | Buy consciously | "Free your mind" not restrictive |
| Monetization | B2B retail data | Subscriptions | Both — B2C free, B2B paid |
| Form factor | Chat with AI | Feature-rich app | Chat wrapping all features |

---

## Triple-Agent Brainstorming (May 16, 2026)

- Cold Start Intelligence: "Never say no data"
- SMS Bank Parsing: Android auto-read transactions
- Zakat Smart Calculation: Islamic competitive feature
- "Financial Guardian" not "Expense Tracker"
- SAMA Open Banking as future vision
- Flutter GenUI / A2UI for dynamic UI
- Dual LLM Routing: Flash 80%, Pro 20%, DeepSeek fallback

---

---

# TEAM BRAINSTORMING SESSION — May 21, 2026

**Participants:** Abdulrahman, Saja (business/SWOT), Deema (UI design)

---

## Saja's Critical Insights

### 1. BNPL Pain Point
"ناس كثير يشتغلوا مع تابي وتمارا ويشتغلوا الأقساط بدون وعي. لما يجي يدفع ينصدم بالمبلغ اللي عليه."
- This is the core problem: unconscious BNPL accumulation
- User doesn't know their total commitments across providers

### 2. Tracking Without Solution = Failure
"إنت حطيت متابع مالي بس ما حطيت حل للمشكلة... ما حطيت شيء يوقف."
- Critical insight: tracking is not enough. Must INTERVENE.
- Previous hackathon teams failed because they only tracked — didn't solve.

### 3. 3-in-1 Vision
"تطبيق فيه ثلاث أقسام: متابع مالي، تقسيط بحدود، استثمار."
- This birthed the 3-tier system: Coach → Smart Lender → Wealth Builder

### 4. Hackathon Intel (From Past Finals Experience)
"فيه ناس مشاركين نفس الأفكار وما يتأهلون. ليش؟ لأنهم حاطين متابعة للمشكلة فقط — مو حاطين حلول."
"يستهدفون الأشياء اللي تفيد مجتمع كامل. حطوا بعد بطاقة لحال للعائلة."
"ترى مرة يهتمون في النسب والرسوم البيانية."
- Judges want: community impact, statistics, sustainability, clear solution

### 5. Family Finance Experience
Previously built a family finance app for AMAD — reached FINALS. Model: family savings pools for travel, gifts, investment, house.

### 6. Track Selection
Pushed for Financial Education track: "لأن بيعلمه وش يصرف عليه ومبلغ التقسيط"
Abdulrahman agreed: "أشوف انه التعليم. أنت صح."

---

## Deema's Role

- UI/UX Design confirmed
- Asked: "التقسيط بالحد المسموح راح يكون ثابت حسب راتبه ولا يكون real-time؟"
- This question directly influenced the dynamic credit ceiling design

---

## Key Decisions from the Session

1. **Track changed to Financial Education** (was Generative AI for FinTech)
2. **3-tier system locked:** Coach → Smart Lender → Wealth Builder
3. **B2B focus shifted:** From "retail data analytics" to "behavioral credit scoring for BNPL companies"
4. **SAMA concern raised:** If we process installments ourselves, we're treated as a bank
5. **Team locked:** Abdulrahman (AI/Flutter) + Saja (business/SWOT) + Deema (UI)

---

## Gemini Paranoid Architect Session (May 21)

Abdulrahman took the team's brainstorming to Gemini for hostile auditing. Key findings:

### Critical Issues Raised
1. **Behavioral Paradox:** Users who pass Tier 1 don't need loans. Users who need loans won't pass Tier 1.
   - RESPONSE: Smart people still use credit strategically. The market is "wise users" vs "reckless users."
2. **Goodhart's Law:** If users know data entry = credit access, they'll game the system.
   - SOLUTION: Hybrid verification architecture (Open Banking ground truth + cross-validation)
3. **Focus risk:** 3-in-1 app might be scattered. Judges prefer sharp solutions.
   - RESPONSE: Hackathon shows Tier 1 Coach only. Tier 2-3 = vision slides.

### What Was Adopted
- Hybrid verification architecture (Open Banking anchor + AI enrichment + Integrity Score)
- B2B credit insights as Phase 2 revenue (before lending license)
- Behavioral UX design (Silent Triage, Framing Effect, evening check-in timing)

### What Was Rejected
- Abandoning the lending vision entirely. We keep it — but phased (Phase 3, post-license).
- Becoming a pure B2B credit bureau. The vision includes transforming users to investors.

---

## Financial Knowledge Layer (May 22)

Abdulrahman requested building the financial knowledge foundation with academic rigor:
- 23 academic references across behavioral economics, personal finance, and market research
- Debt classification matrix: Good debt (asset-backed) vs Bad debt (consumption)
- 5-phase transformation journey grounded in behavioral science
- Simulation engine: compound interest projections, installment impact, seasonal awareness
- Saudi-specific market layer (SAMA, CMA, PDPL, investment platforms)
- See `Financial Knowledge Layer.md` for full documentation

---

## Key Decision Points (Final)

1. ✅ Zero-friction is non-negotiable. Voice + OCR + SMS. No manual entry.
2. ✅ Chat UI as primary interface.
3. ✅ 3-tier system: Coach → Smart Lender → Wealth Builder.
4. ✅ Phase 1-2-3 model: Coach (free) → B2B credit scoring (revenue) → Smart lending (future).
5. ✅ B2B focus: BNPL companies (Tabby, Tamara) + finance companies — they need behavioral scoring most.
6. ✅ Track: Financial Education.
7. ✅ Hybrid architecture: LLM understands, SQL calculates, GenUI displays.
8. ✅ Cold Start Intelligence: Never say "no data."
9. ✅ Financial Knowledge Layer: All AI decisions grounded in academic references.
10. ✅ Hybrid verification: Open Banking ground truth + AI enrichment + Integrity Score.
11. ✅ Behavioral UX: Silent Triage, Framing Effect, Progress Principle, Hook Model.
12. ⚠️ SAMA license: Needed for Phase 3. Not for hackathon. Not for Phase 2 (insights only).
13. 🔍 Need: Academic financial advisor (Islamic finance specialist).
