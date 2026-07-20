# DRAFT — Route B `/goal` for Phase 0 QA Closeout (JSONL + delete fake tests + mutation check)

> **Status: about to be delegated.** Authored by Claude Opus 4.8 (Plan
> subagent), grounded in the real `intent_router.dart`, both service test
> files, and `app-spec/23_golden_intent_matrix.md`. Closes the three Phase-4
> deliverables the prior EPIC (commit `a8a44f6`) reported as "QA PASS
> 69/69" but did not actually deliver.
>
> **Independently re-verified by Claude (not just trusted from the
> subagent)** before delegating, per Abdulrahman's explicit instruction to
> do my own QA rather than rely on a subagent's or the swarm's report: I
> cross-checked GM-015/GM-020/GM-032 against the real keyword regexes in
> `intent_router.dart` by hand — all three genuinely fail to match any
> buy/budget keyword substring under `normalizeArabic`. The finding holds.

## Plain-English framing

Test/fixture hygiene only, no production code changes: (1) convert the
32-row golden matrix into a real JSONL fixture + harness that runs every
row through the actual `IntentRouter.classify`; (2) delete the two old
fake re-deriving test groups (confirmed the new real groups already cover
every scenario they touched); (3) add a genuine, repeatable mutation check
per suite, re-introducing the exact DEC-048 bug and proving the surviving
test catches it.

**One real, verified finding surfaced while grounding this:** the matrix is
NOT green as written. Three of 32 rows (GM-015, GM-020, GM-032) claim a gate
the current router doesn't actually produce under regex matching alone —
GM-015 and GM-032 only reach a buy outcome via the downstream digit→safety-net
path the pure `IntentRouter` doesn't model; GM-020 ("باقي من المصروف") is a
genuine current-router miss (near-miss on the budget keyword list — differs
by an inserted "من" and "ال" prefix from any listed phrase). The brief
reconciles all three honestly (`expected_gate: general_chat`, with notes)
rather than quietly editing them to look green.

---

## The `/goal`

