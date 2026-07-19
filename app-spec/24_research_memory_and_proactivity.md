# Research — Memory + Proactivity (the "personal assistant" infrastructure)

> **Provenance.** A Fable-model deep-design consult (2026-07-19), grounded in full
> reads of `CLAUDE.md`, `START_HERE.md`, `20_personal_vision_and_goals.md`,
> `21_personal_build_plan.md`, `23_research_tool_calling_router.md`, DEC-050/024/022,
> `INIT-03_supabase_schema.md`, `docs/research/financial-knowledge-layer.md`,
> `gemini_service.dart`, `purchase_decision_service.dart`, `financial_profile_service.dart`,
> `pubspec.yaml`. Verified against live 2026 docs; URLs inline; unverified points
> marked. Acceptance target = the 4 examples in doc 20 ("The agent he imagines").

## Bottom line

1. **No vector search, no embeddings.** A single-user coach's memory is 20–100
   structured facts, not a corpus. Keyed `user_facts` + explicit
   `preference_profile` tables, retrieved deterministically by Dart. Composes with
   DEC-050 rule 5 because Dart — not the transcript — authors what the model sees.
2. **New hard rule: memory stores context, never money.** Financial magnitudes
   live only in the ledger tables (`financial_profile`, `commitments`, `goals`,
   `transactions`). `user_facts` is structurally barred from holding amounts —
   this prevents memory from becoming a back-channel for LLM arithmetic (DEC-024).
3. **Proactivity: on-device, not server-side.** `workmanager` (daily inexact) +
   `flutter_local_notifications`, all nudge math pure Dart, **zero LLM calls in
   the background path** (deterministic Arabic templates). Server-side
   pg_cron→Edge-Function→FCM is viable but rebuilds the compute layer DEC-024
   cancelled and drags in FCM/App-Check. Reversible choice behind an interface.
