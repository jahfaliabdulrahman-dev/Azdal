# INIT-03: Supabase Schema Setup — Azdal (أزدل)

> **Task:** Produce ready-to-run SQL DDL, RLS policies, indexes, and setup checklist.
> **Source:** `app-spec/05_data_model_erd.md`, `17_data_architecture_acid_constraints.md`, `08_security_privacy.md`
> **Date:** 2026-07-12
> **Status:** Planning artifact — ready for execution when Supabase credentials are available.

---

## ⚠️ Schema Issues & Improvements Identified

Before running the SQL, review these issues found during cross-referencing the three spec files:

### Issue 1: Missing `updated_at` on commitments, goals, and purchase_decisions
- **ERD says:** Only `created_at` is listed for commitments, goals, and purchase_decisions.
- **ACID/audit rule says:** "All mutations logged (created_at, updated_at)."
- **Fix applied below:** Added `updated_at TIMESTAMPTZ DEFAULT now()` to commitments, goals, and purchase_decisions. The SQL includes a trigger function that auto-sets `updated_at` on any row modification.

### Issue 2: Missing `deleted_at` on commitments and goals
- **ERD says:** `is_deleted BOOLEAN` exists but `deleted_at` is only on transactions.
- **Anti-ghost protocol says:** Both flags are needed.
- **Fix applied below:** Added `deleted_at TIMESTAMPTZ` to commitments and goals.

### Issue 3: Missing CHECK constraints on enum-like text fields
- **ERD declares:** `transactions.type` = 'income'|'expense', `transactions.tone` = 'green'|'gray'|'red', `commitments.type` = 'bnpl'|'rent'|'loan'|'subscription', `commitments.status` = 'active'|'paused'|'completed', `goals.status` = 'active'|'paused'|'achieved', `purchase_decisions.verdict` = 'yes'|'wait'|'no'.
- **No CHECK constraints in ERD.**
- **Fix applied below:** Added CHECK constraints on all enum-like text columns.

### Issue 4: Transaction `group_id` self-referencing FK semantics
- **ERD:** `group_id` FK → transactions.id for compound splits.
- **ACID doc:** "No orphaned group_id references | FK with CASCADE SET NULL."
- **Problem:** Since we never hard-delete (anti-ghost), CASCADE SET NULL on DELETE will never fire. This FK provides referential integrity for active records but won't cascade. When a parent transaction is **soft-deleted**, the children's `group_id` won't auto-nullify — the application must handle this.
- **Applied:** FK with `ON DELETE SET NULL` for correctness, but soft-delete cascade is an **application concern**.
- **Recommendation:** Create a Supabase trigger or Edge Function that sets `group_id = NULL` on child transactions when a parent is soft-deleted. Documented in the checklist below.

### Issue 5: No CHECK constraints on financial amount fields beyond transactions
- **`commitments.total_amount`, `commitments.monthly_amount`** — no `> 0` check.
- **`commitments.remaining`** — ACID doc says "remaining ≥ 0" (app logic), no DB constraint.
- **`goals.target_amount`, `goals.monthly_contribution`** — no `> 0` check.
- **Fix applied below:** Added CHECK > 0 on total_amount, monthly_amount, target_amount, monthly_contribution. Added CHECK >= 0 on remaining.

### Issue 6: `integrity_scores` sub-score fields have no range validation
- **Fields:** `logging_consistency`, `receipt_upload_rate`, `data_match_accuracy`, `response_time_factor`, `no_deletion_rate` — all `numeric(5,2)`.
- **The `_rate` suffix implies 0–100 or 0–1.** The `numeric(5,2)` type (max 999.99) is too wide.
- **Fix applied below:** Added CHECK 0–100 on all sub-score fields to match the `score` range semantics. If the actual range is 0.00–1.00, adjust before running.

### Issue 7: `transactions.receipt_items` — no GIN index for JSONB queries
- **ERD:** No index for receipt_items JSONB column.
- **Recommendation:** If the app queries by OCR line-item content (e.g., "find all transactions containing 'قهوة'"), add a GIN index. Added as optional in the index section.

### Issue 8: `purchase_decisions` — no `is_deleted` column
- **Confirmed intentional:** ACID doc explicitly classifies purchase_decisions as "Audit table — never deleted."
- **No change needed.** RLS policies allow INSERT + SELECT only (no UPDATE, no DELETE).

