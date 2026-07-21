-- ============================================================================
-- Azdal Schema Setup — Core Tables (Deployed via SQL Editor 2026-07-21)
-- Tables: commitments, goals, integrity_scores, purchase_decisions, transactions
-- This file created retroactively from INIT-03_supabase_schema.md per LL-037
-- ============================================================================

-- Ensure pgcrypto is available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Helper function: auto-set updated_at on row modification
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Part 1: commitments
-- ============================================================================

CREATE TABLE IF NOT EXISTS commitments (
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

    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_commitments_updated_at
    BEFORE UPDATE ON commitments
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Part 2: goals
-- ============================================================================

CREATE TABLE IF NOT EXISTS goals (
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

    is_deleted            BOOLEAN NOT NULL DEFAULT false,
    deleted_at            TIMESTAMPTZ,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_goals_updated_at
    BEFORE UPDATE ON goals
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Part 3: integrity_scores
-- ============================================================================

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

CREATE TRIGGER trg_integrity_scores_updated_at
    BEFORE UPDATE ON integrity_scores
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Part 4: purchase_decisions
-- ============================================================================

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

CREATE TRIGGER trg_purchase_decisions_updated_at
    BEFORE UPDATE ON purchase_decisions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Part 5: transactions
-- ============================================================================

CREATE TABLE IF NOT EXISTS transactions (
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

CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- Part 6: Foreign Keys
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_transactions_commitment') THEN
        ALTER TABLE transactions
            ADD CONSTRAINT fk_transactions_commitment
            FOREIGN KEY (commitment_id) REFERENCES commitments(id)
            ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_transactions_group') THEN
        ALTER TABLE transactions
            ADD CONSTRAINT fk_transactions_group
            FOREIGN KEY (group_id) REFERENCES transactions(id)
            ON DELETE SET NULL;
    END IF;
END;
$$;

-- ============================================================================
-- Part 7: Row Level Security
-- ============================================================================

ALTER TABLE commitments        ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE integrity_scores   ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;

-- commitments
CREATE POLICY "commitments_select_own" ON commitments
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "commitments_insert_own" ON commitments
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "commitments_update_own" ON commitments
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- goals
CREATE POLICY "goals_select_own" ON goals
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "goals_insert_own" ON goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "goals_update_own" ON goals
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- integrity_scores
CREATE POLICY "integrity_scores_select_own" ON integrity_scores
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "integrity_scores_insert_own" ON integrity_scores
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "integrity_scores_update_own" ON integrity_scores
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- purchase_decisions (audit table: no UPDATE/DELETE)
CREATE POLICY "purchase_decisions_select_own" ON purchase_decisions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "purchase_decisions_insert_own" ON purchase_decisions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- transactions
CREATE POLICY "transactions_select_own" ON transactions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert_own" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "transactions_update_own" ON transactions
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- Part 8: Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
    ON transactions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_group
    ON transactions (group_id) WHERE group_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transactions_tone
    ON transactions (user_id, tone);
CREATE INDEX IF NOT EXISTS idx_transactions_active
    ON transactions (user_id, created_at DESC) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_transactions_commitment
    ON transactions (commitment_id) WHERE commitment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_commitments_active
    ON commitments (user_id) WHERE is_deleted = false AND status = 'active';
CREATE INDEX IF NOT EXISTS idx_goals_active
    ON goals (user_id, priority) WHERE is_deleted = false AND status = 'active';
CREATE INDEX IF NOT EXISTS idx_purchase_decisions_user_date
    ON purchase_decisions (user_id, created_at DESC);
