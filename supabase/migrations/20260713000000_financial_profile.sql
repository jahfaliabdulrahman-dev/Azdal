-- financial_profile table — durable home for Cold Start estimates
-- Created: 2026-07-13 (DEC-023)

CREATE TABLE IF NOT EXISTS financial_profile (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                         UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,

    monthly_income                  NUMERIC(10,2) CHECK (monthly_income >= 0),
    monthly_commitments_estimate    NUMERIC(10,2) CHECK (monthly_commitments_estimate >= 0),
    weekly_spend_estimate           NUMERIC(10,2) CHECK (weekly_spend_estimate >= 0),
    salary_day                      INT CHECK (salary_day BETWEEN 1 AND 31),
    currency                        TEXT NOT NULL DEFAULT 'SAR',

    is_deleted                      BOOLEAN NOT NULL DEFAULT false,
    deleted_at                      TIMESTAMPTZ,

    created_at                      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger reuses the existing set_updated_at() function

ALTER TABLE financial_profile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "financial_profile_select_own" ON financial_profile
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "financial_profile_insert_own" ON financial_profile
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "financial_profile_update_own" ON financial_profile
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
