-- ============================================================================
-- tool_calls trace table — single-row-per-routed-message audit log
-- Created: 2026-07-21 (DEC-050, Phase 0.5 router infra, LL-037 verified)
-- Purpose: Record every intent-routing decision the LLM makes,
--   turning manual verify-by-Supabase-query rituals into a lookup.
--   One row per function call — message → tool → args → outcome.
-- Anti-ghost: is_deleted + deleted_at soft-delete (no physical DELETE).
-- RLS: own-rows-only (SELECT/INSERT/UPDATE; no DELETE policy).
-- ============================================================================

-- ------------------------------------------------------------------
-- TABLE
-- ------------------------------------------------------------------
CREATE TABLE tool_calls (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- The raw user message that triggered this routing decision
    message_text    TEXT NOT NULL,

    -- Model that chose the tool (e.g. 'gemini-flash-latest')
    model           TEXT NOT NULL,

    -- Round-trip latency from generateContent call to parsed response (ms)
    latency_ms      INTEGER CHECK (latency_ms >= 0),

    -- The tool the model chose (matches RouterTool.name)
    tool_name       TEXT NOT NULL,

    -- Parsed + validated arguments the tool received (Arabic-Indic normalized)
    args            JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Outcome classification (see CHECK below for semantics)
    outcome_kind    TEXT NOT NULL
                    CHECK (outcome_kind IN (
                        'render',        -- read-only tool, widget rendered
                        'staged',        -- write tool, proposal staged for confirmation
                        'clarify',       -- missing required args, user must clarify
                        'invalid_args',  -- parseArgs validation rejected the arguments
                        'unknown_tool',  -- model hallucinated a non-existent tool name
                        'error'          -- any other failure (network, service threw, etc.)
                    )),

    -- Compact summary of the tool's outcome (verdict, score, disposable, etc.)
    -- Null when outcome_kind is 'invalid_args', 'unknown_tool', or 'error'
    result_summary  JSONB,

    -- UUIDs of SUPABASE ROWS created at confirm time for a staged proposal.
    -- Filled later (not at staging), so a trace row tells the full lifecycle.
    write_ids       UUID[],

    -- Error message when outcome_kind demands it (invalid_args / unknown_tool / error)
    error           TEXT,

    -- Anti-ghost protocol
    is_deleted      BOOLEAN NOT NULL DEFAULT false,
    deleted_at      TIMESTAMPTZ,

    -- OpenTelemetry GenAI semantic convention naming where applicable
    -- gen_ai.tool.name → tool_name; gen_ai.request.model → model
    ts              TIMESTAMPTZ NOT NULL DEFAULT now(),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------------
-- TRIGGER: auto-update updated_at (reuses existing set_updated_at())
-- ------------------------------------------------------------------
CREATE TRIGGER trg_tool_calls_updated_at
    BEFORE UPDATE ON tool_calls
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ------------------------------------------------------------------
-- RLS: enable + own-rows-only policies
-- ------------------------------------------------------------------
ALTER TABLE tool_calls ENABLE ROW LEVEL SECURITY;

-- SELECT: users can read their own trace rows
CREATE POLICY "tool_calls_select_own" ON tool_calls
    FOR SELECT
    USING (auth.uid() = user_id);

-- INSERT: users can insert their own trace rows
CREATE POLICY "tool_calls_insert_own" ON tool_calls
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: users can update their own trace rows (fill write_ids, mark soft-delete)
CREATE POLICY "tool_calls_update_own" ON tool_calls
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- NOTE: No DELETE policy — physical delete is blocked by RLS deny-by-default.
-- Application-level soft-delete only (UPDATE is_deleted=true, deleted_at=now()).

-- ------------------------------------------------------------------
-- INDEXES: primary access patterns
-- ------------------------------------------------------------------

-- Primary: recent trace rows for the current user (the "dashboard" query)
CREATE INDEX idx_tool_calls_user_ts
    ON tool_calls (user_id, ts DESC);

-- Filter by outcome (error audit, staged-proposal review)
CREATE INDEX idx_tool_calls_outcome
    ON tool_calls (user_id, outcome_kind)
    WHERE is_deleted = false;

-- Tool-name drilldown (how often was evaluate_purchase called?)
CREATE INDEX idx_tool_calls_tool
    ON tool_calls (user_id, tool_name)
    WHERE is_deleted = false;

