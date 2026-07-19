# DRAFT — Route B `/goal` for Phase 0.5 (Tool-Calling Router)

> **Status: NOT YET DELEGATED.** Authored by Claude Opus 4.8 (via a Plan
> subagent, 2026-07-19), grounded in a real read of DEC-050, doc 23, and the
> current routing code — not a restatement of the decision log summary.
> **Do not run `lead_delegate` with this until the two Phase-0 gaps below are
> resolved or explicitly accepted as risk** — the brief itself says so.

## ⚠️ Blockers found while drafting this (read first)

1. **App Check × sideloaded APK** — must be live-checked in the Firebase
   console. The result decides `firebase_ai` vs. the `googleai_dart` fallback.
   Nothing in Phase 0.5 should start before this is checked.
2. **Golden intent matrix does not exist in the repo.** No matrix file, no
   `.jsonl`, no `lib/features/router/`. `lib/main_personal.dart` is also
   absent, and the two service tests
   (`purchase_decision_service_test.dart`/`integrity_score_service_test.dart`)
   are still the "fake" ones that re-derive formulas locally instead of
   calling the real classes. This matrix is Phase 0.5's *only* safety net for
   proving the new router preserves current behavior — per the plan, "no
   router code starts until both clear."

**In short: Phase 0 *durability* (backups, DEC-051 prep) is done — that was
verified and closed out today. Phase 0's *other* deliverables (golden intent
matrix, real service tests) are separate and still outstanding.** Decide
whether to close those first, or accept the gap and proceed.

---

## The `/goal` (ready for `lead_delegate` once the above is resolved)

