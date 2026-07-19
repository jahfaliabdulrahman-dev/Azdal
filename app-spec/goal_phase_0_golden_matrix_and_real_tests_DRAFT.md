# DRAFT — Route B `/goal` for Phase 0 (Golden Intent Matrix + Real Service Tests)

> **Status: NOT YET DELEGATED.** Authored by Claude Opus 4.8 (via a Plan
> subagent, 2026-07-19), grounded in a real read of the two service files,
> `chat_screen.dart`'s router cascade, the two existing fake test files,
> `21_personal_build_plan.md`, `00_active_capabilities.md`, and DEC-048.
> This closes the two Phase-0 deliverables that were blocking the Phase 0.5
> router brief (`goal_phase_0.5_tool_calling_router_DRAFT.md`) — Abdulrahman
> chose to build these first, per his own "plan, plan, plan, then execute" rule.
> **Do not run `lead_delegate` until the 4 decision points below are resolved.**

## Plain-English framing

Scope: only (1) a golden intent matrix verified GREEN against today's router,
and (2) real service tests that call the actual service classes. Explicitly
excludes all router/`firebase_ai` work (stays in the separate Phase 0.5
brief) and the commitment-payoff→transaction fix (DEC-039) — see decision
point 3 below.

Two real findings from reading the code make this a genuine EPIC, not a
one-file test edit:

1. **Today's router isn't unit-testable in isolation.** The five
   `_looksLike*` predicates and the regexes in `chat_screen.dart` (lines
   47–100) are file-private — a test file can't import them. The actual
   routing decision (precedence, digit-gate, LLM fallback, buy safety-net)
   lives inside the widget-state method `_sendMessage` (301–443), fused with
   `ref.read`, live Gemini calls, and UI side effects. No pure function maps
   a message to "which intent fires" today.
2. **Both services fuse math into Supabase I/O.** `PurchaseDecisionService.evaluate`
   and `IntegrityScoreService.calculate` call `_client.auth.currentUser!.id`
   and `.from(...).select()...` inline, interleaved with the arithmetic —
   there's no pure computation seam to call. That's *why* the existing tests
   re-derive formulas locally: there was nothing else callable. This isn't
   hypothetical — **DEC-048** is a real bug (integrity score understated by
   17–18 points, went negative at -233%) that shipped because
   `integrity_score_service_test.dart` had encoded the buggy formula as its
   own expectation instead of calling `.calculate()`. The DEC-048 fix
   corrected the expected number but never fixed the structural problem —
   today's test *still* never calls the real service.

Both findings point the same way: a small, behavior-preserving testability
refactor must precede the tests — touching `chat_screen.dart`, the single
most bug-prone file in the app (DEC-036/037 found 9 critical bugs there).
That's why it's planned as its own carefully-audited phase, and why decision
point 1 below is worth your explicit sign-off rather than assuming it.

---

## The `/goal` (ready for `lead_delegate` once the 4 decisions below are resolved)

