# 🛡️ SCSI GUARDIAN — Hunt Report
**Hunt #:** 1 | **Date:** 2026-07-21 07:30 UTC
**Epic:** DEC-050 Tool-Calling Router Migration
**Files scanned:** 13 router/tool/chat files + providers + migrations + tests
**Patterns matched:** 3 (from pattern DB + live-system cross-check)
**Bugs found:** 0 CRITICAL, 4 MEDIUM, 3 LOW

---

## ✅ CLEAN (verified safe)

| Area | Status |
|------|--------|
| **flutter test** | 59/59 PASSING ✅ |
| **flutter analyze** | 0 errors, 33 info/warnings (all pre-existing `avoid_print`, unused elements) |
| **Router wired into chat_screen.dart** | Verified — `_sendMessage()` calls `route()` → `routerLlm.route()` → processes `ToolOutcome` variants (Render/Clarify/Staged) |
| **Router dispatch flow** | Single-hop, cap ≤2, deterministic bail — matches DEC-050 spec §2 |
| **DEC-050 discipline rules** | All 5 rules codified in code: (1) coarse verdict-shaped tools, (2) write-tools return StagedProposal, (3) Dart-rendered widgets, (4) hard-cap 2 → bail, (5) state block never raw transcript |
| **StagedProposal tiered approval** | `log_expense` → autoSaveWithUndo, `add_commitment`/`add_goal`/`log_compound_expense` → confirmCard — DEC-020/021 preserved |
| **Arabic-Indic digit normalization** | `_normalizeDigits()` in tools.dart handles ٠-٩ → 0-9 + comma stripping |
| **Mutation check evidence** | 2 suites (integrity + purchase DTI), GREEN/RED pairs captured at `test/fixtures/mutation_evidence/` |
| **Golden intent matrix** | 32-row JSONL at `test/fixtures/golden_intent_matrix.jsonl` + harness at `test/golden_intent_matrix_test.dart` — tests the OLD IntentRouter (correct baseline for migration) |
| **IntentRouter extraction** | `lib/features/chat/routing/intent_router.dart` — extracted verbatim from chat_screen.dart (MD5 of regexes preserved per DEC-051) |
| **tool_calls migration file quality** | `supabase/migrations/20260721220000_tool_calls.sql` — well-structured: UUID PK, RLS (own-rows-only), CHECK constraints on outcome_kind, 3 targeted indexes, soft-delete support, OpenTelemetry naming. Migration file itself is clean. |

---

## 🟡 MEDIUM findings

### MED-1: Live Supabase missing `tool_calls` table — migration never applied

| Field | Detail |
|-------|--------|
| **What** | The migration `supabase/migrations/20260721220000_tool_calls.sql` exists in the repo but the live Supabase at `kqhyjngtquutzdvjfbnf.supabase.co` returns `PGRST205: Could not find the table 'public.tool_calls' in the schema cache` |
| **Impact** | The tool-call audit trace (one row per routed message: message → tool → args → outcome) described in DEC-050 does not exist on the live backend. Any future `logToolCall()` function would fail at runtime. |
| **Root cause** | Migration file was created as Phase 0.5 infrastructure but never pushed to Supabase via `supabase db push` or `supabase migration up` |
| **Suggested gate** | Gate: every migration file → verify `supabase db push` was actually executed (confirm table exists on live) before closing the task that created it. OR: the `supabase db push` command should have been part of the task that created the migration. |

### MED-2: Deprecated `google_generative_ai` 0.4.x still in use — SDK migration deferred

| Field | Detail |
|-------|--------|
| **What** | `pubspec.yaml` pins `google_generative_ai: ^0.4.0` (deprecated, frozen since April 2025). DEC-050 explicitly says "SDK decision (flipped 2026-07-21): Primary: googleai_dart" but the code was built ON TOP OF the deprecated package. The `GeminiRouterLlm` class in `router_llm.dart` directly imports `package:google_generative_ai`. |
| **Impact** | Risk of API rot — the deprecated package will never see Gemini-3 updates, bug fixes, or security patches. Building the router on a deprecated foundation means migrating twice (once to get it working, again to switch SDKs). |
| **Root cause** | DEC-050's SDK decision was "flipped" at the decision-log level but the implementation shipped on the old SDK because Phase 0.5 is still in-progress. The `RouterLlm` interface exists as an abstraction layer but the only implementation uses the deprecated package. |
| **Suggested gate** | When DEC-050 Phase 0.5 completes: gate checks that `google_generative_ai` is removed from `pubspec.yaml` dependencies AND that `router_llm.dart` imports the replacement SDK (`googleai_dart` or `firebase_ai`). |

### MED-3: Zero unit tests for the new Tool-Calling Router

| Field | Detail |
|-------|--------|
| **What** | The new router code (`route.dart`, `router_llm.dart`, `tool_types.dart`, `tools.dart` — ~1,200 lines) has **zero unit tests**. The only router test (`test/intent_router_test.dart`) tests the OLD regex-based `IntentRouter`, not the new Gemini function-calling router. |
| **Impact** | Any regression in `route()`, `parseArgs()`, `ToolRegistry[]`, or `_normalizeDigits()` would be caught only by manual testing. The mutation check only covers integrity_score and purchase_decision services — not the router itself. |
| **Root cause** | The router was built with the LLM interface abstracted (`RouterLlm`) specifically for testability — a `FakeRouterLlm` was envisioned but never implemented. Phase 0.5 is in-progress; tests are likely a planned artifact. |
| **Suggested gate** | Before marking Phase 0.5 complete: require at minimum (a) `FakeRouterLlm` with recorded routings, (b) unit tests for `ToolRegistry` (hallucinated-name→null, valid-name→tool), (c) unit tests for `parseArgs` on each tool (valid, invalid, Arabic-Indic digits), (d) integration test for `route()` with a deterministic fake LLM. |