```
/goal

## Objective
Replace Azdal's hand-maintained cascade of Arabic regex intent-gates with Gemini
native function-calling used as a single-hop tool dispatcher (DEC-050, personal-build
Phase 0.5) — migrating once to firebase_ai behind a RouterLlm interface, with the
existing pure-Dart services wrapped as coarse, verdict-shaped tools. Behavior-preserving
re-architecture, not a new capability.

## Context
- Project: Azdal — /Users/abdurrahmanjahfali/Projects/Azdal
- Spec pack: app-spec/
- Authoritative decision: DEC-050 (12_decision_log.md:31-47). Verified research:
  23_research_tool_calling_router.md. Constraints that must never break: DEC-024
  (LLM never computes), DEC-022/029 (Bounded Reply Pattern), DEC-020/021 (tiered
  approvals), no-hard-delete.
- What exists:
  - Routing today is a sequential regex cascade in lib/features/chat/chat_screen.dart:
    `_normalizeArabic` (47) feeds five keyword regexes — `_commitmentKeywords`/
    `_goalKeywords` (53-60), `_buyKeywords` (74), `_integrityKeywords` (83),
    `_budgetQueryKeywords` (94) — read by `_looksLikeSetupIntent` (62),
    `_looksLikeBuyIntent` (79), `_looksLikeIntegrityQuery` (87), `_looksLikeBudgetQuery`
    (99). `_sendMessage` (301-443) runs them in order, then a digit-gate, then
    `classifyTransaction`, then a `classifyBuyIntent` safety-net (426) — up to 4
    sequential LLM classify round-trips.
  - Three hand-tuned classifier prompts in lib/core/services/gemini_service.dart:
    `_classifySystemPrompt` (63-93), `_setupIntentSystemPrompt` (379-423),
    `_buyIntentSystemPrompt` (433-460); methods `classifyTransaction` (293),
    `classifyBuyIntent` (470), `classifySetupIntent` (501). Coach `sendMessage`,
    `reactToColdStart`, and `ocrReceipt` also live here and must survive the migration.
  - Six pure-Dart services already tool-shaped (all under lib/features/chat/services/):
    PurchaseDecisionService.evaluate(item, amount) + .calculateRemainingBudget();
    IntegrityScoreService.calculate(); CommitmentService.addCommitment/listActive/
    markCompleted/updateRemaining; GoalService.addGoal/listActive/markAchieved/
    updateCurrentAmount; TransactionService.saveTransaction/saveCompoundSplits +
    soft-delete; FinancialProfileService. Widget catalog, tiered approve/undo, voice,
    OCR, BRP coach prompt all carry over unchanged.
  - Deprecated SDK: pubspec.yaml:23 `google_generative_ai: ^0.4.0`; Gemini API key
    compiled into the APK (gemini_service.dart:6-19).
- What doesn't work (current limitations, not bugs — see below):
  - The regex gates are the project's single most documented pain source (the buy-intent
    hamza/dialect saga, DEC-037/-B). Failures were never Gemini misunderstanding dialect;
    the regex prevented Gemini from being asked.
  - N-intents = N-gates scaling wall — decisive against building Phase-1 capabilities on
    gates already slated for deletion.
  - Multi-intent single messages ("جوال بـ2000 ودراجة بـ800") unsupported (DEC-039a).

## Current Limitations (this is architecture, not a bugfix)
1. chat_screen.dart:47-100 — five hand-maintained Arabic keyword regexes; exact-spelling
   misses reach production (DEC-037/-B); each new intent needs another gate.
2. chat_screen.dart:301-443 — `_sendMessage`, "the single most bug-prone function in the
   app" (DEC-036/037 found 9 critical bugs in this flow). A 4-gate + digit-gate +
   safety-net cascade with up to 4 sequential classify calls.
3. gemini_service.dart:63-460 — three parallel hand-tuned JSON classifier contracts that
   drift independently; built on a deprecated SDK (frozen 15 months, format-rot documented,
   doc 23 §1) with the API key exposed in the sideloaded APK.
4. lib/features/chat/services/ — services are already coarse and verdict-shaped, but the
   MODEL never gets to choose among them; intent selection is regex, not model-driven.
5. test/purchase_decision_service_test.dart + integrity_score_service_test.dart re-derive
   formulas as local constants instead of calling the real classes (active_capabilities:85)
   — a Phase-0 deliverable to close before trusting the matrix.

## Target Architecture (grounded — for the Lead Architect to decompose, per DEC-050 + doc 23)
Open/closed tool registry (new package lib/features/router/ — does not exist yet):
`RouterTool<A>` { name; FunctionDeclaration declaration; WriteTier tier; parseArgs
(validate + Arabic-Indic digit normalize, throws ToolArgsError); run(args, ctx) ->
ToolOutcome }. Sealed `ToolOutcome` = RenderOutcome | StagedProposal | ClarifyOutcome.
`ToolRegistry.declarations` -> forced FunctionCallingConfig.any(names). One `route
(userText, RouterState)` entry point; RouterState is a compact Dart-authored block (no
transcript, NO financial magnitudes). One generateContent call; no FunctionResponse is
ever sent back on number-bearing paths (structurally kills DEC-024 leakage); cap ≤2 then
deterministic bail-to-clarify. Concrete tool map (each wraps an EXISTING service method):
- READ (tier none -> RenderOutcome -> existing widget):
  evaluate_purchase(item, amount) -> PurchaseDecisionService.evaluate; get_remaining_budget()
  -> .calculateRemainingBudget; get_integrity_score() -> IntegrityScoreService.calculate;
  view_commitments(name_hint?) -> CommitmentService.listActive; view_goals(name_hint?) ->
  GoalService.listActive.
- WRITE (StagedProposal — run() writes NOTHING; existing DEC-020/021 confirm/undo commits):
  log_expense(amount, category, tone?) [autoSaveWithUndo]; log_compound_expense(splits[])
  [confirmCard]; add_commitment(name?, provider?, amount_monthly?, amount_total?);
  add_goal(name?, amount_monthly?, amount_total?); edit_commitment(name_hint?);
  edit_goal(name_hint?).
- STRUCTURAL (load-bearing under forced ANY): general_chat() -> existing
  GeminiService.sendMessage coach call (the ONLY path that still passes filtered history,
  unchanged BRP); ask_clarification(missing[]) -> hardcoded Dart question (BRP-exempt).
- Preserve-behavior note: today's `buy_query` "price — coming soon" reply maps to
  general_chat or a thin stub; real price lookup is DEC-054, NOT this phase.
Migration order (single EPIC, "migrate once"): (0) App Check gate + matrix precondition ->
(1) RouterLlm interface + port ALL 6 gemini_service call sites to firebase_ai, remove
google_generative_ai + compile-time key, matrix still green on unchanged coach/OCR/cold-start
-> (2) tool_calls trace table + dependency-verify every service method/column the tools touch
-> (3) build registry + tools -> (4) swap _sendMessage to route(), DELETE the five regexes,
classifyBuyIntent, classifySetupIntent, and classifyTransaction's routing role + its 3 prompts
-> (5) QA offline+live+device -> (6) audit -> (7) release.

## Phases & Worker Assignments
- Phase 0 (PRE-FLIGHT, blocks the whole EPIC): DevOps Engineer — live-check Firebase App
  Check in the console against a sideloaded CI APK (doc 23 pitfall 1 / Q1). Outcome decides
  SDK: firebase_ai if enforcement can be relaxed/debug-provider works, else fallback
  googleai_dart. Also confirm the Phase-0 golden intent matrix exists and is GREEN against
  the current regex router; if absent, it must be built first — it is the only safety net
  proving the new router preserves behavior. No router code starts until both clear.
- Phase 1: Product Steward — verify scope against PRD + DEC-050. Enforce that this is
  behavior-preserving: own the golden intent matrix as the acceptance spec (Gherkin:
  message -> expected_tool -> expected_outcome). Guard the scope boundary — multi-intent
  (DEC-039a) may pass for free and should be added as newly-passing rows, but NO Phase-1
  capabilities (DTI-ratio query DEC-039b, forecast_month, taxonomy) are in scope.
- Phase 2: Backend DB Architect (parallel with — but Designer is SKIPPED, see below) —
  design + migrate the `tool_calls` trace table (id, user_id, message_text, ts, model,
  latency_ms, tool_name, args jsonb, outcome_kind, result_summary jsonb, write_ids uuid[],
  error, is_deleted/deleted_at soft-delete; RLS own-rows-only). Run the LL-037
  dependency-verification gate: prove every service method AND live Supabase column each
  tool touches actually exists with the assumed signature (this is the exact DEC-036 bug-#1
  class — code that assumed non-existent columns). Confirm firebase_app_check/firebase_auth
  coexist with Supabase auth without conflict (doc 23 Q2).
- Phase 3: State Engineer — implement (after Phase 2). RouterLlm interface; firebase_ai
  port of all 6 gemini_service call sites; remove google_generative_ai + the compile-time
  key; build lib/features/router/ registry + one RouterTool per intent wrapping the existing
  services; ToolOutcome types; replace the _sendMessage cascade with route(); wire outcomes
  to the existing widget catalog + tiered approval/undo; write tool_calls trace rows; DELETE
  the five regexes, classifyBuyIntent, classifySetupIntent, and classifyTransaction's routing
  role + its three classifier prompts. Cover the NEW outcome states (clarify, invalid_args,
  unknown_tool, error) with existing message/snackbar rendering.
- Phase 4: QA Tester — validate (after Phase 3). Build FakeRouterLlm (interface impl) +
  the offline matrix tier in CI: assert unknown-name->clarify, bad-args->clarify,
  staged-proposal-never-writes (mock Supabase -> zero inserts before confirm), cap
  enforcement, and that RouterState carries no financial magnitudes. Build the live eval
  script (dart run, NOT CI) and diff chosen-tool/args accuracy against the frozen regex-router
  baseline. Truth Check: grep proves the old patterns are gone. Then LL-010 device discipline:
  re-run the full matrix on the real Android device, cross-checking every write in Supabase.
- Phase 5: Zero-Trust Auditor — hostile audit (INCLUDED, not optional; this touches DEC-024
  and the app's most bug-prone function). Probe the three doc-23 arithmetic-leak vectors
  (FunctionResponse sent back "for a nicer sentence"; financial figures in the state block;
  any decomposed component-returning tool); unintended writes (a tool calling service.insert
  inside run() instead of returning StagedProposal); hallucinated tool name/args; prompt
  injection via user text into the routing prompt; ChatSession/history leakage (rule 5);
  forced-ANY greeting shoehorning without general_chat.
- Phase 6: DevOps Engineer — build + release (after QA PASS). firebase_options.dart via
  flutterfire configure; add firebase_core/firebase_ai/firebase_app_check; confirm the model
  alias (gemini-flash-latest) resolves under AI Logic or pin an explicit model (doc 23
  pitfall 8); build APK; smoke-test on real Android device; publish GitHub Release with the
  rolling 'latest' tag.
- Guardian: SCSI Hunter — continuous scan throughout; final gate before DONE.
- Documentation Steward (at stage close): flip DEC-050 status; update 00_active_capabilities.md;
  record the SDK migration + new LL entries; FIX the doc path drift (services are under
  lib/features/chat/services/, not lib/core/services/ as several entries claim; and
  .hermes/swarm.yaml records the repo as /Users/abdurrahmanjahfali/Azdal while it actually
  lives at /Users/abdurrahmanjahfali/Projects/Azdal).

## Workers to SKIP
- UI/UX Designer — no new screens. Every outcome renders through the EXISTING widget catalog
  (verdict card, compound_split_card, forms, lists, summary_card); the new typed outcomes
  (clarify / invalid_args / unknown_tool / error) map to existing message/snackbar patterns
  and are folded into the State Engineer's state-coverage. If any new outcome needs a novel
  visual treatment, escalate back — otherwise Designer is not on the critical path.

## Exit Criteria (Machine-Checkable)
- [ ] App Check pre-flight gate resolved in the Firebase console BEFORE any router code; SDK
      decision recorded (firebase_ai OR googleai_dart fallback)
- [ ] Phase-0 golden intent matrix present in-repo and GREEN against the current regex router
      (baseline frozen) before the dispatch swap
- [ ] flutter analyze: 0 errors
- [ ] flutter test: all pass, count ≥ baseline (real service tests + offline matrix tier added)
- [ ] Truth Check: grep of lib/ returns 0 for `_looksLike`, `_buyKeywords`, `classifyBuyIntent`,
      `classifySetupIntent`, and the classifyTransaction routing role
- [ ] `google_generative_ai` fully removed from pubspec.yaml (no dual-SDK); no compile-time
      Gemini key path remains
- [ ] Registry validated: every RouterTool has a FunctionDeclaration; general_chat +
      ask_clarification registered; forced FunctionCallingConfig.any asserted; declarations
      flat (doc 23 pitfall 4)
- [ ] Structural DEC-024 assertion: automated proof that no FunctionResponse is sent back on
      number-bearing paths and RouterState contains no financial magnitudes
- [ ] Structural DEC-020/021 assertion: write-tools return StagedProposal with zero Supabase
      writes before confirm (mocked)
- [ ] One-round cap proven: ≤2 calls then deterministic bail-to-clarify
- [ ] Live eval: chosen-tool/args accuracy ≥ frozen regex-router baseline; multi-intent
      (DEC-039a) added and passing
- [ ] tool_calls trace table deployed (soft-delete), one row per routed message, verified via
      direct Supabase query on-device
- [ ] Device + Supabase verification (LL-010): full matrix re-run on real Android device, every
      write cross-checked in Supabase — "tests pass" is NOT sufficient
- [ ] Git pushed to remote
- [ ] APK built and smoke-tested on real Android device
- [ ] GitHub Release published with 'latest' tag
- [ ] SCSI Guardian: APPROVED

## File Paths
- Spec pack: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/
- Source: /Users/abdurrahmanjahfali/Projects/Azdal/lib/
- Router (new): /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/router/
- Services wrapped as tools: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/services/
- Routing to replace: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/chat_screen.dart
- Gemini integration to port: /Users/abdurrahmanjahfali/Projects/Azdal/lib/core/services/gemini_service.dart
- Tests: /Users/abdurrahmanjahfali/Projects/Azdal/test/
```

---

## Opus's own note to Abdulrahman (decide before delegating)

1. **App Check × sideloaded APK (pre-flight):** live-check the Firebase console; the
   result alone decides `firebase_ai` vs the `googleai_dart` fallback. Nothing should
   start until you confirm this.
2. **Golden intent matrix — not found in the repo** (no matrix/`.jsonl`, and
   `main_personal.dart` + real service tests are also still absent). Git shows Phase 0's
   *backups/planning* landed, but its matrix + real-tests deliverables look outstanding.
   That matrix is the migration's only safety net — confirm or build it first.
3. **SDK migration scope:** recommend *same EPIC, sequenced first* (port all 6 Gemini
   call sites once), not a separate step.
4. **Accept Firebase in the stack** (core/auth/app_check alongside Supabase)? Doc 23 Q2.
5. **Per-transaction warm reply:** keep model-authored BRP `reply` on `log_expense`, or
   Dart-render it (rule 3)? Minor but real.
6. **Fix `swarm.yaml` repo path** (`/Users/abdurrahmanjahfali/Azdal` → `/Projects/Azdal`)
   so the swarm doesn't target a dead path.