```
/goal

# TARGET PROJECT: /Users/abdurrahmanjahfali/Projects/Azdal

## Objective
Close the three Phase-4 deliverables that the previous Phase-0 EPIC (commit a8a44f6) reported
as "QA PASS 69/69" but verifiably did NOT deliver: (1) convert the 32-row golden intent matrix
in app-spec/23_golden_intent_matrix.md into a real, git-tracked JSONL fixture at
test/fixtures/golden_intent_matrix.jsonl, plus a `flutter test` harness that runs every row
through the REAL IntentRouter.classify and asserts the gate decision; (2) DELETE the two old
fake re-deriving test groups still present in test/integrity_score_service_test.dart and
test/purchase_decision_service_test.dart, but ONLY after confirming the new pure-function groups
already cover every scenario they covered; (3) add a genuine, repeatable per-suite MUTATION
check (perturb the real formula, prove the suite goes RED, revert) encoded as a real artifact
with captured evidence. This is test/fixture hygiene only. It EXPLICITLY EXCLUDES all router /
tool-calling / firebase_ai / google_generative_ai work (the separate, un-approved Phase 0.5,
DEC-050) and the commitment-payoff→transaction fix (DEC-039). No production behavior changes; no
new user-facing behavior ships.

## Context
- Project: Azdal — /Users/abdurrahmanjahfali/Projects/Azdal. (NOTE: if swarm.yaml still records
  the repo as /Users/abdurrahmanjahfali/Azdal, that is a dead path — operate on /Projects/Azdal.
  This TARGET PROJECT line is authoritative; block if it cannot be resolved.)
- Spec pack: app-spec/. Source spec for the fixture: app-spec/23_golden_intent_matrix.md (315
  lines, 32 rows GM-001..GM-032, 10-value expected_intent enum, 5-value GateDecision enum).
- The gap this closes is real and verified by direct repo inspection (2026-07-20):
  1. NO JSONL fixture exists anywhere. `test/fixtures/` does not exist; no `.jsonl` file exists
     in the tree. app-spec/23_golden_intent_matrix.md:6 itself says "Phase 4 (QA Tester) will
     convert this to JSONL and run it against the harness" — that never happened.
  2. The old fake re-deriving test groups were NEVER deleted. test/integrity_score_service_test.dart:12
     still opens `group('IntegrityScoreService', ...)` (lines 12-132) which re-derives every
     factor as local constants (e.g. :51 `(loggingConsistency + receiptUploadRate + noDeletionRate)/3`,
     :95 `keptCount/(keptCount+deletedCount)`) and NEVER calls the service.
     test/purchase_decision_service_test.dart:12 still opens `group('PurchaseDecisionService', ...)`
     (lines 12-85) which re-derives DTI/disposable locally (:42 `3400/10000`, :58
     `income - commitments - monthlySpend - goalMonthly - amount`) and NEVER calls the service.
     Both files ALSO already contain the NEW real groups that DO call the service:
     `group('computeScore — pure function (no Supabase)', ...)` (integrity, lines 134-237) and
     `group('decideVerdict — pure function (no Supabase)', ...)` (purchase, lines 87-194).
  3. NO mutation check exists. `grep -ri mutation test/ lib/features/chat/` returns nothing.
- Why fake re-deriving tests are dangerous — DEC-048 (app-spec/12_decision_log.md:292-302): a REAL
  no_deletion_rate bug (integrity score understated 17-18 points on real Supabase accounts; went
  NEGATIVE at -233% when deletions outnumbered survivors) shipped precisely because the integrity
  test "had encoded the buggy formula as its own expectation (re-deriving (totalCount-deletedCount)/
  totalCount locally rather than calling the real service)." The leftover fake groups are the same
  failure mode, still live in the repo.
- The REAL code the harness/tests must target (already extracted in commit a8a44f6, verified faithful):
  - lib/features/chat/routing/intent_router.dart — `class IntentRouter` (static-only). Enum
    `GateDecision { setupCommitment, buyIntent, integrityQuery, budgetQuery, generalChat }`
    (intent_router.dart:24-30). Methods: `normalizeArabic(String)` (:46-49), `looksLikeSetupIntent`
    (:63), `looksLikeBuyIntent` (:80), `looksLikeIntegrityQuery` (:89), `looksLikeBudgetQuery`
    (:101), and the entry point `static GateDecision classify(String text)` (:110-116) which runs
    the cascade setup → buy → integrity → budget → generalChat (setup precedence first). It is
    pure/synchronous, no network — provably assertable today with zero pinned LLM responses.
  - lib/features/chat/services/purchase_decision_service.dart:21-85 —
    `static Map<String,dynamic> decideVerdict({income, totalCommitments, monthlySpend,
    totalGoalMonthly, amount})`: income<=0 → need_info (:28-36); DTI = totalCommitments/income,
    `if (dti > 0.33)` → no (:39-51); disposable = income-commitments-monthlySpend-goalMonthly-amount
    (:54-55); >=0 → yes; else goals>0 → wait; else → no (:57-84).
  - lib/features/chat/services/integrity_score_service.dart:24-66 —
    `static Map<String,dynamic> computeScore({totalCount, deletedCount, uniqueDays, daysSince,
    withReceipt})`: three factors, no_deletion_rate = `totalCount / (totalCount + deletedCount)`
    (:48-49, the DEC-048 fix), equal-weight mean rounded+clamped 0-100 (:53-55), two locked
    factors stay null (:62-64).
- VERIFIED HARNESS RISK — the matrix is NOT green as written against the real IntentRouter.
  Independently re-checked by hand (not just the subagent's claim): the exact normalized
  regexes from intent_router.dart against all 32 rows give 29 green, THREE DO NOT MATCH:
    - GM-015 "وش رايك في سعر البلايستيشن ٥" — matrix claims buy_intent; IntentRouter.classify
      returns generalChat (no "كم سعر"/buy keyword; reaches buy_query only via the downstream
      digit→classifyTransaction 'chat' safety-net, which IntentRouter deliberately does NOT model).
    - GM-020 "باقي من المصروف" — matrix claims budget_query; IntentRouter.classify returns
      generalChat (matches none of budgetQueryKeywords; "باقي من المصروف" ≠ "باقي مصروف" and has no
      digit → in the full flow it falls to the coach). This is a GENUINE current-router miss.
    - GM-032 "جوال بـ ٢٠٠٠ ودراجة بـ ٨٠٠" — matrix claims buy_intent; IntentRouter.classify
      returns generalChat (no buy keyword; reaches buy via the digit safety-net path only).
  These three are consistent with the spec's own GateDecision semantics (23_golden_intent_matrix.md:47
  defines buy_intent as regex match "or safety-net call from the 'chat' fallback"). The regex-gate
  layer that IntentRouter models genuinely returns general_chat for all three. They MUST be
  reconciled honestly before the harness is frozen (see Approach + note).
- Coverage-equivalence for the deletions is ALREADY SATISFIED (verified) — the new real groups cover
  every scenario the fake groups covered, so deletion loses nothing:
    - purchase: fake group's need_info / DTI>33%→no / DTI==33%→allowed / positive-disposable→yes /
      neg-disposable+goals→wait / neg-disposable+no-goals→no / zero-income scenarios are ALL covered
      by decideVerdict tests at lines 88, 101, 115, 128, 142, 156, 183 (which additionally assert the
      disposable-exactly-zero→yes boundary at :170).
    - integrity: fake group's range-clamp / equal-weight / locked-null / new-account→33 /
      no_deletion_rate incl. heavy-deletion regression / receipt-rate / logging-consistency / factor
      clamp scenarios are ALL covered by computeScore tests at lines 135, 149, 163, 181, 193, 206,
      220 (the DEC-048 heavy-deletion regression is now asserted via the SERVICE at :193-204).
  The worker must RE-CONFIRM this mapping before deleting, but it holds today.
- Out of scope for THIS closeout (do not pull in): app-spec/24_test_seed_fixture.md's local-Supabase
  seed + real .evaluate()/.calculate() integration cross-check. The harness here asserts the pure
  regex gate (IntentRouter.classify) and the two pure functions (computeScore/decideVerdict) — none
  touch Supabase. Doc 24's seeded-DB cross-check is a separate, later deliverable; referenced only for
  the DEC-048 hand-computed integrity values (24:307-446) the mutation check re-uses.

## Current Limitations (what makes this a real EPIC, not a one-line delete)
1. The matrix's expected_gate column conflates the regex-gate decision (what IntentRouter.classify
   returns) with the downstream safety-net/LLM path. Three rows (GM-015/020/032) are therefore not
   green as written; a naive verbatim conversion produces a RED harness. The fixture schema needs an
   explicit, honest regex-gate field and the three rows need product reconciliation.
2. Both service test files carry TWO groups each — one fake (re-derives formulas, passes against a
   broken service) and one real. Deleting the fake half safely requires proving no scenario is lost.
3. A mutation check that is a one-time unrecorded claim ("I perturbed it and it went red") is exactly
   the false-confidence pattern DEC-048 warns about. It must be a repeatable artifact with captured
   evidence, not a sentence in a PR description.

## Target Approach (matrix→JSONL + delete fakes + mutation check ONLY)
A) Reconcile + author the fixture (Product Steward owns semantics; QA authors the file):
   - Fixture at test/fixtures/golden_intent_matrix.jsonl — one JSON object per line, git-tracked, 32
     rows. Per-row schema: { id, message, expected_intent (10-value enum), expected_gate (the
     GateDecision IntentRouter.classify actually returns — one of setup_commitment | buy_intent |
     integrity_query | budget_query | general_chat), requires_llm_classify (bool), ground_truth
     (nullable literal per DEC-024, e.g. GM-008 {"item":"جوال","amount":3000}), notes }.
   - Reconcile GM-015, GM-020, GM-032 HONESTLY: set expected_gate to the value IntentRouter.classify
     actually produces (general_chat for all three) and annotate each note with WHY — GM-015/GM-032
     reach buy via the digit→classifyTransaction safety-net path (not the regex gate); GM-020 is a
     documented current-router GAP that Phase 0.5 (DEC-050) is expected to fix. Keep expected_intent
     as the downstream semantic outcome for Phase 0.5's future diff. DO NOT rewrite expected_gate
     silently to make green — the reconciliation must be visible and product-signed.
   - Harness (a normal `flutter test`, e.g. test/golden_intent_matrix_test.dart): read the JSONL from
     the package-relative path, parse every line, and for each row assert
     `IntentRouter.classify(row.message)` maps to row.expected_gate (via an explicit
     string→GateDecision map: setup_commitment→setupCommitment, buy_intent→buyIntent,
     integrity_query→integrityQuery, budget_query→budgetQuery, general_chat→generalChat). Assert all
     32 rows present and all 10 expected_intent values represented (>=2 each per the matrix's own
     coverage rule). This harness is deterministic, network-free, and provably GREEN once the three
     rows are reconciled. It does NOT assert the full expected_intent path — that needs a pinned
     FakeGeminiService + chat_screen wiring and is explicitly deferred to Phase 0.5's consumer.
B) Delete the fake groups (QA), coverage-equivalence-gated:
   - In test/integrity_score_service_test.dart delete the entire `group('IntegrityScoreService', ...)`
     block (lines 12-132), keeping `group('computeScore — pure function (no Supabase)', ...)`.
   - In test/purchase_decision_service_test.dart delete the entire
     `group('PurchaseDecisionService', ...)` block (lines 12-85), keeping
     `group('decideVerdict — pure function (no Supabase)', ...)`.
   - PRE-REQ (must be recorded before deleting): produce the scenario→real-test mapping proving every
     deleted scenario is covered by a surviving computeScore/decideVerdict test (the mapping in
     Context holds today — re-verify and record it). If any scenario is genuinely uncovered, ADD a
     real-service test for it first; do not delete until covered.
C) Mutation check per suite (QA), as a repeatable artifact with captured evidence:
   - Encode a repeatable procedure (recommended: tool/mutation_check.sh, or an equivalent documented
     runbook) that, per suite: applies ONE known one-line perturbation to the REAL service source,
     runs `flutter test <that suite>`, asserts it FAILS, then reverts via `git checkout` and re-runs
     asserting it PASSES. Capture the RED output as evidence (e.g. committed under
     test/fixtures/mutation_evidence/ or a tracked log), never a bare claim.
   - Integrity perturbation must re-introduce the DEC-048 bug specifically: change
     integrity_score_service.dart:48-49 `totalCount / totalEver` back to the buggy
     `totalCount / totalCount` (or `(totalCount - deletedCount)/totalCount`) and prove the
     computeScore heavy-deletion test (:193-204) goes RED — i.e. the real test now catches the exact
     bug the old fake test shipped. Revert.
   - Purchase perturbation: change decideVerdict.dart:40 `if (dti > 0.33)` to `if (dti > 0.99)` and
     prove the 'DTI > 33% → hard no' test (:101) goes RED. Revert.
   - NET-ZERO the production files — no perturbation is committed; the only committed changes under
     lib/ are none.

## Phases & Worker Assignments
- Phase 1: Product Steward — own the fixture as the acceptance spec. Finalize the per-row JSONL
  schema (Approach A). RECONCILE GM-015/GM-020/GM-032 to the honest IntentRouter.classify output and
  write the annotations (safety-net path vs. documented current-router gap). Confirm all 10
  expected_intent values keep >=2 rows after any change. ENFORCE SCOPE: fixture + test hygiene only;
  reject any card that edits IntentRouter regexes, adds firebase_ai, redesigns routing, or touches
  DEC-039. No code.
- Phase 2: QA Tester — do the build. (a) Author test/fixtures/golden_intent_matrix.jsonl (32 rows,
  reconciled) + the harness test asserting IntentRouter.classify == expected_gate for every row and
  freeze it GREEN. (b) Record the scenario→real-test coverage-equivalence mapping, then DELETE the
  two fake groups (integrity :12-132, purchase :12-85). (c) Build the repeatable mutation-check
  artifact (Approach C) and capture the RED evidence for both suites, including the DEC-048
  re-introduction. (d) TRUTH CHECK greps: prove `group('IntegrityScoreService'` and
  `group('PurchaseDecisionService'` no longer exist; prove no local formula re-derivation remains in
  either file; prove both files still import + call computeScore/decideVerdict; prove intent_router.dart
  is byte-unchanged (regexes intact) and no firebase_ai was added.
- Phase 3: Zero-Trust Auditor — focused hostile audit (INCLUDED; this is exactly the fake-test class
  that produced DEC-048). Probe: (1) does every JSONL expected_gate actually equal IntentRouter.classify
  for its message — re-run classify independently and diff, confirming green was NOT achieved by
  tautology or by silently mutating expected values without the documented reconciliation; (2) are the
  fake groups genuinely gone AND is coverage genuinely preserved (spot-check that a broken service
  fails a surviving test); (3) does the mutation check ACTUALLY go red when re-run from scratch, and
  does the integrity perturbation truly re-trigger the DEC-048 case; (4) does any figure-bearing row
  (GM-008..013, GM-014, GM-032) store its number as literal ground_truth data, never LLM-derived
  (DEC-024); (5) scope leak — no firebase_ai/google_generative_ai change, no IntentRouter edit, no
  chat_screen edit, no DEC-039. Scope: no release/APK vectors — nothing ships.
- Phase 4: DevOps Release Engineer — MINIMAL, no release. Confirm the harness reads the JSONL via a
  path that resolves under `flutter test` in CI (package-root-relative file load), and that
  `flutter test` (incl. the new harness + surviving real groups) and `flutter analyze` run clean.
  Confirm test/fixtures/golden_intent_matrix.jsonl and the mutation evidence are git-tracked. Commit +
  push. NO APK build, NO GitHub Release (no user-facing behavior changed).
- Guardian: Curiosity Hunter (SCSI) — continuous truth-check + final gate. Re-verify: matrix honest
  (classify == expected_gate for all 32), fakes gone, coverage preserved, mutation check real and
  repeatable, no scope leak, IntentRouter unchanged. Auto-approve only when all gates pass.
- Documentation Steward (at stage close): flip app-spec/23_golden_intent_matrix.md:6 ("Phase 4 will
  convert this to JSONL") to done and cite test/fixtures/golden_intent_matrix.jsonl; record the
  GM-015/GM-020/GM-032 reconciliation, flagging GM-020 as a documented current-router gap Phase 0.5
  targets; update app-spec/00_active_capabilities.md's test-quality gap to reflect the fakes are now
  deleted and the mutation check exists; add an LL entry ("a golden matrix that asserts aspirational
  gate behavior instead of the router's ACTUAL output is itself a fake test — three rows had to be
  reconciled to real IntentRouter output before the harness could be honestly green"); and record
  (do not re-litigate) that commit a8a44f6's QA phase reported these three deliverables as done when
  they were not.

## Workers to SKIP
- UI/UX Designer — SKIP. No screens, widgets, navigation, UX copy, or design tokens. Every deliverable
  is a JSONL fixture, a test harness, test-file deletions, and a mutation-check artifact.
- State Engineer — SKIP. This closeout changes NO production code. The service/router extractions it
  depends on already landed in commit a8a44f6. The mutation check's perturbations to lib/ are transient
  and reverted by QA's own script (net-zero, never committed) — not a production refactor.
- Backend/DB Architect — SKIP. The harness asserts the pure regex gate and two pure functions; nothing
  touches Supabase, schema, migrations, or seed data. app-spec/24_test_seed_fixture.md's seeded-DB
  cross-check is a separate, later deliverable, explicitly NOT in this closeout.

## Exit Criteria (Machine-Checkable)
- [ ] test/fixtures/golden_intent_matrix.jsonl exists, is git-tracked, has exactly 32 rows (GM-001..032),
      each line is valid JSON, and all 10 expected_intent values are present with >=2 rows each; GM-032
      multi-intent row present with its two-item ground_truth literal.
- [ ] Harness test exists and, for every one of the 32 rows, asserts IntentRouter.classify(message)
      maps to the row's expected_gate; `flutter test` on the harness is GREEN.
- [ ] The three reconciled rows GM-015, GM-020, GM-032 have expected_gate == the value
      IntentRouter.classify actually returns (general_chat for all three) AND each carries a note
      documenting why (safety-net path / current-router gap). An independent re-run of classify over
      all 32 rows matches the fixture exactly (Zero-Trust confirms — no tautology, no silent rewrite).
- [ ] Both fake groups are DELETED: grep finds neither `group('IntegrityScoreService'` nor
      `group('PurchaseDecisionService'`; grep finds no local formula re-derivation in either test file
      (no inline DTI/disposable/no_deletion_rate arithmetic); both files still import and call
      computeScore / decideVerdict.
- [ ] Coverage-equivalence mapping recorded proving every deleted scenario is covered by a surviving
      real-service test; no scenario lost.
- [ ] Repeatable mutation-check artifact exists (e.g. tool/mutation_check.sh) with captured RED
      evidence for BOTH suites; the integrity perturbation re-introduces the DEC-048 no_deletion_rate
      bug and the surviving heavy-deletion test catches it (goes RED), then GREEN after revert. lib/ is
      net-unchanged (no perturbation committed).
- [ ] No scope leak: grep confirms no firebase_ai / firebase_core / google_generative_ai change;
      intent_router.dart byte-unchanged (all five keyword regexes + classify intact); chat_screen.dart
      unchanged; no DEC-039 change.
- [ ] flutter analyze: 0 errors.
- [ ] flutter test: all pass, count strictly > baseline (harness rows + any added coverage tests;
      minus the deleted fake tests is expected and acceptable so long as coverage-equivalence holds).
- [ ] Git committed and pushed to remote.
- [ ] SCSI Guardian: APPROVED.
- [ ] NOTE — APK build and GitHub Release are intentionally NOT exit criteria: no user-facing behavior
      changed (fixture + test hygiene only).

## File Paths
- Spec pack: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/
- Source matrix to convert: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/23_golden_intent_matrix.md
- New fixture: /Users/abdurrahmanjahfali/Projects/Azdal/test/fixtures/golden_intent_matrix.jsonl
- New harness: /Users/abdurrahmanjahfali/Projects/Azdal/test/golden_intent_matrix_test.dart
- Router under test (unchanged): /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/routing/intent_router.dart
- Existing router tests (do not duplicate): /Users/abdurrahmanjahfali/Projects/Azdal/test/intent_router_test.dart
- Fake groups to delete: /Users/abdurrahmanjahfali/Projects/Azdal/test/integrity_score_service_test.dart (lines 12-132)
- Fake groups to delete: /Users/abdurrahmanjahfali/Projects/Azdal/test/purchase_decision_service_test.dart (lines 12-85)
- Services mutated+reverted for the mutation check: /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/services/integrity_score_service.dart (:48-49), /Users/abdurrahmanjahfali/Projects/Azdal/lib/features/chat/services/purchase_decision_service.dart (:40)
- Mutation artifact: /Users/abdurrahmanjahfali/Projects/Azdal/tool/mutation_check.sh (+ captured evidence under test/fixtures/mutation_evidence/)
- Hand-computed integrity ground truth: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/24_test_seed_fixture.md (§4, DEC-048 case)
- Governing spec: /Users/abdurrahmanjahfali/Projects/Azdal/app-spec/21_personal_build_plan.md (Phase 0)
```

---

## Opus's note to Abdulrahman (one real decision)

**The golden matrix is not green as written.** Three of 32 rows claim a gate
the current router does not actually produce:

- GM-015 and GM-032 claim `buy_intent`, but `IntentRouter.classify` returns
  `general_chat` — they only reach a buy outcome via the downstream
  digit→safety-net path, which the pure router doesn't model. Recording
  `general_chat` with a note is just honest bookkeeping, not a judgment call.
- GM-020 ("باقي من المصروف") is the real one — a **genuine current-router
  miss**. No budget keyword matches (differs from the listed phrases by an
  inserted "من" and "ال" prefix), no digit, so today it falls to the coach.

**The decision:** record GM-020 as a truthful "current gap" row (recommended
— the matrix's whole purpose is to encode today's ACTUAL behavior, gaps
included, so Phase 0.5 can later prove it improved), or quietly edit the
message to match a budget keyword so it looks green? Opus recommends the
former and wrote the brief that way — but flagged this as your call to
ratify, since a matrix that edits reality to look green is the same
false-confidence failure as the fake tests this whole effort exists to kill.