4. **Build order: memory → profile → in-app (pulled) insights → background
   (pushed) nudges.** Proactivity without ~4 weeks of taxonomy-clean data is blind
   nagging (doc 20's guardrail).

## Grounding discrepancies found

- `financial_profile` is **not in `INIT-03_supabase_schema.md`** (added later).
  Update the schema doc when adding the migrations below so truth doesn't fork.
  (Live DB not seen — `financial_profile` columns are code/plan-inferred.)
- `pubspec.yaml` still carries a stale "STUB — Pre-implementation" comment. **No
  notification / background / Firebase packages exist yet** — all of §Proactivity
  is net-new dependency surface.
- The coach prompt (`_systemPrompt`) receives **no user context whatsoever** — "it
  doesn't remember me" is literally accurate; the fix is architectural.

## The memory layer

**Industry (2026):** separate episodic (what happened) from semantic
(facts/preferences); do the work at write time; "embed everything into one vector
index" is a named failure mode. Anthropic's context-engineering guidance = memory
as structured notes persisted outside the window, pulled back deliberately —
exactly the DEC-050 shape (Dart writes notes, Dart selects what re-enters).
Azdal's memory = one user, bounded discrete facts with canonical keys → Postgres
rows beat embeddings on correctness, auditability, durability, cost. **Episodic
memory is free: the ledger tables already are it** (`transactions`,
`purchase_decisions`, `commitments`, `goals`, planned `tool_calls`) — don't
duplicate.
Sources: [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) ·
[vectorize.io](https://vectorize.io/articles/best-ai-agent-memory-systems) ·
[mem0](https://mem0.ai/blog/long-term-memory-ai-agents) ·
[Redis agent memory](https://redis.io/blog/build-smarter-ai-agents-manage-short-term-and-long-term-memory-with-redis/)

**What to remember:** stated facts (salary day, household, provider prefs) →
`user_facts`; preferences (tone, verbosity, cadence) → `preference_profile`;
recurring context → `planned_expenses` + `user_facts`; prior decisions/outcomes →
`purchase_decisions` + `tool_calls` (feeds no-gloat suppression); detected
patterns → computed on demand, snapshotted into `nudges` when surfaced; financial
magnitudes → **never in memory, ledger only.**

### Schema (additive; soft-delete, RLS-per-user, CHECKs, set_updated_at)

```sql
CREATE TABLE user_facts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fact_key TEXT NOT NULL,          -- canonical snake_case: 'salary_day','household_size','bnpl_provider_pref'
    fact_value JSONB NOT NULL,       -- {"v":25}|{"v":"tamara"} — context values only, never amounts
    fact_text_ar TEXT NOT NULL,      -- Dart-composed Arabic line injected into prompts
    source TEXT NOT NULL CHECK (source IN ('user_stated','app_detected_confirmed')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','superseded')),
    superseded_by UUID REFERENCES user_facts(id),
    stated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ,
    is_deleted BOOLEAN NOT NULL DEFAULT false, deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_user_facts_active_key
    ON user_facts (user_id, fact_key) WHERE status='active' AND is_deleted=false;
```

- **Keyed upsert with a supersede chain IS the compaction strategy** — update = new
  row + mark old `superseded` (never edit in place, never hard-delete). Growth
  bounded by keys × changes ≈ nothing for one human. No summarization job to build.
- `fact_text_ar` is Dart-authored at write time → injection is a string concat.
- **"Never re-ask" is enforceable:** tools check `user_facts` before any clarify; a
  `need_info` for a known key is a testable bug.
- **Structural money bar:** `UserFactsService.upsert()` rejects financial-magnitude
  keys (denylist) + a committed `fact_keys.dart` registry with an `isPromptSafe`
  bit. Income → `financial_profile`; commitment → `commitments`.
- Free-form facts get `note_<slug>` keys; cap ~100; weekly "memory review" card
  retires stale ones (human-in-the-loop compaction).

```sql
CREATE TABLE preference_profile (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tone TEXT NOT NULL DEFAULT 'direct' CHECK (tone IN ('direct','gentle')),
    detail TEXT NOT NULL DEFAULT 'numbers_first' CHECK (detail IN ('numbers_first','summary_first')),
    reply_length TEXT NOT NULL DEFAULT 'short' CHECK (reply_length IN ('short','medium')),
    nudges_enabled BOOLEAN NOT NULL DEFAULT false,           -- opt-IN
    nudge_max_per_week INT NOT NULL DEFAULT 3 CHECK (nudge_max_per_week BETWEEN 0 AND 7),
    quiet_start TIME NOT NULL DEFAULT '22:00', quiet_end TIME NOT NULL DEFAULT '09:00',
    weekly_review_dow INT NOT NULL DEFAULT 5 CHECK (weekly_review_dow BETWEEN 0 AND 6),
    weekly_review_time TIME NOT NULL DEFAULT '21:00',
    nudge_habit_enabled BOOLEAN NOT NULL DEFAULT true,
    nudge_unit_econ_enabled BOOLEAN NOT NULL DEFAULT true,
    nudge_invest_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Retrieval:** deterministic — one query (active facts + profile), cached in
Riverpod, invalidated on write. No ranking/search; all of it fits in a few hundred
tokens. `last_used_at` gives the weekly review a staleness signal.

## Injection without breaking history-free routing (DEC-050 rule 5)

Memory = Dart-authored state, not history. Two surfaces:

**A — router call:** inject only *which keys exist*, not values:
```jsonc
{ "pending": {"tool":"evaluate_purchase","item":"ساعة","missing":["amount"]},
  "known_fact_keys": ["salary_day","household_size","bnpl_provider_pref"],
  "profile": {"tone":"direct","detail":"numbers_first"},
  "has_income_on_file": true }   // boolean flags only — never the number
```
`known_fact_keys` lets the model route "متى ينزل راتبي؟" to a `recall_fact` tool
and teaches few-shots "if the key is known, never ask."

**B — coach/BRP calls:** a Dart-composed block of `fact_text_ar` lines, filtered by
`isPromptSafe`:
```
[معلومات عن المستخدم — صاغها التطبيق، لا تضف عليها ولا تحسب منها]
- راتبه ينزل يوم 25 من كل شهر
- عنده أسرة: زوجة وطفلان
- يفضّل تمارا للتقسيط
```
Enforced structurally: one `MemoryBlock.build()` consuming only prompt-safe
`fact_text_ar` (no path formats a ledger number in); `route(userText, state)`
signature keeps the transcript a non-parameter.

**New router tools** (one-file `RouterTool` each): `remember_fact` (write tier:
confirmCard — memory writes alter every future conversation, so same trust
treatment as money writes), `recall_memory` (renders "هذا اللي أعرفه عنك" with
edit/forget = soft-delete supersede), `update_preference` (staged typed edit).

## The explicit preference profile (honest "understands my personality")

Edited three ways, all existing machinery: (a) natural language → `update_preference`
staged; (b) a rendered profile card with tap-to-toggle chips; (c) ≤1 profile
question during the weekly review when signals conflict — **offer, never silently
infer** (silent inference = the fake-personality trap doc 20 forbids). Modulation
is mostly Dart: `detail:numbers_first` = widget ordering (zero LLM); `reply_length`
= BRP length bound; `tone` selects between two committed BRP variants, **both
blunt-honest** (`gentle` softens delivery, never the verdict — the tone floor is
not user-configurable, by design). **Never gloat is a constant, not a preference.**

## The proactivity engine

**Verified landscape (2026-07-19):** `flutter_local_notifications` 21.0.0 (actively
maintained, de-facto standard); `workmanager` 0.9.0+3 (maintained, pre-1.0,
historic maintenance gaps — honest risk); `android_alarm_manager_plus` 5.1.0
(Flutter Favorite, but exact alarms need `SCHEDULE_EXACT_ALARM`, **denied by
default on Android 14+**, cleared on reboot, dead after force-stop, OEM battery
killers). WorkManager periodic = 15-min min, inexact, Doze-compliant. Server-side:
pg_cron + pg_net → Edge Function (official), push via FCM (FCM tab **unverified**;
`firebase_messaging` health unverified).

**Recommendation: on-device computation + delivery.** Deciding argument = DEC-024:
a nudge "coffee daily → machine saves X/month" *contains computed money math*,
which must be pure Dart; a server nudge engine rebuilds the cancelled
Edge-Function compute layer in TypeScript with a second copy of the financial
logic. Architecture:
1. `NudgeEngine` — pure-Dart, unit-testable, queries Supabase, evaluates firing
   rules, computes savings, writes candidate rows to `nudges`.
2. `workmanager` daily inexact task (avoid `SCHEDULE_EXACT_ALARM` entirely).
3. Background isolate runs `NudgeEngine`; passing nudges shown via
   `flutter_local_notifications`; tap deep-links into chat.
4. **No LLM in the background path** — text from committed Arabic templates with
   Dart-slotted numbers (durability + trust + avoids the unverified question of
   whether the Gemini SDK even inits in a `workmanager` isolate).
5. **Foreground sweep on every app open** runs the same engine → since logging
   coverage ≥90% is the Phase-1 metric (he opens daily), the sweep alone delivers
   most value even if the OEM kills the background task. Background = enhancement,
   not dependency.

```sql
CREATE TABLE nudges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('habit_substitution','unit_economics','goal_risk','weekly_review','planned_expense_warning')),
    pattern_key TEXT NOT NULL,       -- 'coffee_daily' — dedup anchor
    evidence JSONB NOT NULL,         -- Dart-computed
    body_ar TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'candidate' CHECK (status IN ('candidate','suppressed','delivered','opened','accepted','dismissed')),
    suppressed_reason TEXT,          -- 'cadence_cap'|'quiet_hours'|'cooldown'|'below_threshold'|'post_override_grace'
    delivered_at TIMESTAMPTZ, responded_at TIMESTAMPTZ,
    is_deleted BOOLEAN NOT NULL DEFAULT false, deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
Every candidate is written even when suppressed (with reason) → "why did/didn't it
nudge me?" is one query; the anti-nagging policy becomes measurable.

## When to fire — the anti-nagging policy

Grounded in `financial-knowledge-layer.md` (Fogg B=MAP; Strategic Silence;
Kahneman loss-framing) + doc 20/21's "weekly review, not daily nag." A nudge fires
only if ALL gates pass (each failure recorded):
1. **Opt-in** (`nudges_enabled` + per-class switch; default off = a Fogg
   commitment device when he turns it on).
2. **Evidence** ≥28 days logging, coverage ≥80%, pattern ≥N occurrences, under the
   **fixed category taxonomy** (no taxonomy → no detection).
3. **Materiality** monthly saving ≥ max(50 SAR, 5% disposable) — both Dart. Below →
   waits for weekly review. (Constants founder-tunable, not research-verified.)
4. **Cadence caps** ≤1/day, ≤`nudge_max_per_week`, per-pattern 30-day cooldown after
   a dismissal / 90 after two.
5. **Quiet window** never inside quiet hours; preferred slot ~21:00.
6. **Post-override grace (no-gloat, mechanized):** if he overrode a verdict in the
   last 72h, suppress every nudge related to that category/purchase — a
   substitution nudge the morning after he ignored coffee advice *is* gloating by
   cron. This single rule keeps proactivity compatible with doc 20's key tone
   constraint.
7. **Channel demotion:** anything failing 3–6 but still true → weekly review line
   item, keeping the pushed channel scarce and welcome.

## Composition + build order

- Router: memory adds 3 tools (zero dispatcher changes) + one `RouterState` field
  family; history-free invariant untouched.
- Money side (Dart/SQL): fact storage/retrieval/injection, pattern detection,
  savings math, firing logic, notification text. World side (later): the DEC-050
  world-tools price lookup composes at the nudge card's seam.
- Write tiers: memory writes + preference edits use existing StagedProposal →
  confirm/undo.

**Build order:** M0 `user_facts`+`preference_profile`+3 tools+`RouterState.known_fact_keys`
(kills most of "it doesn't remember me"); M1 profile-driven BRP variants + fixed
taxonomy + no-gloat constants; M2 `NudgeEngine`+`nudges` **in-app only** (validates
thresholds, zero spam risk); M3 background delivery (`workmanager` +
notifications + Android 13+ `POST_NOTIFICATIONS` prompt, device-verified against
Doze/OEM). Nothing here blocks or is blocked by App Check/`firebase_ai`.

## Durability & unverified

**Strong:** no embeddings to operate/migrate; memory growth bounded; one language
(Dart) owns all computation; background path has zero LLM-critical steps;
everything auditable by SQL; all reversible behind interfaces.
**Watch:** `workmanager` pre-1.0 (fallbacks: `android_alarm_manager_plus`, then
foreground-sweep-only); OEM battery killers (device verification only); §firing
thresholds are proposals.
**Unverified:** FCM tab of the Supabase push page; `firebase_messaging` health;
Gemini SDK in a background isolate (avoided by design); live `financial_profile`
columns; the "three-tier memory" framing (secondary 2026 sources, primary anchor =
Anthropic's post).

## Open questions
1. Nudge opt-in default (off for future users; he may want on for himself).
2. Weekly review day/time (Friday 21:00 is a guess — set in first profile chat).
3. Materiality threshold — tune after M2's in-app-only period.
4. Should `recall_memory` also show ledger-derived summaries? (Yes, as separate
   Dart-rendered sections.)
5. Auto-extract facts from casual chat (staged-confirm) vs explicit "احفظ إن…" only
   — UX judgment (interruption cost of confirm cards).

## Related
- `20_personal_vision_and_goals.md` (the 4 examples), `23_research_tool_calling_router.md`
  (the router these tools plug into), `25_research_financial_intelligence_engines.md`
  (the taxonomy this shares), DEC-050/024/022, `21_personal_build_plan.md`
