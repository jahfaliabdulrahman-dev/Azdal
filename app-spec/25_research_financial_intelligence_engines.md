# Research — Financial-Intelligence Engines

> **Provenance.** A Fable-model deep-design consult (2026-07-19): habit/consumption
> detection, unit economics, the payoff-vs-invest decision, and the safe advice
> line. Grounded in repo reads (`purchase_decision_service.dart`,
> `transaction_service.dart`, `commitment_service.dart`, `gemini_service.dart`,
> DEC-050/024/026, doc 20, `docs/research/financial-knowledge-layer.md`) and
> current web sources. URLs inline; unverified items marked **[UNVERIFIED]**.
> Acceptance target = doc 20 examples 1, 3, 4.

## What the repo verified first

- `purchase_decision_service.dart` is the template: fetches its own five inputs,
  returns a verdict-shaped map, pure Dart, DTI 33% cap (DEC-026). (It lives in
  `lib/features/chat/services/`, not `core/`.)
- **`transactions.category` is a free-text Arabic string authored by Gemini at log
  time** — exactly the قهوة/كوفي/مقهى fragmentation doc 20 warns about. No
  `qty`/`unit` capture. **Fixing this is the prerequisite for everything below.**
- `commitments` carry name/total/remaining/monthly/type(`'bnpl'`)/provider/status
  but **no cash-price field**, so installment effective cost is currently
  uncomputable — additive migration needed.
- **Flag on existing docs:** `financial-knowledge-layer.md` §7.2 says Azdal
  "directs users to the most suitable platform (Tamra/Abyan by size/risk)." That
  is **suitability-based platform recommendation — on the wrong side of the advice
  line (§4). Soften to non-personalized education or remove.**

## 1. Fixed category taxonomy (build FIRST — it starts the 4-week clock)