### Issue 9: `integrity_scores.user_id` UNIQUE but no `is_deleted`
- **ERD:** UNIQUE constraint on user_id (one score per user), but no anti-ghost fields.
- **ACID anti-ghost table:** Does NOT list integrity_scores (only transactions, commitments, goals, purchase_decisions).
- **Verdict:** Intentional. Integrity scores are recalculated in-place. No anti-ghost needed. If this changes, a separate `integrity_score_history` table would be the right pattern.

---

## 1. Complete SQL DDL

Paste the blocks below into the **Supabase SQL Editor** (`https://app.supabase.com/project/<ref>/sql/new`), in order.

### 1.0 — Extensions & Helper Trigger

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 0: Extensions & Utilities
-- ============================================================================

-- Ensure pgcrypto is available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------------
-- Helper function: auto-set updated_at on row modification
-- Must be created before any table with updated_at
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 1.1 — `commitments` Table

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 1: commitments
-- ============================================================================

CREATE TABLE commitments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    name            TEXT NOT NULL,
    provider        TEXT,
    total_amount    NUMERIC(10,2) NOT NULL CHECK (total_amount > 0),
    remaining       NUMERIC(10,2) NOT NULL CHECK (remaining >= 0),
    monthly_amount  NUMERIC(10,2) NOT NULL CHECK (monthly_amount > 0),
    type            TEXT NOT NULL CHECK (type IN ('bnpl', 'rent', 'loan', 'subscription')),
    status          TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'paused', 'completed')),
    url             TEXT,

    -- Anti-ghost protocol (soft delete)
    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: auto-update updated_at
CREATE TRIGGER trg_commitments_updated_at
    BEFORE UPDATE ON commitments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 1.2 — `goals` Table

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 2: goals
-- ============================================================================