```
/goal

## Objective
Close the two outstanding Phase-0 deliverables that gate the router rewrite: (1) build a
versioned GOLDEN INTENT MATRIX of real Saudi-dialect messages → expected routing outcome,
verified GREEN against the CURRENT (regex) router, structured so Phase 0.5 can later diff a
new router against it; and (2) replace the FAKE service tests (which re-derive financial
formulas as local constants) with REAL tests that import and call PurchaseDecisionService and
IntegrityScoreService and fail if the real service is broken. This is a testability +
regression-baseline EPIC. It EXPLICITLY EXCLUDES any router / tool-calling / firebase_ai /
google_generative_ai work (that is the separate, un-approved Phase 0.5, DEC-050) and the
commitment-payoff→transaction fix (DEC-039). No new user-facing behavior ships.

## Context
- Project: Azdal — /Users/abdurrahmanjahfali/Projects/Azdal  (NOTE: swarm.yaml:7,24 still
  records the repo as /Users/abdurrahmanjahfali/Azdal — a dead path; use /Projects/Azdal.)
- Spec pack: app-spec/
- Authoritative source for these deliverables: 21_personal_build_plan.md:102-108 (Phase 0:
  "real tests for PurchaseDecisionService and IntegrityScoreService against the actual
  classes"; "Build a golden intent matrix (real dialect phrasings → expected behavior)
  against the current router, so it encodes today's behavior before anything changes") and
  the refined restatement at 21_personal_build_plan.md:145-156.
- The gap being closed is documented verbatim at 00_active_capabilities.md:85: the two service
  tests "don't call the real service classes — they re-derive the formulas as local constants.
  '34/34 passing' did not and will not catch bugs in these two services."
- Proof the gap is not theoretical — DEC-048 (12_decision_log.md:292-302): a REAL
  no_deletion_rate bug in IntegrityScoreService (17-18 point understatement on real Supabase
  accounts; went NEGATIVE, -233%, when deletions outnumbered survivors) shipped precisely
  because integrity_score_service_test.dart "had encoded the buggy formula as its own
  expectation (re-deriving (totalCount - deletedCount)/totalCount locally rather than calling
  the real service)." The DEC-048 fix corrected the expected NUMBER but NOT the structural
  problem — the test STILL re-derives, never calls .calculate() (see current test lines
  89-106). This EPIC fixes the structure.
- Verified state of the CURRENT (regex) router — the matrix's baseline target:
  - chat_screen.dart:47-50 `_normalizeArabic`; :53-60 `_commitmentKeywords`/`_goalKeywords`;
    :74-77 `_buyKeywords`; :83-85 `_integrityKeywords`; :94-97 `_budgetQueryKeywords`; the five
    predicates `_looksLikeSetupIntent` (:62), `_looksLikeBuyIntent` (:79),
    `_looksLikeIntegrityQuery` (:87), `_looksLikeBudgetQuery` (:99). ALL are file-private
    top-level functions — a test/ file CANNOT import them (Dart library privacy).
  - The routing DECISION lives inside `_ChatScreenState._sendMessage` (:301-443): digit-gate
    (:317), setup pre-check (:323-330), buy pre-check (:333-340), integrity (:343-346), budget
    (:349-352), then classifyTransaction (:388) with a buy safety-net (:425-432). It is fused
    with ref/Gemini/UI and is NOT reachable as a pure function. => a behavior-preserving
    extraction is required before the matrix can assert against "today's router" in isolation.
  - The regex gates are only PRE-FILTERS: the buy/setup FINAL outcome still depends on an LLM
    classify (classifyBuyIntent/classifySetupIntent returning kind != 'none'); integrity/budget
    are fully deterministic (no LLM). This distinction drives the matrix schema below.
- Verified state of the two services (the real code the tests must call):
  - PurchaseDecisionService (lib/features/chat/services/purchase_decision_service.dart):
    `evaluate(String item, double amount)` (:23-157) and `calculateRemainingBudget()`
    (:166-252). Verdict logic: income<=0 => need_info (:40-48); DTI = totalCommitments/income,
    >0.33 => no (:80-92); disposable = income - totalCommitments - monthlySpend -
    totalGoalMonthly - amount (:126-127); >=0 => yes; else goals>0 => wait; else => no
    (:129-156). totalCommitments = max(itemized, coldStartEstimate) (:74-77).
  - IntegrityScoreService (lib/features/chat/services/integrity_score_service.dart):
    `calculate()` (:23-128). Three factors: logging_consistency (:39-74), receipt_upload_rate
    (:77-90), no_deletion_rate = kept/(kept+deleted) (:93-112, the DEC-048 fix), equal-weight
    mean, round, clamp 0-100 (:115-117); two locked factors stay null (:124-125).
  - BOTH take a SupabaseClient in the constructor and call `_client.auth.currentUser!.id` +
    `.from(table).select()...` inline; the math is interleaved with the query results. There
    is NO pure seam to call today.
- Verified test state (test/): 5 files exist — gemini_service_test.dart, chat_provider_test.dart,
  widget_test.dart, and the two fake ones. purchase_decision_service_test.dart only asserts
  `PurchaseDecisionService is Type` (:16) and re-derives DTI/disposable as local arithmetic
  (:35-84) — it never constructs the service or calls evaluate(). integrity_score_service_test.dart
  re-derives every factor locally (:22-131) — it never calls calculate().
- Verified tooling: pubspec.yaml has supabase_flutter ^2.3.0 (:26) and mocktail ^1.0.0 (:53,
  dev). supabase/config.toml + supabase/migrations/ EXIST and the project is linked
  (supabase/.temp/linked-project.json) — so a local-Supabase integration path is viable, BUT
  only the financial_profile migration is present locally (20260713000000_financial_profile.sql);
  the commitments / transactions / goals tables the services query are NOT in local migrations
  yet (a `supabase db pull` is likely needed to reproduce the full schema locally).
- No golden intent matrix exists anywhere in the repo (glob for matrix/golden/fixture across
  the whole tree returns nothing).

## Current Limitations (what makes this a real EPIC, not a one-file test edit)
1. test/purchase_decision_service_test.dart + integrity_score_service_test.dart re-derive the
   real formulas as local constants (DTI, disposable, no_deletion_rate, etc.) — they pass
   unchanged against a BROKEN service. DEC-048 is the proof this already caused a shipped bug.
2. The two services expose no pure-computation seam: math is fused to Supabase fetches, so
   "call the real formula" is impossible without either a pure-compute extraction, a live/local
   Supabase, or brittle mocktail chain-mocking of the postgrest fluent builder.
3. The current router's cascade is file-private + embedded in widget state (chat_screen.dart
   :47-100, :301-443) — unreachable from tests. The matrix cannot be asserted GREEN against
   "today's router" without extracting the pre-LLM cascade into a public, pure seam.
4. There is no versioned fixture capturing today's routing behavior, so Phase 0.5 currently has
   NO regression baseline to diff a new router against — which is the entire reason it is blocked.

## Target Approach (for the Lead Architect to decompose — matrix + tests ONLY)
A) TWO behavior-preserving testability refactors (production code, State Engineer):
   - Services: extract the pure arithmetic of evaluate() and calculate() into pure, public,
     synchronous functions (e.g. PurchaseDecisionService.decideVerdict({income, commitments,
     monthlySpend, goalMonthly, amount}) -> {verdict, disposable, dti} and
     IntegrityScoreService.computeScore({uniqueDays, daysSince, withReceipt, totalCount,
     deletedCount}) -> {score, factors}). The async methods then FETCH from Supabase and DELEGATE
     to the pure function. Byte-identical outputs to today (verified). This is the seam the real
     tests call.
   - Router: extract the pre-LLM regex cascade + its precedence from chat_screen.dart into a
     public, pure IntentRouter (new file lib/features/chat/routing/intent_router.dart) returning
     a deterministic GateDecision (setup | buy | integrity | budget | needs_llm_classify |
     passthrough). `_sendMessage` calls IntentRouter and behaves identically. The regexes are
     MOVED, NOT DELETED and NOT changed (deletion is Phase 0.5). IntentRouter is an explicitly
     TRANSITIONAL seam: Phase 0.5 will replace it, but it (a) makes today's behavior assertable
     now and (b) hands Phase 0.5 one clean swap point.
B) Golden intent matrix (versioned fixture + harness, QA Tester, spec by Product Steward):
   - Fixture at test/fixtures/golden_intent_matrix.jsonl (one JSON object per line, git-tracked).
     Row schema: { id, message (Arabic dialect), expected_intent (stable enum), expected_gate
     (deterministic regex-gate outcome), requires_llm_classify (bool), ground_truth (nullable —
     for figure-bearing rows, the number stored as DATA per DEC-024, never LLM-derived), notes }.
   - expected_intent enum = today's reachable semantic outcomes, chosen to map 1:1 onto the
     Phase 0.5 tool names so a future router can be diffed directly: setup_commitment,
     setup_goal, evaluate_purchase, buy_query, view_integrity, view_budget, log_expense,
     log_compound_expense, clarify, general_chat.
   - Coverage: representative real dialect phrasings per intent INCLUDING the LL-011 hamza-dropped
     variants (ابي اشتري vs أبي أشتري), the DEC-039a multi-intent message as a documented
     currently-limited row, and near-miss/negative rows. Product Steward owns the row set as the
     acceptance spec (message -> expected_intent).
   - Harness (a normal `flutter test`): for every row, run IntentRouter over the message and
     assert expected_gate — deterministic, no network, provably GREEN today. For
     requires_llm_classify rows, optionally assert the full expected_intent via a FakeGeminiService
     with PINNED classify responses (keeps it deterministic). The harness FREEZES the baseline.
C) Real service tests (QA Tester): rewrite the two test files to import and call the extracted
   pure functions with known inputs -> known verdicts/scores, covering the DEC-026 DTI/verdict
   boundaries and the DEC-048 no_deletion_rate regression case computed BY the service. Add a
   MUTATION check per suite (temporarily perturb the real formula -> the test MUST go red) to
   prove the test actually exercises the service and cannot silently re-derive again. Delete
   every local formula re-derivation.
D) LL-010 cross-check (QA Tester + Backend, if provisioned): instantiate the REAL service against
   a seeded local Supabase (or a mocktail-backed client) and assert .evaluate()/.calculate()
   returns the same verdict/score the pure function predicts — this is the layer that catches
   column drift (the DEC-036 bug-#1 class), which pure-unit tests alone cannot.

## Phases & Worker Assignments
- Phase 1: Product Steward — own the golden intent matrix as the acceptance spec. Define the
  expected_intent enum (exactly the 10 outcomes above, mapped to Phase 0.5 tool names for
  future diffability). Curate the representative Arabic-dialect message set (LL-011 hamza
  variants; DEC-039a multi-intent as a documented-limitation row; negatives/near-misses).
  Write rows as message -> expected_intent (+ expected_gate, requires_llm_classify). ENFORCE
  SCOPE: matrix + tests only; NO router/firebase_ai/google_generative_ai code; NO new intents;
  NO commitment-payoff (DEC-039) work. Reject any card that edits routing behavior.
- Phase 2: Backend & DB Architect — Dependency-Verification gate (LL-037), the load-bearing
  pre-req for the REAL service tests and the LL-010 cross-check. Prove against the LIVE/local
  Supabase that every table+column each service reads exists with the assumed name/type:
  financial_profile(user_id, monthly_income, monthly_commitments_estimate, is_deleted);
  commitments(user_id, monthly_amount, status, is_deleted); transactions(user_id, amount, type,
  is_deleted, created_at, receipt_url); goals(user_id, monthly_contribution, status, is_deleted).
  Confirm whether the local migration set reproduces all four tables (only financial_profile is
  present locally) or a `supabase db pull` is needed; define the deterministic test-seed
  strategy (a fixed fixture user + known rows whose expected verdict/score is hand-computed).
  This is READ/verify + migration/seed design only — no service code.
- Phase 3: State Engineer — implement the two behavior-preserving refactors (Approach A). Pure-
  compute extraction for both services; IntentRouter extraction for the pre-LLM cascade; wire
  `_sendMessage` to IntentRouter with IDENTICAL behavior; regexes moved-not-deleted, unchanged.
  Prove behavior-preserving (same verdicts, same gate decisions) before handing to QA. Touching
  chat_screen.dart demands maximum care (DEC-036/037 history) + a self Truth Check. NO deletion
  of any regex/classifier; NO firebase_ai. Do NOT write the fixture or rewrite the test files —
  that is QA's lane (keeps lib/ vs test/ ownership clean).
- Phase 4: QA Tester — build the coverage. (a) Author test/fixtures/golden_intent_matrix.jsonl
  from Phase 1's spec + the harness test that asserts expected_gate via IntentRouter (+ pinned-
  FakeGeminiService assertion of expected_intent on requires_llm_classify rows); freeze GREEN.
  (b) Rewrite both service tests to import + call the extracted pure functions (known input ->
  known verdict/score), delete every local re-derivation, include the DEC-048 regression case
  and DEC-026 boundaries, and add the per-suite MUTATION check. (c) If Phase 2 provisions it,
  the local-Supabase real-service cross-check (Approach D). (d) TRUTH CHECK: grep proves the
  test files no longer contain local formula re-derivations (no inline `income -`/`(totalCount -
  deletedCount)` etc.) and DO import + construct/call the services; and grep proves the regexes
  still EXIST in the tree (they must NOT be deleted here).
- Phase 5: Zero-Trust Auditor — focused hostile audit (INCLUDED; this EPIC is exactly the class
  of work that produced the fake tests + the DEC-036 regression-from-a-fix). Probe: (1) did the
  two refactors silently change ANY verdict/gate outcome (behavior-drift on the app's most bug-
  prone file)? (2) can the matrix be "made green" tautologically (asserting against itself rather
  than the real IntentRouter)? (3) do the new service tests GENUINELY fail against a broken
  service, or do they re-derive again in a new disguise? (4) does any figure-bearing matrix row
  smuggle an LLM-derived number instead of stored ground_truth (DEC-024)? Scope: no release/APK
  attack vectors — nothing ships.
- Phase 6: DevOps Release Engineer — MINIMAL, no release. Ensure `flutter test` (incl. the new
  matrix harness + real service tests) and `flutter analyze` run clean in CI. If the local-
  Supabase integration tier is adopted, either wire the Supabase CLI (Docker) into CI OR
  designate that tier a local/manual gate (dart run, not CI) per LL-010's "real-DB is a separate
  bar" philosophy — recommend the latter unless CI Docker is already available. Commit + push.
  NO APK build, NO GitHub Release (no shippable behavior changed) — see Exit Criteria note.
- Guardian: SCSI Hunter — continuous scan + final gate. Truth-Check both refactors (behavior
  identical; regexes still present; no firebase_ai introduced) and the tests (no re-derivations;
  mutation check real). Auto-approve only when all gates pass.
- Documentation Steward (at stage close): flip the 00_active_capabilities.md:85 gap to closed and
  cite the two real test files; FIX the path drift at 00_active_capabilities.md:73,77 (services
  are at lib/features/chat/services/, NOT lib/core/services/); record IntentRouter as the
  transitional seam Phase 0.5 will consume; add an LL entry ("a test that re-derives the formula
  it claims to verify manufactures false confidence and is worse than no test — DEC-048 proved
  it shipped a real bug"); flag (do not fix here) the swarm.yaml repo-path drift.

## Workers to SKIP
- UI/UX Designer — SKIP. No screens, no widgets, no navigation, no UX copy, no design tokens.
  Every deliverable is test code, a JSONL fixture, and internal-only refactors with byte-identical
  user-visible behavior. If any refactor is found to change a rendered outcome, that is a defect to
  fix (behavior must be preserved), NOT a design task — do not pull the Designer in.

## Exit Criteria (Machine-Checkable)
- [ ] test/purchase_decision_service_test.dart and integrity_score_service_test.dart IMPORT and
      CALL the real service code (extracted pure functions); grep confirms zero local formula
      re-derivations remain (no inline DTI/disposable/no_deletion_rate arithmetic in test files)
- [ ] Per-suite MUTATION proof: perturbing the real formula turns the suite RED (evidence
      captured) — i.e., the tests fail if the real service is broken
- [ ] DEC-048 regression case (no_deletion_rate with deletions > survivors) is asserted via the
      SERVICE's computed value and stays in [0,100] (never negative)
- [ ] Golden intent matrix present as a versioned fixture: test/fixtures/golden_intent_matrix.jsonl
      (git-tracked), covering all 10 expected_intent outcomes incl. LL-011 hamza variants and the
      DEC-039a multi-intent row
- [ ] Matrix verified GREEN against the CURRENT router: the harness asserts expected_gate via
      IntentRouter for every row and passes; Zero-Trust/Guardian confirm IntentRouter is a
      behavior-identical extraction of chat_screen.dart's cascade (so GREEN-vs-IntentRouter ==
      GREEN-vs-today's-router)
- [ ] Matrix is diff-ready for Phase 0.5: expected_intent enum maps 1:1 to the planned tool names;
      fixture is machine-readable so a future router's chosen-tool output can be diffed row-by-row
- [ ] Behavior-preserving proof for BOTH refactors: services return identical verdict/score maps
      and IntentRouter returns the identical gate decision for a representative input set vs.
      pre-refactor (evidence captured); no regex/classifier deleted; grep of lib/ shows the five
      keyword regexes and `_looksLike*` logic still present
- [ ] No scope leak: grep confirms NO firebase_ai / firebase_core added and google_generative_ai
      untouched; no tool_calls table; no commitment-payoff (DEC-039) change
- [ ] LL-010 verification: the real service math is confirmed against real data — either the
      local-Supabase seeded cross-check asserting .evaluate()/.calculate() matches the hand-
      computed expected values, or (documented) a real-Supabase test-account check in the spirit
      of DEC-048's account-level verification. "flutter test passes" alone is NOT sufficient.
- [ ] Figure-bearing matrix rows store the number as ground_truth DATA, never LLM-derived (DEC-024)
- [ ] flutter analyze: 0 errors
- [ ] flutter test: all pass, count strictly > baseline (real service tests + matrix harness added)
- [ ] Git committed and pushed to remote
- [ ] SCSI Guardian: APPROVED
- [ ] NOTE — APK build and GitHub Release are intentionally NOT exit criteria for this EPIC: no
      user-facing behavior changes (test + internal-refactor only). If the Lead Architect judges a
      release warranted, it is additive, not a gate.

## File Paths
- Spec pack: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/
- Services under test: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/services/purchase_decision_service.dart
- Services under test: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/services/integrity_score_service.dart
- Current router to extract from: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/chat_screen.dart
- New transitional seam: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/routing/intent_router.dart
- Tests to rewrite: /Users/abdurrahmanjahfali/Projects/Azdal/test/purchase_decision_service_test.dart
- Tests to rewrite: /Users/abdurrahmanjahfali/Projects/Azdal/test/integrity_score_service_test.dart
- New fixture: /Users/abdurrahmanjahfali/Projects/Azdal/test/fixtures/golden_intent_matrix.jsonl
- Local Supabase: /Users/abdurrahmanjahfali/Projects/Azdal/supabase/ (config.toml, migrations/)
- Governing spec: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/21_personal_build_plan.md (Phase 0)
- Gap being closed: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/00_active_capabilities.md:85
```

