# Azdal — `tool_calls` Trace Table Design + Dependency Verification (LL-037)

> **Status:** 🟢 Deployed to live Supabase (kqhyjngtquutzdvjfbnf) — 2026-07-21
> **Date:** 2026-07-21
> **Deployment:** Direct Supabase MCP migration. 16 columns verified present, RLS enabled, 3 own-rows policies, FK to auth.users. Zero issues.
> **Approved by:** Abdulrahman — all 3 open questions resolved: (1) deploy standalone now, (2) `supabase db pull --linked` deferred (5 missing local migrations still outstanding), (3) founder_feedback deferred to future migration.
> **Phase:** Phase 0.5 — Tool-Calling Router (DEC-050)
> **Source trace:** DEC-050, `23_research_tool_calling_router.md` §5, `goal_phase_0.5_tool_calling_router_DRAFT.md` Phase 2, `26_research_world_facing_tools.md`

---

## 1. LL-037 Live Schema Verification (Dependency-Verification Gate)

### 1.1 Query Executed

All queries run against **LIVE Supabase** (`kqhyjngtquutzdvjfbnf`, Frankfurt, linked project) on 2026-07-21:

```sql
-- Full column inventory (all 6 public tables)
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- RLS policies
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- Indexes
SELECT indexname, tablename, indexdef FROM pg_indexes
WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- Trigger functions
SELECT routine_name FROM information_schema.routines
WHERE routine_type = 'FUNCTION' AND routine_schema = 'public';
```

### 1.2 Result Summary

| # | Table | Columns | RLS Policies | Notes |
|---|-------|---------|-------------|-------|
| 1 | `commitments` | 14 | SELECT, INSERT, UPDATE (own) | Anti-ghost fields present |
| 2 | `financial_profile` | 10 | SELECT, INSERT, UPDATE (own) | UNIQUE on user_id |
| 3 | `goals` | 13 | SELECT, INSERT, UPDATE (own) | Anti-ghost fields present |
| 4 | `integrity_scores` | 10 | SELECT, INSERT, UPDATE (own) | UNIQUE on user_id; no soft-delete |
| 5 | `purchase_decisions` | 8 | SELECT, INSERT (own) | Audit-immutable; no UPDATE/DELETE |
| 6 | `transactions` | 16 | SELECT, INSERT, UPDATE (own) | Anti-ghost fields present |

**Total: 71 columns across 6 tables, 17 RLS policies, 18 indexes. All verified present and type-correct.**

New `tool_calls` table: **confirmed absent** — zero naming collision risk. The table will be table #7.

### 1.3 Service-Column Dependency Cross-Reference

Every column the existing services read was confirmed present with matching type:

| Service | Method | Table | Columns Verified |
|---------|--------|-------|-----------------|
| PurchaseDecisionService | evaluate() | financial_profile | user_id(uuid), monthly_income(numeric), monthly_commitments_estimate(numeric), is_deleted(boolean) |
| | | commitments | user_id(uuid), monthly_amount(numeric), status(text), is_deleted(boolean) |
| | | transactions | user_id(uuid), amount(numeric), type(text), is_deleted(boolean), created_at(timestamptz) |
| | | goals | user_id(uuid), monthly_contribution(numeric), status(text), is_deleted(boolean) |
| | calculateRemainingBudget() | (same as above) | — |
| IntegrityScoreService | calculate() | transactions | user_id(uuid), id(uuid), type(text), is_deleted(boolean), created_at(timestamptz), receipt_url(text) |

**Zero missing columns. Zero type mismatches.**

### 1.4 Local Migration Drift

| Environment | Tables | Migration Files |
|-------------|--------|-----------------|
| LIVE Supabase | 6 tables | N/A (Dashboard + SQL Editor deployed) |
| Local `supabase/migrations/` | 1 file | `20260713000000_financial_profile.sql` only |

**The 5 other tables (commitments, goals, integrity_scores, purchase_decisions, transactions) have NO corresponding migration file in the repo.** They were deployed via the Supabase Dashboard SQL Editor or earlier migrations that were not committed.

**RECOMMENDED (carried forward from prior task t_3cd09487):**
```bash
npx supabase db pull --linked
```
This syncs all 6 live tables into local migration files. Without it, `supabase db diff` or `supabase db push` will see a mismatch.

---

## 2. `tool_calls` Table Design

### 2.1 Purpose

Per DEC-050: each routed message gets one row recording the LLM's tool choice, the parsed arguments, the outcome, and (for write tools) the UUIDs of Supabase rows created at confirm time. This replaces the manual verify-by-Supabase-query ritual with:

```sql
SELECT * FROM tool_calls ORDER BY ts DESC LIMIT 5;
```

