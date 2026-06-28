# Azdal — Porter's Five Forces Analysis

> **Date:** 2026-05-19
> **Purpose:** Competitive environment analysis for Saudi AI-powered personal finance app

---

## 1. Threat of New Entrants — 🟡 MEDIUM

| Factor | Rating | Explanation |
|--------|--------|-------------|
| **Capital requirements** | Low | Flutter app + Supabase + Gemini API = low initial cost. A competitor could start with $500. |
| **Technical barriers** | Medium-High | Arabic NLP + "Can I buy?" engine + guardrails + prompt engineering + state machine = significant technical depth. UI alone is easy to copy. The behavior is hard. |
| **Regulatory barriers** | Low (MVP) / High (Full product) | No license needed for MVP. But SAMA Open Banking licensing creates a moat later. |
| **Brand/trust** | Medium | Financial apps need user trust. First-mover in Arabic AI finance has branding advantage. |
| **Network effects** | Medium | More users → better B2B data → more revenue → better features. But not a "winner takes all" market. |
| **Access to distribution** | Low | Google Play and App Store are open. No exclusive channels needed. |

**Verdict:** A competitor can build a similar-looking app quickly. But replicating the Arabic NLP quality, guardrails, and "Can I buy?" decision engine is hard. **First-mover window: 12-18 months.**

---

## 2. Bargaining Power of Buyers (Users) — 🔴 HIGH

| Factor | Rating | Explanation |
|--------|--------|-------------|
| **Low switching costs** | Very High | Users can switch between finance apps with zero cost. This is why 77% abandon in 3 days. |
| **Price sensitivity** | High | Saudi users expect free apps. YNAB's $14.99/month would fail here. B2C must be free. |
| **Many alternatives** | High | Bank apps, spreadsheets, paper, mental tracking — all are "competitors" to adopting a new app. |
| **User concentration** | Low | Millions of potential users. No single user has leverage. |
| **Product differentiation** | High (our advantage) | Arabic AI + "Can I buy?" + zero-friction = genuinely different. This reduces buyer power over time as users get attached. |

**Verdict:** Users can leave instantly. Retention is THE challenge. Our moat: make the app so effortless they don't want to leave. Guest-first + conversational UI = sticky. **Monetize B2B, not B2C.**

---

## 3. Bargaining Power of Suppliers — 🟢 LOW

| Factor | Rating | Explanation |
|--------|--------|-------------|
| **Gemini API dependency** | Low-Medium | Primary supplier. But: Flash is cheap, DeepSeek V3 is a 5x cheaper fallback. Multiple LLM options exist. No single-vendor lock-in. |
| **Supabase dependency** | Low | Open source, multiple providers. Can self-host PostgreSQL. No lock-in. |
| **Flutter/Google dependency** | Low | Flutter is open source. If GenUI fails, native widgets work. |
| **Apple/Google App Store** | Low | 15-30% commission on subscriptions only. Free B2C app = no commission. |
| **Talent supply** | Medium | Flutter developers available. Arabic AI prompt engineers are rare but not needed — we use Gemini API. |

**Verdict:** Suppliers have almost no power over us. Every critical dependency has a fallback. Multi-vendor strategy is built-in.

---

## 4. Threat of Substitutes — 🔴 HIGH

| Substitute | Threat Level | Why Users Choose It |
|-----------|-------------|---------------------|
| **Bank apps (الراجحي, الأهلي)** | Medium | Already installed. Show transactions. But no AI, no decisions, no "Can I buy?" |
| **Spreadsheets / Notes** | Medium | Free, private, familiar. But manual, no insights, no OCR. |
| **Mental tracking / nothing** | Very High | The #1 competitor. 80% of people don't track spending at all. This is the real enemy. |
| **Dosh** | Low | Cashback only. Not expense tracking. |
| **YNAB** | Low | English only, $14.99/month, complex. Not a Saudi market threat. |
| **Cleo/Origin** | Low (now) / Medium (future) | English only now. If they Arabic-localize: becomes a real threat. |
| **Financial advisors** | Low | Expensive, not for mass market. Different segment. |
| **BNPL apps (Tabby/Tamara)** | Low | They encourage spending. We prevent bad spending. Different value proposition. |

**Verdict:** The #1 substitute is "doing nothing." 80% of people don't track spending. **This is actually an opportunity — the market is untapped, not saturated.** We're not competing with YNAB. We're competing with "I don't care enough to track."

---

## 5. Industry Rivalry — 🟡 MEDIUM (Global) / 🟢 LOW (Saudi Arabic)

| Factor | Rating | Explanation |
|--------|--------|-------------|
| **Number of competitors** | High (Global) / Very Low (Arabic) | Globally: YNAB, Monarch, Rocket Money, Cleo, Origin, PocketGuard, Money Manager, 50+ apps. In Saudi Arabic AI: ZERO. |
| **Industry growth** | High (20% CAGR) | Growing market = room for everyone. Less zero-sum competition. |
| **Differentiation** | High (our advantage) | Arabic AI + "Can I buy?" + guest-first = highly differentiated in global context. In Saudi context: completely unique. |
| **Exit barriers** | Low | If we fail, Flutter code + Supabase schema = reusable for other projects. Low sunk cost. |
| **Competitor diversity** | Medium | Ranges from basic manual trackers to AI agents. We're in the AI agent category — the smallest, most innovative segment. |

**Verdict:** In the Saudi market, rivalry is near ZERO for our specific offering (Arabic AI expense agent). Globally, the market is competitive but growing. **Our blue ocean: Saudi Arabia + Arabic + AI.**

---

## Porter's Five Forces — Summary Diagram

```
THREAT OF NEW ENTRANTS: 🟡 MEDIUM
  Easy to copy UI, hard to copy behavior
         │
         ▼
SUPPLIER POWER: 🟢 LOW ←── INDUSTRY RIVALRY ──→ BUYER POWER: 🔴 HIGH
  No vendor lock-in          🟢 LOW (KSA)         Users leave fast
  Multi-model fallback       🟡 MED (Global)       Must be free & sticky
                                          │
                                          ▼
                             THREAT OF SUBSTITUTES: 🔴 HIGH
                               #1 competitor = "doing nothing"
                               But: 80% untapped = opportunity
```

---

## Strategic Positioning from Porter

1. **Defend against buyer power:** Make the app so frictionless that switching feels like work. Guest-first = no barrier to start. Chat = no learning curve.

2. **Exploit low rivalry in KSA:** Move fast. First to market in Arabic AI finance. Lock in users before Cleo/Origin localize.

3. **Build moat against new entrants:** Arabic prompt engineering + guardrails + "Can I buy?" calculator = technical depth that takes months to replicate. UI is not the moat.

4. **Neutralize substitutes:** "Doing nothing" is the real competitor. Our value prop: "Azdal takes less effort than doing nothing — and gives you peace of mind."

5. **Keep supplier power low:** Already done. Gemini Flash + DeepSeek fallback + native Flutter Plan B = no single point of dependency failure.