CREATE TABLE goals (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    name                  TEXT NOT NULL,
    target_amount         NUMERIC(10,2) NOT NULL CHECK (target_amount > 0),
    current_amount        NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    monthly_contribution  NUMERIC(10,2) NOT NULL CHECK (monthly_contribution > 0),
    priority              INT NOT NULL DEFAULT 1 CHECK (priority >= 1),
    status                TEXT NOT NULL DEFAULT 'active'
                              CHECK (status IN ('active', 'paused', 'achieved')),
    achieved_at           TIMESTAMPTZ,

    -- Anti-ghost protocol (soft delete)
    is_deleted            BOOLEAN NOT NULL DEFAULT false,
    deleted_at            TIMESTAMPTZ,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: auto-update updated_at
CREATE TRIGGER trg_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 1.3 — `integrity_scores` Table

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 3: integrity_scores
-- ============================================================================

CREATE TABLE integrity_scores (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

    score                 INT NOT NULL CHECK (score >= 0 AND score <= 100),

    -- Sub-scores (0–100 scale; adjust to 0.00–1.00 if that's the intended range)
    logging_consistency   NUMERIC(5,2) CHECK (logging_consistency >= 0 AND logging_consistency <= 100),
    receipt_upload_rate   NUMERIC(5,2) CHECK (receipt_upload_rate >= 0 AND receipt_upload_rate <= 100),
    data_match_accuracy   NUMERIC(5,2) CHECK (data_match_accuracy >= 0 AND data_match_accuracy <= 100),
    response_time_factor  NUMERIC(5,2) CHECK (response_time_factor >= 0 AND response_time_factor <= 100),
    no_deletion_rate      NUMERIC(5,2) CHECK (no_deletion_rate >= 0 AND no_deletion_rate <= 100),

    calculated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- NOTE: No anti-ghost on integrity_scores. Scores are recalculated in-place.
    -- Historical tracking would use a separate integrity_score_history table.
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: auto-update updated_at
CREATE TRIGGER trg_integrity_scores_updated_at
    BEFORE UPDATE ON integrity_scores
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 1.4 — `purchase_decisions` Table

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 4: purchase_decisions
-- ============================================================================

CREATE TABLE purchase_decisions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    query             TEXT NOT NULL,
    verdict           TEXT NOT NULL CHECK (verdict IN ('yes', 'wait', 'no')),
    disposable_income NUMERIC(10,2),
    goal_impact       JSONB,
    explanation       TEXT NOT NULL,

    -- Audit table — never soft-deleted (per ACID constraints doc)
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: auto-update updated_at (though rows should rarely be updated)
CREATE TRIGGER trg_purchase_decisions_updated_at
    BEFORE UPDATE ON purchase_decisions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 1.5 — `transactions` Table

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 5: transactions
-- ============================================================================

CREATE TABLE transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    category        TEXT NOT NULL,
    subcategory     TEXT,
    description     TEXT,
    type            TEXT NOT NULL DEFAULT 'expense'
                        CHECK (type IN ('income', 'expense')),
    tone            TEXT NOT NULL DEFAULT 'gray'
                        CHECK (tone IN ('green', 'gray', 'red')),

    -- Receipt storage
    receipt_url     TEXT,
    receipt_items   JSONB,

    -- Compound transaction (self-referencing FK — see note below)
    group_id        UUID,
    -- FK added via ALTER TABLE below to avoid forward-reference issues

    -- Commitment link
    is_commitment   BOOLEAN NOT NULL DEFAULT false,
    commitment_id   UUID,
    -- FK added via ALTER TABLE below

    -- Anti-ghost protocol
    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: auto-update updated_at
CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### 1.6 — Foreign Keys (cross-table & self-referencing)

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 6: Foreign Keys
-- ============================================================================

-- transactions.commitment_id → commitments.id
ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_commitment
    FOREIGN KEY (commitment_id) REFERENCES commitments(id)
    ON DELETE SET NULL;

-- transactions.group_id → transactions.id (self-referencing for compound splits)
ALTER TABLE transactions
    ADD CONSTRAINT fk_transactions_group
    FOREIGN KEY (group_id) REFERENCES transactions(id)
    ON DELETE SET NULL;
```

---

## 2. RLS Policies

Enable RLS on all tables and create per-table policies.

### 2.1 — Enable RLS

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 7: Enable Row Level Security
-- ============================================================================

ALTER TABLE commitments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrity_scores   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
```

### 2.2 — `commitments` RLS Policies

```sql
-- ------------------------------------------------------------------
-- commitments: Users can SELECT their own (including soft-deleted)
-- ------------------------------------------------------------------
CREATE POLICY "commitments_select_own" ON commitments
    FOR SELECT
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- commitments: Users can INSERT their own rows
-- ------------------------------------------------------------------
CREATE POLICY "commitments_insert_own" ON commitments
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- commitments: Users can UPDATE their own rows
--   Application is responsible for setting is_deleted + deleted_at
--   instead of issuing DELETE. No DELETE policy = physical delete blocked.
-- ------------------------------------------------------------------
CREATE POLICY "commitments_update_own" ON commitments
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### 2.3 — `goals` RLS Policies

```sql
-- ------------------------------------------------------------------
-- goals: Users can SELECT their own
-- ------------------------------------------------------------------
CREATE POLICY "goals_select_own" ON goals
    FOR SELECT
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- goals: Users can INSERT their own
-- ------------------------------------------------------------------
CREATE POLICY "goals_insert_own" ON goals
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- goals: Users can UPDATE their own (includes soft-delete)
-- ------------------------------------------------------------------
CREATE POLICY "goals_update_own" ON goals
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### 2.4 — `integrity_scores` RLS Policies

```sql
-- ------------------------------------------------------------------
-- integrity_scores: Users can SELECT only their own score
-- ------------------------------------------------------------------
CREATE POLICY "integrity_scores_select_own" ON integrity_scores
    FOR SELECT
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- integrity_scores: Users can INSERT their score (one-time)
--   The UNIQUE constraint on user_id prevents duplicate scores.
-- ------------------------------------------------------------------
CREATE POLICY "integrity_scores_insert_own" ON integrity_scores
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- integrity_scores: Users can UPDATE their own score
--   This allows the Edge Function to recalculate and overwrite.
-- ------------------------------------------------------------------
CREATE POLICY "integrity_scores_update_own" ON integrity_scores
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

### 2.5 — `purchase_decisions` RLS Policies

```sql
-- ------------------------------------------------------------------
-- purchase_decisions: Users can SELECT their own audit history
-- ------------------------------------------------------------------
CREATE POLICY "purchase_decisions_select_own" ON purchase_decisions
    FOR SELECT
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- purchase_decisions: Edge Function / app inserts decision records
-- ------------------------------------------------------------------
CREATE POLICY "purchase_decisions_insert_own" ON purchase_decisions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- NOTE: No UPDATE or DELETE policies — audit table, immutable once written.
-- Physical DELETE is blocked (no DELETE policy + RLS enabled = deny by default).
```

### 2.6 — `transactions` RLS Policies

```sql
-- ------------------------------------------------------------------
-- transactions: Users can SELECT their own
-- ------------------------------------------------------------------
CREATE POLICY "transactions_select_own" ON transactions
    FOR SELECT
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- transactions: Users can INSERT their own
-- ------------------------------------------------------------------
CREATE POLICY "transactions_insert_own" ON transactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- transactions: Users can UPDATE their own (includes soft-delete)
-- ------------------------------------------------------------------
CREATE POLICY "transactions_update_own" ON transactions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
```

---

## 3. Indexes

### 3.1 — Required Indexes (per ERD)

```sql
-- ============================================================================
-- INIT-03: Azdal Schema Setup — Part 8: Indexes
-- ============================================================================

-- transactions: Fast date-range lookups per user (dashboard, history)
CREATE INDEX idx_transactions_user_date
    ON transactions (user_id, created_at DESC);

-- transactions: Compound transaction grouping queries
CREATE INDEX idx_transactions_group
    ON transactions (group_id) WHERE group_id IS NOT NULL;

-- transactions: Filter by tone (green/gray/red) for "Can I buy?" engine
CREATE INDEX idx_transactions_tone
    ON transactions (user_id, tone);
```

### 3.2 — Recommended Additional Indexes (not in ERD, strongly advised)

```sql
-- ------------------------------------------------------------------
-- Additional recommended indexes for query patterns
-- ------------------------------------------------------------------

-- transactions: Soft-delete filter (most queries add WHERE is_deleted = false)
CREATE INDEX idx_transactions_active
    ON transactions (user_id, created_at DESC)
    WHERE is_deleted = false;

-- transactions: Commitment-linked transaction queries
CREATE INDEX idx_transactions_commitment
    ON transactions (commitment_id) WHERE commitment_id IS NOT NULL;

-- commitments: Active commitments per user
CREATE INDEX idx_commitments_active
    ON commitments (user_id) WHERE is_deleted = false AND status = 'active';

-- goals: Active goals per user, by priority
CREATE INDEX idx_goals_active
    ON goals (user_id, priority) WHERE is_deleted = false AND status = 'active';

-- purchase_decisions: Recent decisions per user (dashboard)
CREATE INDEX idx_purchase_decisions_user_date
    ON purchase_decisions (user_id, created_at DESC);

-- integrity_scores: Fast lookup by user (backed by UNIQUE already, but explicit)
CREATE INDEX idx_integrity_scores_user
    ON integrity_scores (user_id);

-- transactions: Lookup by category (AI-classified category analysis)
CREATE INDEX idx_transactions_category
    ON transactions (user_id, category) WHERE is_deleted = false;
```

### 3.3 — Optional: GIN Index for JSONB receipt_items

```sql
-- ------------------------------------------------------------------
-- OPTIONAL: GIN index for querying JSONB receipt_items
--   Enable this if the app searches OCR line items (e.g., "find 'قهوة'")
-- ------------------------------------------------------------------
-- CREATE INDEX idx_transactions_receipt_items_gin
--     ON transactions USING GIN (receipt_items);
```

---

## 4. Setup Checklist

### 4.1 — Prerequisites

Before executing any SQL, gather these from your Supabase dashboard:

| # | Item | Where to find it | Purpose |
|---|------|-----------------|---------|
| 1 | **Supabase project URL** | `https://app.supabase.com/project/<ref>/settings/api` | Flutter `Supabase.initialize()` |
| 2 | **Supabase anon key** | Same page, `anon public` key | Flutter client auth |
| 3 | **Supabase service_role key** | Same page, `service_role` secret | Edge Functions / admin operations (keep secret!) |
| 4 | **Database password** | Set during project creation | SQL Editor access |
| 5 | **Project reference** | URL slug (e.g., `abcdefghijklm`) | SQL Editor URL |

### 4.2 — Execution Steps

1. **Log in** to [app.supabase.com](https://app.supabase.com) and select your project.
2. **Open SQL Editor**: Sidebar → SQL Editor → New Query.
3. **Copy-paste** the SQL blocks from this document in order:
   - Part 0: Extensions & `set_updated_at()` function
   - Part 1–5: CREATE TABLE statements (commitments, goals, integrity_scores, purchase_decisions, transactions)
   - Part 6: ALTER TABLE FK constraints
   - Part 7: ENABLE ROW LEVEL SECURITY + all policies
   - Part 8: CREATE INDEX statements
4. **Run each block** (or paste all at once — they're order-safe).
5. **Verify** in the Table Editor: all 5 tables should appear.
6. **Test RLS** by creating a test user in Authentication → Users, then querying via the API with that user's JWT — you should only see that user's rows.

### 4.3 — Supabase Project Settings to Configure

| Setting | Recommended Value | Why |
|---------|-------------------|-----|
| **Auth → Email Auth** | Disable email confirmations (for MVP/dev) | Faster testing |
| **Auth → JWT expiry** | 3600 seconds (1 hour) | Balance security and UX |
| **Database → Extensions** | Ensure `pgcrypto` is ON | Required for `gen_random_uuid()` |
| **API → Realtime** | OFF (not needed for MVP) | Simpler setup |
| **Storage** | Create a bucket named `receipts` | For `receipt_url` in transactions |

### 4.4 — Environment Variables for Flutter App

Add these to your Flutter project (`.env` or direct config):

```
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJhbG...  (your anon key)
```

### 4.5 — Post-Execution: Application-Level Concerns

1. **Soft-delete cascade for compound transactions:** When a parent transaction is soft-deleted (`is_deleted = true`, `deleted_at = now()`), the application (or a Supabase trigger) must set `group_id = NULL` on all child transactions. The FK's `ON DELETE SET NULL` only fires on physical DELETE — which never happens.

2. **Transaction idempotency:** Implement client-side deduplication using `(user_id, amount, created_at, md5(description))` within a 60-second window (per ACID constraints doc).

3. **Integrity score recalculation:** The Edge Function that recalculates scores should:
   - SELECT existing score row by user_id
   - UPDATE if exists, INSERT if not
   - Use the UNIQUE constraint on user_id for upsert safety

4. **Purchase decision caching:** Implement a 5-minute cache using `(user_id, md5(query))` as the idempotency key before inserting a new purchase_decisions row.

5. **`goals.current_amount` validation:** The app must enforce `target_amount > current_amount` — there is no DB-level CHECK for this cross-column constraint.

---

## 5. Quick-Start: Run Everything At Once

Copy this entire block and paste into Supabase SQL Editor as a single execution. All parts are ordered correctly:

```sql
-- ========================================================================
-- AZDAL INIT-03: Full Schema Setup (single-execution version)
-- Copy this ENTIRE block into Supabase SQL Editor → Run
-- ========================================================================

-- 0. EXTENSIONS & UTILITIES ------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. TABLES (in dependency order) ------------------------------------------

-- 1.1 commitments
CREATE TABLE IF NOT EXISTS commitments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    provider        TEXT,
    total_amount    NUMERIC(10,2) NOT NULL CHECK (total_amount > 0),
    remaining       NUMERIC(10,2) NOT NULL CHECK (remaining >= 0),
    monthly_amount  NUMERIC(10,2) NOT NULL CHECK (monthly_amount > 0),
    type            TEXT NOT NULL CHECK (type IN ('bnpl', 'rent', 'loan', 'subscription')),
    status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    url             TEXT,
    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_commitments_updated_at BEFORE UPDATE ON commitments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 1.2 goals
CREATE TABLE IF NOT EXISTS goals (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    target_amount         NUMERIC(10,2) NOT NULL CHECK (target_amount > 0),
    current_amount        NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    monthly_contribution  NUMERIC(10,2) NOT NULL CHECK (monthly_contribution > 0),
    priority              INT NOT NULL DEFAULT 1 CHECK (priority >= 1),
    status                TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'achieved')),
    achieved_at           TIMESTAMPTZ,
    is_deleted            BOOLEAN NOT NULL DEFAULT false,
    deleted_at            TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 1.3 integrity_scores
CREATE TABLE IF NOT EXISTS integrity_scores (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    score                 INT NOT NULL CHECK (score >= 0 AND score <= 100),
    logging_consistency   NUMERIC(5,2) CHECK (logging_consistency >= 0 AND logging_consistency <= 100),
    receipt_upload_rate   NUMERIC(5,2) CHECK (receipt_upload_rate >= 0 AND receipt_upload_rate <= 100),
    data_match_accuracy   NUMERIC(5,2) CHECK (data_match_accuracy >= 0 AND data_match_accuracy <= 100),
    response_time_factor  NUMERIC(5,2) CHECK (response_time_factor >= 0 AND response_time_factor <= 100),
    no_deletion_rate      NUMERIC(5,2) CHECK (no_deletion_rate >= 0 AND no_deletion_rate <= 100),
    calculated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_integrity_scores_updated_at BEFORE UPDATE ON integrity_scores FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 1.4 purchase_decisions
CREATE TABLE IF NOT EXISTS purchase_decisions (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    query             TEXT NOT NULL,
    verdict           TEXT NOT NULL CHECK (verdict IN ('yes', 'wait', 'no')),
    disposable_income NUMERIC(10,2),
    goal_impact       JSONB,
    explanation       TEXT NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_purchase_decisions_updated_at BEFORE UPDATE ON purchase_decisions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 1.5 transactions (FKs added after table creation)
CREATE TABLE IF NOT EXISTS transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    category        TEXT NOT NULL,
    subcategory     TEXT,
    description     TEXT,
    type            TEXT NOT NULL DEFAULT 'expense' CHECK (type IN ('income', 'expense')),
    tone            TEXT NOT NULL DEFAULT 'gray' CHECK (tone IN ('green', 'gray', 'red')),
    receipt_url     TEXT,
    receipt_items   JSONB,
    group_id        UUID,
    is_commitment   BOOLEAN NOT NULL DEFAULT false,
    commitment_id   UUID,
    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 2. FOREIGN KEYS (cross-table) ---------------------------------------------
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_commitment FOREIGN KEY (commitment_id) REFERENCES commitments(id) ON DELETE SET NULL;
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_group    FOREIGN KEY (group_id)      REFERENCES transactions(id) ON DELETE SET NULL;

-- 3. ROW LEVEL SECURITY ----------------------------------------------------
ALTER TABLE commitments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrity_scores   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;

-- commitments
CREATE POLICY "commitments_select_own" ON commitments FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "commitments_insert_own" ON commitments FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "commitments_update_own" ON commitments FOR UPDATE  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- goals
CREATE POLICY "goals_select_own" ON goals FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "goals_insert_own" ON goals FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "goals_update_own" ON goals FOR UPDATE  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- integrity_scores
CREATE POLICY "integrity_scores_select_own" ON integrity_scores FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "integrity_scores_insert_own" ON integrity_scores FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "integrity_scores_update_own" ON integrity_scores FOR UPDATE  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- purchase_decisions (audit table — SELECT + INSERT only, no UPDATE/DELETE)
CREATE POLICY "purchase_decisions_select_own" ON purchase_decisions FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "purchase_decisions_insert_own" ON purchase_decisions FOR INSERT  WITH CHECK (auth.uid() = user_id);

-- transactions
CREATE POLICY "transactions_select_own" ON transactions FOR SELECT  USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert_own" ON transactions FOR INSERT  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "transactions_update_own" ON transactions FOR UPDATE  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. INDEXES -----------------------------------------------------------------
CREATE INDEX idx_transactions_user_date     ON transactions (user_id, created_at DESC);
CREATE INDEX idx_transactions_group         ON transactions (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_transactions_tone          ON transactions (user_id, tone);
CREATE INDEX idx_transactions_active        ON transactions (user_id, created_at DESC) WHERE is_deleted = false;
CREATE INDEX idx_transactions_commitment    ON transactions (commitment_id) WHERE commitment_id IS NOT NULL;
CREATE INDEX idx_transactions_category      ON transactions (user_id, category) WHERE is_deleted = false;
CREATE INDEX idx_commitments_active         ON commitments (user_id) WHERE is_deleted = false AND status = 'active';
CREATE INDEX idx_goals_active               ON goals (user_id, priority) WHERE is_deleted = false AND status = 'active';
CREATE INDEX idx_purchase_decisions_user_date ON purchase_decisions (user_id, created_at DESC);
CREATE INDEX idx_integrity_scores_user      ON integrity_scores (user_id);
```

---

## 6. Verification Queries

Run these after executing the schema to confirm everything is correct:

```sql
-- List all Azdal tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('transactions', 'commitments', 'goals', 'integrity_scores', 'purchase_decisions')
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('transactions', 'commitments', 'goals', 'integrity_scores', 'purchase_decisions');

-- List all policies
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- List all indexes
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('transactions', 'commitments', 'goals', 'integrity_scores', 'purchase_decisions')
ORDER BY tablename;
```

---

## 7. Next Steps

After this schema is executed:

1. **INIT-04**: Create Supabase Edge Functions for:
   - `calculate-integrity-score` — Score recalculation engine
   - `can-i-buy` — Purchase decision endpoint
   - `process-commitment` — Commitment lifecycle management

2. **INIT-05**: Set up Supabase Storage bucket `receipts` with RLS policies.

3. **INIT-06**: Configure Flutter Supabase client with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

4. **Application work**: Implement the soft-delete cascade trigger for compound transactions (see Issue 4 in the issues section above).

---

*End of INIT-03 deliverable. Ready for execution when Supabase project credentials are available.*