### MED-4: tool_calls trace table created but never wired into Dart code

| Field | Detail |
|-------|--------|
| **What** | The `tool_calls` Supabase migration exists but **zero lines of Dart code** reference `tool_calls`, `logToolCall`, or `insertToolCall`. The DEC-050 decision log says "tool-call trace (one row per routed message)" is "New infra worth adding" — it was designed but never implemented. |
| **Impact** | The manual verify-by-Supabase-query ritual DEC-050 explicitly says this audit table would eliminate remains the only way to trace routing decisions. Combined with MED-1 (table not even on live), the audit capability is 0%. |
| **Root cause** | The migration was created as Phase 0.5 infrastructure but the wiring (a `logToolCall()` call inside `route()` in `route.dart`) was never added. |
| **Suggested gate** | Gate: `route()` in `route.dart` must call `logToolCall()` before any `return` statement that produces an outcome. OR: add a task for Phase 0.5 finishing that includes wiring the trace table. |

---

## 🔵 LOW findings

### LOW-1: Dead code — unused old gate handlers in chat_screen.dart

`lib/features/chat/chat_screen.dart` — the old regex-gate cascade handlers are still present but never called:
- `_saveAndAnnounceTransaction` (line 470) — unused_element warning
- `_handleSetupIntent` (line 483) — unused_element warning
- `_handleBuyIntent` (line 499) — unused_element warning
- `_showIntegrityScore` (line 1091) — unused_element warning

These are dead code from the pre-DEC-050 era. The new router handles all dispatch.

**Suggested:** Delete these four unused handlers. They're noise in analyze output and confuse future readers about the active code path.

### LOW-2: Unused service fields in tools.dart

Four tool classes carry service references with `// ignore: unused_field`:
- `LogExpenseTool._txService` (line 417) — held for future direct execution
- `LogCompoundExpenseTool._txService` (line 476)
- `AddCommitmentTool._commitmentService` (line 543)
- `AddGoalTool._goalService` (line 606)

These services ARE used by `_handleStagedProposal` in chat_screen.dart, but via `ref.read(transactionServiceProvider)`, not via the tool's own field. The tool fields are dead weight.

**Suggested:** Either wire the tool's own service field through `ToolContext` (cleaner) or remove the fields. The `// ignore: unused_field` comments describe intent but don't make the code correct.

### LOW-3: ToolRegistry linear lookup

`tool_types.dart:239-244` — `operator []` iterates all tools sequentially. For 11 tools this is negligible, but adding `Map<String, RouterTool<Object?>> _byName` in the constructor would be a 2-line fix that makes it O(1) and self-documenting.

---

## 📊 Gate Summary

| Gate | Status |
|------|--------|
| flutter test | ✅ 59/59 pass |
| flutter analyze | ✅ 0 errors, 33 pre-existing info/warning |
| Live Supabase schema verification | ⚠️ `tool_calls` table absent (MED-1) |
| DEC-050 SDK migration status | ⚠️ Still on deprecated `google_generative_ai` 0.4.x (MED-2) |
| Router unit test coverage | ⚠️ 0% — no tests for the new router (MED-3) |
| tool_calls audit wiring | ⚠️ Migration exists but Dart code never writes to it (MED-4) |
| Golden intent matrix (old router) | ✅ 32 rows, all tests pass |
| Mutation check (integrity + purchase DTI) | ✅ GREEN/RED pairs captured |
| Dead code cleanup | ⚠️ 4 unused handlers in chat_screen.dart (LOW-1) |
| DEC-050 discipline rules | ✅ All 5 rules structurally enforced |

---

## 🧬 TEST TAUTOLOGY CHECK

- `test/intent_router_test.dart` — ✓ Real: imports `IntentRouter`, calls `classify()` and individual predicates. Tests the actual class.
- `test/golden_intent_matrix_test.dart` — ✓ Real: loads the JSONL fixture, calls `IntentRouter.classify()` for each row.
- `test/purchase_decision_service_test.dart` — ✓ Real: imports `PurchaseDecisionService`, calls `decideVerdict()`, `calculateDTI()`.
- `test/integrity_score_service_test.dart` — ✓ Real: imports `IntegrityScoreService`, calls `calculate()`, `noDeletionRate()`.
- **No router tests exist** — the new `route()`, `ToolRegistry`, `parseArgs`, and tool `run()` methods have zero coverage (MED-3).

---

## 🎯 Recommended Action Order

1. **Push the tool_calls migration** to live Supabase: `cd supabase && supabase db push` (MED-1)
2. **Wire tool-call tracing** into `route.dart` — add a `logToolCall()` call before each return (MED-4)
3. **Add router unit tests** with a `FakeRouterLlm` — test parseArgs, hallucinated names, cap enforcement (MED-3)
4. **Delete dead code** — the four unused gate handlers in chat_screen.dart (LOW-1)
5. **Complete SDK migration** — swap `google_generative_ai` for `googleai_dart` per DEC-050 (MED-2, Phase 0.5 scope)