Free-text categories can't aggregate; the habit gate never honestly fills. Borrow
principles (not wholesale) from Plaid's Personal Finance Category taxonomy (16
primary / ~104 detailed, deliberately simplified from 600+, with confidence
levels) and COICOP for coverage sanity.
Sources: [Plaid taxonomy](https://plaid.com/blog/transactions-categorization-taxonomy/) ·
[CSV](https://plaid.com/documents/transactions-personal-finance-category-taxonomy.csv) ·
[PFC docs](https://plaid.com/docs/transactions/pfc-migration/) · COICOP **[UNVERIFIED URL]**.

**Starter taxonomy — 14 primary keys** (English snake_case in DB, Arabic display in
Dart): `groceries` (مقاضي — item-level milk lives here), `coffee_out` (قهوة خارجية
— **deliberately top-level**, his named habit target, not buried under dining),
`dining_out` (مطاعم وتوصيل), `fuel_transport` (بنزين ومواصلات),
`utilities_bills` (فواتير), `subscriptions` (اشتراكات), `housing` (سكن وصيانة),
`health` (صحة), `family_outings` (طلعات عائلية), `personal_shopping` (تسوق شخصي),
`education` (تعليم), `gifts_social` (هدايا وواجبات — culturally load-bearing, never
moralized), `charity_zakat` (صدقة وزكاة — separate so never flagged a "bad habit"),
`misc` (متنوع — if >15% of monthly spend, weekly review prompts re-categorization;
`misc` share is a data-quality metric).

Plus orthogonal columns for unit economics: `item_key` (nullable closed list:
`coffee`,`milk`,`water`,`bread`,`diapers`…) and `qty`/`unit_size`/`unit` (nullable;
filled by OCR or volunteered detail — **never interrogated at logging time**, which
would kill logging coverage, the leading metric).

**Assignment pipeline (trust-compliant):** (1) deterministic Dart keyword map
(first match: `قهوة|كوفي|كافيه|ستاربكس → coffee_out`); (2) LLM **closed-set** choice
only on no hit — the Gemini prompt changes from "author a category string" to
"choose one key from this enum" + Dart validation (else `misc`); (3) a
`user_category_overrides` table checked before step 1 next time — his corrections
grow the deterministic layer with **zero model cost**. Store
`category_source: override|deterministic|llm|user` (Plaid's confidence idea).
**Migration additive:** add `category_key`,`category_source`,`item_key`,`qty`,
`unit_size`,`unit`; keep old free-text as `category_raw`; one-time backfill, unmatched
→ `misc` surfaced once.

## 2. Habit detection + substitution + unit economics (examples 1 & 3)

**The data gate is a verdict, not an error.** `insufficient_data` is first-class:
gate = ≥28-day span with a `category_key` AND ≥60% daily coverage over trailing 28
(below that, "buys coffee daily" can't be distinguished from "logs on coffee
days"). Response carries what's missing → "أحتاج ٩ أيام تسجيل إضافية عشان أعطيك
كلام صادق عن عاداتك" (itself a Fogg-aligned logging nudge).

`HabitDetectionService` (deterministic): gate → aggregate trailing 28d by
(category_key,item_key): occurrences, avgTicket, avgPerWeek,
monthlySpend = total/windowDays×30, annualized anchor, shareOfIncome. Habit
threshold (repo-committed, can't drift): ≥12 occurrences/28d (~3+/week) OR
monthlySpend ≥5% income. Returns `{verdict: habits_found|no_habits|insufficient_data, habits:[…]}`.
"Arithmetic with warm phrasing, presented as exactly that."

`SubstitutionService` (**pure function, no I/O**): the **model** proposes the idea
(world-side language); every **number** is Dart-computed from his logged data,
numbers he supplies, or a fetched cited price (later — never invented). **V1: ask
him for machine price + cost-per-cup** (two questions once → unimpeachable math).
```dart
evaluateSubstitution({currentMonthlySpendSar, upfrontCostSar, altMonthlyRunningSar})
  → { verdict: saves_money|not_cheaper, monthlySavingSar, annualSavingSar,
      breakEvenMonths, firstYearNetSar }
```
Phrasing split (BRP): Dart renders numbers; LLM authors one bounded `reply`.
Behavioral grounding: **loss-framing** ("تخسر ٤٨٨ شهرياً — ٥٨٥٦ بالسنة" > "توفر"),
Fogg B=MAP (one low-friction action), user sets his own target (staged→confirm),
**never gloat** if next week's coffee spend is unchanged (neutral re-plan). V1 =
on-demand + weekly review; proactive push waits for the proactivity engine.

`UnitEconomicsService` (**pure function**, example 3): compares options by
price-per-unit; with `unitsConsumedPerMonth` also returns monthly cost + saving +
`consumptionSource`. Two built-in caveats: (a) detecting "always buys small" is
gated on `item_key`+`unit_size` density (OCR/volunteered) — until then it works
**on demand** (he supplies two prices, gets the verdict, day one); (b) family-size
math must respect cash-flow — composes with `calculateRemainingBudget()`: "العائلي
أرخص باللتر ١٫٠٩، لكن باقي لك ٨٥ هالشهر — الصغير أهون على أسبوعك." Spoilage/waste
is his judgment; the app states unit math only.

## 3. Payoff-vs-invest engine (example 4 — the crown jewel)

**Defensible framework:** paying down debt = a **guaranteed, risk-free return equal
to the debt's effective cost**, compared against a *risk-free* alternative, not
hoped-for stock returns; emergency buffer first; then surplus is investable —
matching the knowledge layer's own pyramid (§6.1).
Sources: [Bogleheads: pay down loans vs investing](https://www.bogleheads.org/wiki/Paying_down_loans_versus_investing) ·
[Fidelity](https://www.fidelity.com/learning-center/personal-finance/pay-down-debt-vs-invest).

**Deterministic cascade:** (1) **liquidity floor** — if clearing the installment
drops liquid cash below emergency milestone 1 (one month essential outflow) →
`keep_cash_build_emergency` (or `split`); (2) **compute the debt's effective annual
cost** from his actual numbers (IRR); (3) **compare as categories, not instruments**
— cost > 0 → `pay_off` ("سداده = عائد مضمون ١٢٪؛ أي استثمار لازم يتجاوز ١٢٪ *بعد
المخاطرة*"); cost ≈ 0 (genuine fee-free BNPL) → **honest `neutral_zero_cost`**, with
non-math factors returned as explicit flags (DTI headroom freed under SAMA's
33.33% cap, cash-flow freed, missed-payment risk) — never smuggled into fake
arithmetic; (4) **never name where to invest** — the *sequence* is education, the
instrument stays his.

**Representing KSA BNPL cost — derive, don't assume.** SAMA licenses/regulates BNPL
(Dec 2023 rules), suspended the small admin fee, caps exposure (SAR 10,000 —
**[UNVERIFIED: a Dec-2025 circular reportedly raised this — verify before
hardcoding]**). Tamara/Tabby market split-in-4 as no-interest/Sharia-certified;
longer tenors are typically murabaha fixed-markup **[UNVERIFIED marketing vs
reality]**. **Design answer: capture `principal_cash_price` + `total_payable` at
commitment creation (additive migration); effective cost = IRR of his actual
payment stream in Dart** — collapses murabaha markup/fees/subsidies into one honest
number; fee-free split-in-4 computes to 0 and the engine says so.
Sources: [SAMA BNPL Rules](https://rulebook.sama.gov.sa/en/rules-regulating-buy-now-pay-later-bnpl-companies-0) ·
[SAMA Responsible Lending / 33.33% cap](https://rulebook.sama.gov.sa/en/chapter-iv-quantitative-principles-responsible-lending) ·
[Tamara](https://tamara.co/en-sa).

```dart
evaluatePayoffVsInvest({commitmentId, cashAvailableSar}) async
  → { verdict: pay_off|keep_cash_build_emergency|split|neutral_zero_cost,
      effectiveAnnualCostPct, guaranteedSavingSar, monthlyCashflowFreedSar,
      monthsFreed, dtiBefore, dtiAfter, emergencyFundAfterSar, flags:[…], reply:null }
```
Missing cash-price/total-payable → `need_info` (mirrors DEC-026). The `_irrAnnualized`
helper (Newton's method) **needs real tests** (DEC-048 proved the fake-coverage gap
is real — he'll obey this with real money).

## 4. The safe advice boundary (CMA/SAMA) — concrete DO/DON'T

**The line, verified:** under the CMA's Securities Business Regulations, "advising"
on a security's merits — expanded to include financial planning / wealth management
— is a **regulated activity** requiring a licensed Capital Market Institution.
Robo-advice sits under CMA licensing. Reported exemptions (media/publication;
advice incidental to another profession) **[UNVERIFIED article numbers — read the
CMA PDF and pin Arts. 15/9 before relying on them]**. The safe distinction:
**general, non-personalized education about principles + computing his own money**
vs **personalized advice on a specific instrument.** A single-user build arguably
never meets "by way of business," but design to the product-grade line anyway.
Sources: [CMA Amended SBR (PDF)](https://cma.gov.sa/en/RulesRegulations/Regulations/Documents/Amended%20Securities%20Business%20Regulations.pdf) ·
[King & Spalding](https://www.kslaw.com/news-and-insights/establishing-a-regulated-financial-institution-in-saudi-arabia-key-considerations-for-capital-market-institutions) ·
[Lexology](https://www.lexology.com/library/detail.aspx?g=4a95fdb8-886c-4f80-9bd4-a14e23ca89f2).

**DO:** compute anything about his own money (budget, DTI, debt effective cost,
goal impact, emergency gap); teach the principle with his numbers plugged in
("سداد قسط كلفته ١٢٪ = عائد مضمون ١٢٪؛ الاستثمار غير مضمون" — the flagship DO);
state regulators' own rules as sourced facts; sequence education (fund → high-cost
debt → then surplus is investable); say "ما أقدر أرشّح أداة — هذا نشاط مرخّص؛ هذا
الإطار بدلها" (the refusal builds trust).

**DON'T (in any engine or prompt):** name a specific security/fund/stock/sukuk/
crypto/platform with a buy/use/suitability recommendation (**incl. removing the
§7.2 platform-matching**); promise/project/assume a **market return in a
personalized computation**; time the market or rank instruments; let the **LLM**
author any of the above spontaneously — the router system prompt gets an explicit
refusal rule + a "which stock?" → framework-not-instrument few-shot.

## 5. Router composition + build order

Tools (all coarse, verdict-shaped, fetch own inputs, one round, log to `tool_calls`):
`detect_habits({category_key?})`, `compare_unit_options({option_a,option_b,consumption_hint?})`,
`evaluate_payoff_vs_invest({commitment_ref,cash_available})`. The only write
(accepting a substitution target) goes through staged-proposal + confirm.
`insufficient_data`/`need_info`/`neutral_zero_cost` are legitimate verdicts so the
model never fills gaps itself.

**Build order (with reason):** (1) **taxonomy + additive migrations** first — it
starts the 4-week clock, every week of delay = discarded fragmented data; (2)
**`evaluate_payoff_vs_invest`** — no history gate (runs off today's commitments +
profile), the thesis crown jewel, value same week, includes IRR + real tests; (3)
**`compare_unit_options` on-demand** — tiny pure function, no gate when he supplies
prices; (4) **`detect_habits` + `SubstitutionService`** last — the gate needs ~4
weeks of taxonomy-clean data that steps 1–3 accumulate, so the gate costs ~zero
calendar time. Slots into the existing plan (step 1 ∈ Phase 1, 2–3 late Phase 1 /
early Phase 2, step 4 = Phase 3) with **no reordering** — all after Phase 0
(durability) + Phase 0.5 (router).

## 6. Durability & open questions

**Durability:** all engines pure Dart, mostly pure functions (trivially testable;
real tests before he obeys them — esp. IRR); no external API in V1 (alt prices
user-supplied; world price tool is a later additive upgrade); deterministic engines
mean the `firebase_ai` migration changes *routing*, never verdicts; taxonomy keys +
thresholds are repo-committed constants (can't drift); honest verdicts mean the
engines never overpromise. **Risks:** item-level density for example 3's proactive
mode (mitigated by shipping on-demand first); the SAR-10,000 BNPL limit changed
Dec 2025 (source-and-date every regulatory constant); taxonomy churn (resist adding
categories 6 months — Plaid's lesson).

**Open questions:** milk-size capture (OCR only vs one-tap size chip after save —
friction test); `neutral_zero_cost` phrasing (tone question he owns); whether the
payoff verdict ever cites a real risk-free rate (current design says no —
categorical only); where substitution targets live (`goals` vs new `habit_targets`);
**verify before shipping**: CMA SBR article numbers, the Dec-2025 BNPL limit,
Tamara longer-tenor pricing.

## Related
- `20_personal_vision_and_goals.md` (examples 1/3/4, the advice-line guardrail),
  `23_research_tool_calling_router.md` (router these plug into),
  `24_research_memory_and_proactivity.md` (shares the taxonomy + nudge engine),
  DEC-050/024/026, `docs/research/financial-knowledge-layer.md` (**§7.2 needs the
  advice-line fix**), `21_personal_build_plan.md`