### 2.2 Schema

| Column | Type | Null | Default | Description |
|--------|------|------|---------|-------------|
| `id` | UUID PK | NO | gen_random_uuid() | Row identity |
| `user_id` | UUID FK→auth.users | NO | — | Owner; ON DELETE CASCADE |
| `message_text` | TEXT | NO | — | Raw user message that triggered routing |
| `model` | TEXT | NO | — | Model alias (e.g. 'gemini-flash-latest') |
| `latency_ms` | INTEGER | YES | — | Round-trip ms from generateContent→parsed |
| `tool_name` | TEXT | NO | — | RouterTool.name the model selected |
| `args` | JSONB | NO | '{}' | Parsed+validated arguments (Arabic-Indic normalized) |
| `outcome_kind` | TEXT (CHECK) | NO | — | See §2.3 |
| `result_summary` | JSONB | YES | — | Compact outcome: verdict/score/disposable/etc. |
| `write_ids` | UUID[] | YES | — | Row UUIDs created at confirm time (filled later) |
| `error` | TEXT | YES | — | Error message for failure outcomes |
| `is_deleted` | BOOLEAN | NO | false | Anti-ghost soft-delete |
| `deleted_at` | TIMESTAMPTZ | YES | — | Anti-ghost timestamp |
| `ts` | TIMESTAMPTZ | NO | now() | When the routing decision occurred |
| `created_at` | TIMESTAMPTZ | NO | now() | Row creation time |
| `updated_at` | TIMESTAMPTZ | NO | now() | Auto-updated by trigger |

### 2.3 `outcome_kind` Enum

| Value | Meaning | `result_summary` | `error` | `write_ids` |
|-------|---------|-----------------|---------|-------------|
| `render` | Read-only tool, result rendered as widget | Present (verdict/score JSON) | NULL | NULL |
| `staged` | Write tool, proposal staged for user confirm | Present (proposal summary) | NULL | Filled at confirm |
| `clarify` | Missing required arg(s), user must clarify | Present (missing fields list) | NULL | NULL |
| `invalid_args` | parseArgs rejected the arguments | NULL | Validation error | NULL |
| `unknown_tool` | Model hallucinated a non-existent tool | NULL | Tool name | NULL |
| `error` | Any other failure (network, service throw) | NULL | Error message | NULL |

Future additions (Phase 1+, not in this migration):
- `world_results` — grounded search results from `search_prices` (DEC-054, doc 26)
- `founder_feedback` column — thumbs up/down on search quality (doc 26)

### 2.4 RLS Policies

| Policy | Verb | Rule |
|--------|------|------|
| `tool_calls_select_own` | SELECT | `auth.uid() = user_id` |
| `tool_calls_insert_own` | INSERT | `auth.uid() = user_id` |
| `tool_calls_update_own` | UPDATE | `auth.uid() = user_id` |

No DELETE policy — physical delete blocked by RLS deny-by-default. Soft-delete via `UPDATE is_deleted=true`.

### 2.5 Indexes

| Index | Columns | Filter | Purpose |
|-------|---------|--------|---------|
| `idx_tool_calls_user_ts` | `(user_id, ts DESC)` | — | Primary access: recent traces per user |
| `idx_tool_calls_outcome` | `(user_id, outcome_kind)` | `WHERE is_deleted=false` | Error audit, staged-proposal review |
| `idx_tool_calls_tool` | `(user_id, tool_name)` | `WHERE is_deleted=false` | Per-tool frequency analysis |

### 2.6 Naming Convention

Column names follow OpenTelemetry GenAI semantic conventions where applicable:
- `gen_ai.tool.name` → `tool_name`
- `gen_ai.request.model` → `model`
- `gen_ai.tool.args` → `args`

`ts` (rather than `created_at`) is the primary event timestamp — when the routing decision happened vs. when the row was inserted (which may differ for `write_ids` backfill at confirm time).

### 2.7 Write-Lifecycle Pattern

```
1. Router receives message → INSERT row with outcome_kind='staged', write_ids=NULL
2. User confirms → UPDATE row: write_ids = [uuid1, uuid2, ...]
3. User undoes → UPDATE row: is_deleted=true, deleted_at=NOW()
```

The trace row is inserted at routing time (step 1), before the user sees the confirmation card. This means a `tool_calls` row exists even if the user never confirms — the trace captures the full funnel (routed → staged → confirmed/cancelled).

### 2.8 Storage Estimate

For a single-user personal build:
- ~10–30 tool calls/day
- ~300 bytes/row (message text is the dominant field)
- ~9 KB/day, ~270 KB/month, ~3.2 MB/year

Negligible. No TTL/purge needed for MVP.

---

