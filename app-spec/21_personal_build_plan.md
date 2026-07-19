# Personal Build Plan

> The plan for turning Azdal into the founder's own real, permanently-developed
> personal finance coach — the phase after the AMAD hackathon. Consulted with
> the Fable model (twice), grounded in reads of the actual code, and reconciled
> with the founder's own words in `20_personal_vision_and_goals.md`.
>
> This is a living plan, not a contract. Its acceptance criterion is the
> founder's real financial trajectory, not the completion of a checklist.

## Framing: the chat coach *is* Azdal

The most useful reframe (Fable's): the chat coach is the real product. The
splash / onboarding / tab-shell / mock bank-linking / journey screens were a
temporary costume for hackathon judges. So the personal build is not a fork
*away* from Azdal — it is Azdal returning to its core, with the demo shell as the
divergent artifact.

**Cut from the personal build:** the whole demo shell (`features/launch`,
`features/shell`, `features/courses`, `features/journey`, `features/bank`, most
of `features/account`), and specifically the **"start as new guest" reset** —
harmless as a demo affordance, but a loaded gun on a device holding real
financial history. Compile it out, don't just hide it.

## The single most urgent action — before any feature

The founder's account is currently **anonymous** (a device-local session). His
entire financial history could vanish with one cleared app or lost phone.
**Convert it to a permanent email-linked account** (Supabase supports this
in-place, same UUID, all rows preserved) and set up backups. This protects data
that already exists, is independent of the hackathon, and outranks everything
below.

## Feature gaps — his needs vs. what exists

Verified against the code. "Have" = the existing Coach already covers it; "New" =
a real capability gap.

| His need | Status | Note |
|---|---|---|
| "Can I buy X at price Y now" | **Have** | The buy engine works end-to-end |
| Tamara/BNPL installment decision | **New, easy** | `commitments.type` already has a `'bnpl'` value; DTI cap is the right base. A distinct `evaluateInstallment` — installment = total/months, re-check DTI, and on "yes" create the BNPL commitment so future decisions account for it |
| "Will this wreck my goals" | **Partial** | The "wait" verdict says *that* a goal is delayed, never *by how much*. Quantifying it is `ceil(shortfall / monthly_contribution)` — cheap, high-trust |
| Next month's plan straining this month | **New — needs a concept** | Nothing knows about the future. Add a `planned_expenses` table; model a future cost as a **pre-funding requirement** of `amount / months_until_due` per month starting now — that's the mechanism by which the future presses on the present, and a user can verify it by hand |
| Situational budget ("family dinner tonight") | **New, mostly composable** | `calculateRemainingBudget()` already returns `remaining` and `daysLeft`; add salary-cycle awareness (`financial_profile.salary_day` exists but is unused) and a lightweight, single, auto-expiring **session envelope** ("طالع مع الأهل، حط لي حد ٣٠٠") |
| Emergency fund | **New treatment** | A designated goal type, but the designation must do work: first milestone = 1 month of *essential* outflow (not the demoralizing 3–6 months); it becomes the shock-absorber in the unexpected-expense flow, with a computed refill plan |
| 2–3 month trajectory | **New** | Same forecasting engine as forward cash-flow, rendered as a projection |
| Fast triage of a forced expense + soften the blow | **New composition** | Log it → recompute budget + goal impact + emergency-fund option → one **damage-report card** with a *deterministic* mitigation menu (pause a goal a month, draw from emergency fund, spread it, absorb it), each carrying its computed consequence. The LLM only phrases; Dart computes |
| Habit detection & replacement | **New, with a prerequisite** | Only honest with ~4 weeks of real data — do NOT ship "insights" off ten transactions. Prerequisite: a **fixed category taxonomy** so aggregation doesn't fragment (قهوة/كوفي/مقهى becoming three habits). Then it's SQL aggregation presented plainly, and the user sets his own substitution target |
| Needs-vs-wants coaching | **New — conversation design** | Never moralize at logging time (that teaches hiding). At *decision* time, offer self-labelling (ضروري / يمشي الحال / رفاهية); later reflect *his own labels* back |
| Investment vs. operational expense | **New — honest version** | Total-cost-of-ownership: `price + 12 × recurring` for larger purchases, and register the recurring part as a commitment. The app must NOT rate life-decision "investment quality" — it can't, and pretending would poison the trust |

Also inherited and now urgent because a real user depends on the data: the
DEC-039 deferrals (especially **commitment payoff not creating a transaction**,
which silently corrupts monthly-spend truth) and the fake-test-coverage gap on
the financial-math services (DEC-048 proved that gap is real).

## "My success is the branch's success" — made falsifiable

"I feel better about money" is unfalsifiable and will rot into vibes. Track five
real metrics computed from his actual Supabase rows, with definitions committed
to the repo so they can't drift retroactively:

1. **Logging coverage** — % of days with ≥1 logged transaction (the leading
   metric; if it drops, nothing downstream is true).
2. **Emergency fund vs. milestone 1** (one month of essential outflow).
3. **Monthly savings rate** — (income − outflow) / income, trend over months.
4. **Model accuracy** — projected end-of-month disposable vs. actual. Unusual and
   valuable: it measures whether *the app* is getting more truthful, not just
   whether he is. A coach that publishes its own error rate earns trust.
5. **Consulted-decision count** — purchases above a threshold that went through
   the engine before happening.

Surface these as a **mirror view (المرآة)** — a chat query ("وين وصلت؟")
rendering one summary card, not a dashboard tab — plus one weekly-initiated
review, not daily nagging.

**Definition of done for the first stage:** 4 consecutive weeks of ≥90% logging
coverage, emergency fund at milestone 1, savings rate > 0 for 2 consecutive
months, and model accuracy within ~15%. Guardrails: metrics may be *added* or
targets adjusted going forward, never redefined retroactively; and the app is not
accountable for a structural deficit — if income is genuinely below essential
outflow, the app's job is to show that clearly and early, not to conjure savings
arithmetic forbids.

## Branch strategy — sequencing beats branching

A long-lived divergent git branch was **rejected** (the shared core would rot
apart within a month). Recommended instead: **(1)** tag the hackathon submission
(`hackathon-amad-2026`); **(2)** add a second Flutter entry point
(`lib/main_personal.dart`, a minimal chat + settings router) in the same repo;
**(3)** over time, invert `main` itself into the personal product and quarantine
the shell. One codebase, one direction of truth, zero merge debt.

Backend: keep the single Supabase project — RLS-per-user already isolates his
data. But treat migrations as production migrations from now on (additive,
reversible, tested first), and enable backups (PITR if the plan allows, else a
scheduled `pg_dump`).

## Phased build order

- **Phase 0 — foundation.** Account durability (anonymous → permanent) + backups;
  **real tests** for `PurchaseDecisionService` and `IntegrityScoreService`
  against the actual classes (close the fake-coverage gap — he's about to obey
  this arithmetic in real life); fix the commitment-payoff-creates-no-transaction
  gap. Build a **golden intent matrix** (real dialect phrasings → expected
  behavior) against the *current* router, so it encodes today's behavior before
  anything changes.
- **Phase 0.5 — the tool-calling router.** Replace the brittle regex intent-gates
  with Gemini native function-calling, as a single-hop dispatcher. This is the
  right foundation *before* adding new capabilities, because otherwise each new
  capability is another regex gate you've already decided to delete. Full
  rationale and the discipline rules are **DEC-050** — read it before starting.
- **Phase 1 — "this is already helping me" week.** BNPL/installment decision;
  goal-delay quantification; salary-cycle-aware budget + safe-to-spend-today;
  fixed category taxonomy; quick-capture (app shortcuts / mic-hot); the
  tone/disobedience-rule prompt work (`20_personal_vision_and_goals.md`).
  **Gate:** if week-1 logging coverage < ~80%, SMS-parsing (Android bank SMS →
  auto-log) jumps to the top — every downstream feature is only as honest as the
  logging underneath it.
- **Phase 2 — the future becomes visible.** `planned_expenses` + pre-funding
  model; 3-month projection (inputs labelled actual vs. estimate); emergency-fund
  designation + milestone 1; unexpected-expense damage-report flow; session
  envelope for outings.
- **Phase 3 — patterns, once data exists.** Mirror view + weekly review ritual;
  habit aggregates + self-set substitution targets; needs/wants self-labelling +
  TCO on large purchases; explicit preference profile; SMS parsing if the week-1
  gate didn't already promote it.

## Unified build order — the agentic-coach quartet (2026-07-19)

> This section **refines** the "Phased build order" above with the four deep
> consults (DEC-051…054, research docs 22–26). Ordering principle, stated bluntly:
> **foundation before bling.** Three things recur as the prerequisite for every
> impressive behaviour — the router, the fixed category taxonomy + 4 weeks of
> logging, and the memory layer. The features that dazzle (cheaper-alternative
> search, habit detection, proactivity) all stand on top of them.

**Gate checks first — cheap, before any code:**
- **G1 — App Check × sideloaded APK** (Firebase console): decides `firebase_ai`
  vs `googleai_dart` for the router *and* the world tools. Blocks DEC-050/054.
- **G2 — live Supabase check**: plan tier (backup path) + confirm the pre-existing
  anonymous data is throwaway before deleting it (DEC-051).

**Phase 0 — foundation (durability, simplified by DEC-051):**
- Remove guest sign-in; require email login from first launch; delete the guest
  reset; clean-slate the throwaway data.
- Backups: nightly `pg_dump` via GitHub Actions, `age`-encrypted, private repo,
  **including `-s auth`** (doc 22).
- Migration baseline: `supabase db pull`; production-migration discipline
  henceforth.
- Real tests for `PurchaseDecisionService` + `IntegrityScoreService`; fix the
  commitment-payoff-creates-no-transaction gap.
- Build the **golden intent matrix against the *current* router** (the migration
  safety net).
- Task-zero cheap fix: soften/remove `financial-knowledge-layer.md` §7.2 (DEC-053).

**Phase 0.5 — the router (DEC-050):** migrate to `firebase_ai` behind a
`RouterLlm` interface; forced ANY + `general_chat` + `ask_clarification`;
open/closed tool registry; `tool_calls` trace. Retire the regex gates.

**Phase 1 — the intelligence foundation ("before the bling"):**
- **Fixed category taxonomy** + migration + backfill (DEC-053) — do EARLY (may
  overlap Phase 0.5); it starts the 4-week clock.
- **Memory M0**: `user_facts` + `preference_profile` + `remember_fact` /
  `recall_memory` / `update_preference` (DEC-052) — kills most of "it doesn't
  remember me."
- **Tone**: no-gloat constants + profile-driven BRP variants + the vision-doc
  tone/disobedience prompt.

**Phase 2 — value-now engines (no data gate):**
- `evaluate_payoff_vs_invest` — the crown jewel; capture `principal_cash_price` +
  `total_payable`; IRR + real tests (DEC-053).
- `compare_unit_options` on-demand (DEC-053).
- World **W0 spike** (10 real KSA grounded queries — retires the biggest unknown)
  → **W1** `search_price` + `WorldOutcome` card + grounded-or-silent enforcement +
  `price_observations` (DEC-054).

**Phase 3 — world + composition:** **W2** `find_cheaper_alternative` composing
into the substitution/unit engines; **W3** `get_market_info` (DEC-054).

**Phase 4 — data-gated (after ~4 weeks of taxonomy-clean logging):**
- `detect_habits` + `SubstitutionService` (DEC-053); proactivity **M2** in-app
  insights → **M3** background nudges (DEC-052); the weekly review / mirror
  (المرآة).
- **W4 (conditional)** SerpApi behind `WorldPriceProvider`, only if telemetry
  shows a real price-precision gap (DEC-054).

**Guardrail (from DEC-050's timing note):** timebox each phase; if one overruns,
ship the value you have and return — his real financial life is the point, not
architectural purity.

## Honest limits (tell the founder as-is, don't oversell)

- **"Understands my personality"** — not achievable as real inference now. The
  honest substitute is an explicit, user-edited preference profile plus
  remembered facts. See `20_personal_vision_and_goals.md`.
- **Habit "insight"** is arithmetic with warm phrasing, presented as exactly
  that. Anything more, this early, is theater.
- **Projections are models of estimates.** Label inputs; publish the app's own
  accuracy. Trust the trend only as the logged data underneath it becomes
  complete.
- **Investment-quality judgment stays his.** The app surfaces recurring costs and
  totals; it does not rate life decisions, and won't pretend to. (This also keeps
  it clear of personalized investment advice, which a coach app should
  structurally avoid.)
- **The app cannot out-coach a structural deficit.** If essential outflow exceeds
  income, its honest job is to make that visible fast — not to promise savings
  arithmetic forbids.

## Sources & consultations behind this plan

- **Fable-model deep consults, verified against live official docs, captured in
  full:** `22_research_account_durability.md` (Phase 0 — conversion, backups,
  migrations) · `23_research_tool_calling_router.md` (Phase 0.5 — SDK verdict +
  router architecture) · `24_research_memory_and_proactivity.md` (the memory layer
  + proactivity/nudge engine — the "personal assistant" infrastructure) ·
  `25_research_financial_intelligence_engines.md` (fixed category taxonomy, habit/
  substitution/unit-economics engines, payoff-vs-invest, and the CMA/SAMA advice
  line) · `26_research_world_facing_tools.md` (Gemini Google-Search grounding for
  real KSA price/product/market lookup — two-call architecture, grounded-or-silent
  enforcement, the ToS "no price database" rule). Read the relevant one before
  building that layer; they supersede the summary bullets below where they conflict.
- Two Fable-model consultations (2026-07): the full product/feature plan, and a
  focused architecture read of the current chat routing.
- The founder's own stated needs and philosophy — `20_personal_vision_and_goals.md`.
- Direct reads of `purchase_decision_service.dart`, `gemini_service.dart`, the
  Supabase schema, and the decision log through DEC-048.
- The "agent harness" concept the founder encountered (a YouTube video, título
  "الحقيقة وراء وكلاء الذكاء الاصطناعي") — which prompted DEC-050. See that entry
  for how the concept was evaluated and where it does and doesn't apply.