---

## Opus's own note to Abdulrahman (decide before delegating)

1. **This brief unavoidably touches production code, including `chat_screen.dart`.**
   The matrix can't be verified "GREEN against the current router" in a real
   unit test without extracting the pre-LLM cascade into a public seam —
   today those functions are file-private and the decision logic is buried
   inside the `_sendMessage` widget method. Same for the services — math is
   fused to Supabase I/O with no callable seam. Recommended: the two
   behavior-preserving extractions (pure-compute for the services,
   `IntentRouter` for the cascade — deliberately transitional, Phase 0.5
   replaces it and inherits a clean swap point + frozen baseline). Since
   `chat_screen.dart` is the most bug-prone file in the app, this needs your
   explicit sign-off rather than an assumption.
2. **Supabase cross-check: CI or manual/local gate?** `supabase/config.toml`
   exists and the project is linked, so a local-Supabase seeded cross-check
   is viable — but only `financial_profile` is migrated locally, so a
   `supabase db pull` is likely needed first. Recommended: manual/local gate
   (`dart run`, not CI), matching how device/real-DB verification is already
   treated as a separate bar from CI.
3. **Scope confirmation.** `21_personal_build_plan.md` bundles a third
   Phase-0 item in with the matrix + tests: fixing the commitment-payoff-
   creates-no-transaction gap (DEC-039). Excluded here since you named only
   matrix + tests. Confirm that's right.
4. **Matrix baseline semantics.** Two-layer fixture — a stable `expected_intent`
   (what Phase 0.5 diffs against) plus a deterministic `expected_gate` (what
   today's regex router provably produces), with LLM-dependent rows asserted
   via a pinned `FakeGeminiService` — recommended over a full end-to-end
   capture that would require pinning every LLM response for every row.

Minor, not blocking: `00_active_capabilities.md:73,77` cite the services at
`lib/core/services/`, but they actually live at `lib/features/chat/services/`
— folded into the Documentation Steward's cleanup pass above.