## 3. Migration Plan

### 3.1 Prerequisites

- [x] Live schema verified — no naming collisions
- [x] `set_updated_at()` trigger function confirmed present on live DB
- [x] `pgcrypto` extension confirmed available (used by `gen_random_uuid()`)
- [ ] `supabase db pull` recommended BEFORE running this migration to sync the 5 missing local migration files

### 3.2 Deployment

**Option A: Run via Supabase Dashboard SQL Editor** (recommended for personal build)
1. Copy `supabase/migrations/20260721220000_tool_calls.sql`
2. Paste into https://app.supabase.com/project/kqhyjngtquutzdvjfbnf/sql/new
3. Run
4. Verify: `SELECT * FROM information_schema.columns WHERE table_name = 'tool_calls';`

**Option B: Via CLI (if Docker is available)**
```bash
cd /Users/abdurrahmanjahfali/Projects/Azdal
npx supabase db push --linked
```

### 3.3 Post-Deployment Verification

After migration is applied, confirm live:
```sql
-- Column inventory
SELECT column_name, data_type, is_nullable FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'tool_calls'
ORDER BY ordinal_position;

-- RLS policies
SELECT policyname, cmd FROM pg_policies
WHERE tablename = 'tool_calls';

-- Indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'tool_calls';
```

---

## 4. Design Decisions

### DEC-TOOL-001: `ts` vs `created_at` as primary timestamp

`ts` records the routing-decision moment (populated on INSERT). `created_at` is the row-insertion time. For a row that gets `write_ids` backfilled at confirm time, `ts` stays stable while `updated_at` changes. This matches the OpenTelemetry convention where the span timestamp is the event time, not the persistence time.

### DEC-TOOL-002: `write_ids` as `UUID[]` not JSONB

Postgres native array type gives type safety (can't accidentally store a string) and is indexable via GIN. UUID[] is simpler than JSONB for a homogeneous list of row IDs.

### DEC-TOOL-003: CHECK constraint on `outcome_kind` — strict now, ALTER later

The 6 values cover all Phase 0.5 router outcomes. Future values (`world_results`, etc.) will require an `ALTER TABLE ... DROP CONSTRAINT ... ADD CONSTRAINT` migration — a clean, intentional schema evolution rather than silently accepting typos. The doc 26 `founder_feedback` column is a separate ADD COLUMN migration.

### DEC-TOOL-004: No DELETE policy

Matches the pattern on `transactions` and `goals`. Physical deletion is blocked by RLS; soft-delete is application-level. The `write_ids` backfill uses UPDATE, not INSERT+DELETE.

---

## 5. Open Questions for Lead Architect

1. **Deploy now or with the router?** This migration creates an empty table. It can be deployed ahead of the router code (zero-risk) or bundled with Phase 0.5. Recommended: deploy now — it's a standalone migration with no code dependency, and having it live simplifies the router's Phase 0.5 exit criterion ("`tool_calls` trace table deployed, verified via direct Supabase query").

2. **`supabase db pull` — do it before this migration?** The 5 missing local migration files are a known gap. If `supabase db pull` is run first, this migration's filename should be sequenced after those. If we skip the pull, this migration stands alone. Either works; the pull is cleaner.

3. **`founder_feedback` column (doc 26)?** The world-facing tools research proposes a `founder_feedback` column on `tool_calls` for thumbs up/down on search quality. Not needed now — this migration intentionally omits it. Add via a separate migration when DEC-054 world-facing tools land.

---

## 6. File Inventory

| File | Status |
|------|--------|
| `supabase/migrations/20260721220000_tool_calls.sql` | ✅ Written, ready for deployment |
| `app-spec/27_tool_calls_trace_table.md` | ✅ This document |
| `app-spec/00_lessons_learned.md` | LL-037 entry exists (2026-07-20) |
| `app-spec/12_decision_log.md` | New DEC entries to be added after approval |

---

## 7. Traceability

| Ref | Item |
|-----|------|
| Feature | DEC-050 — Tool-Calling Router |
| Phase | Phase 0.5 (personal build) |
| Spec files read | `00_active_capabilities.md`, `12_decision_log.md`, `00_lessons_learned.md`, `23_research_tool_calling_router.md`, `24_test_seed_fixture.md`, `26_research_world_facing_tools.md`, `INIT-03_supabase_schema.md`, `goal_phase_0.5_tool_calling_router_DRAFT.md`, `goal_phase_0_golden_matrix_and_real_tests_DRAFT.md` |
| Decision IDs | DEC-050, DEC-010 (anti-ghost), DEC-024 (model never computes) |
| Lessons Learned | LL-037 (live schema verification), LL-010 (device+DB verification) |
