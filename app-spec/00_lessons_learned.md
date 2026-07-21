# Azdal — Lessons Learned

> **Purpose:** Capture ALL lessons, decisions, rejected approaches, and critical insights during the project lifecycle.  
> **Rule:** Route lessons here IMMEDIATELY when discovered — not later.  
> **Status:** Populated from historical brainstorming sessions.

---

## LL-001: Tracking Without Solution = Failure

- **Discovered:** 2026-05-21 — Team brainstorming with Saja
- **Lesson:** Finance tracking apps fail because they only track — they don't solve. Previous hackathon teams were rejected specifically because they had "متابعة فقط بدون حلول".
- **Impact:** Pivoted from "expense tracker" to "3-tier financial rehabilitation program."
- **Rule:** Every feature must have a behavioral intervention, not just observation.
- **Source:** `docs/archive/raw-ideas-brainstorming.md`

---

## LL-002: BNPL Is the Real Pain Point

- **Discovered:** 2026-05-21 — Saja's insight
- **Lesson:** Saudi users' biggest financial pain is unconscious BNPL debt accumulation across Tabby, Tamara, and other providers. They don't know their total commitments.
- **Impact:** Shifted B2B focus from "retail data analytics" to "behavioral credit scoring for BNPL companies."
- **Rule:** Solves a problem lenders have (high defaults) AND a problem consumers have (debt spiral).
- **Source:** `docs/business/business-model-canvas.md`

---

## LL-003: 3-in-1 Solves the Sustainability Problem

- **Discovered:** 2026-05-21 — Saja's vision
- **Lesson:** A standalone coach has no revenue path. A standalone lender needs a license. A standalone investment app has no users. Combined: Coach builds users → data proves creditworthiness → lending generates revenue → investment generates more revenue. Each tier feeds the next.
- **Impact:** Designed the 3-tier system (Coach → Smart Lender → Wealth Builder).
- **Source:** `docs/archive/raw-ideas-brainstorming.md`

---

## LL-004: Financial Education Track Is the Best Fit

- **Discovered:** 2026-05-21 — Saja pushed, Abdulrahman agreed
- **Lesson:** Our entire feature set is educational at its core — "Can I buy?" is a teaching moment, the 5-phase journey is a curriculum, and tiers reward learning.
- **Impact:** Changed track from "Generative AI for FinTech" to "Financial Education."
- **Rule:** Judges in education track value behavioral science, user transformation, measurable outcomes.
- **Source:** `docs/business/hackathon-strategy.md`

---

## LL-005: Goodhart's Law Threatens Behavioral Scoring

- **Discovered:** 2026-05-21 — Gemini paranoid architect critique
- **Lesson:** "When a measure becomes a target, it ceases to be a good measure." If users know data entry = credit access, they'll game the system.
- **Impact:** Designed hybrid verification architecture: Open Banking ground truth + AI enrichment + Integrity Score cross-validation. The Integrity Score is NEVER the only factor.
- **Rule:** Every behavioral metric needs an independent ground truth anchor.
- **Source:** `docs/archive/gemini-critique.md`

---

## LL-006: LLMs Must Never Calculate Financially

- **Discovered:** 2026-05-16 — Triple-agent validation
- **Lesson:** LLMs hallucinate math. Financial calculations must be deterministic.
- **Impact:** Architecture rule: "LLM understands and routes — SQL/Python calculates."
- **Rule:** NEVER route financial math through an LLM. SQL for queries, Python for complex calculations, LLM for understanding and summarization only.
- **Source:** `07_flutter_architecture.md`

---

## LL-007: Framing Beats Restrictions

- **Discovered:** 2026-05-14 — Abdulrahman original insight
- **Lesson:** "لما تقول اشتري بوعي انت تقتل المتعة" — telling users to "buy consciously" kills the joy. Position as empowerment, not restriction.
- **Impact:** Designed behavioral UX: Silent Triage (only intervene on red/gray), Framing Effect (focus on future gains, not current losses), evening check-in (not real-time nagging).
- **Rule:** Every intervention must be framed as "you chose better" not "we stopped you."
- **Source:** `00_product_discovery.md`

---

## LL-008: Zero-Friction Is Non-Negotiable

- **Discovered:** 2026-05-14 — Abdulrahman
- **Lesson:** Opening an app + typing price + photographing product = too much work. 77% of finance app users quit in 3 days due to manual entry.
- **Impact:** Input methods locked: Voice (3 seconds) + OCR (1 photo) + Chat (natural). Zero manual data entry forms.
- **Rule:** Every additional tap between user and expense logging reduces retention. Kill all friction.
- **Source:** `00_product_discovery.md`

---

## LL-009: Never Say "No Data"

- **Discovered:** 2026-05-16 — Triple-agent brainstorming
- **Lesson:** Apps that say "add more transactions to see insights" lose users. The first experience must deliver value.
- **Impact:** Designed Cold Start Intelligence: use income brackets, general estimates, confidence levels. Give value first, then ask minimal questions (3 max).
- **Rule:** Onboarding delivers insight before asking for input.
- **Source:** `01_prd.md`

---

## LL-010: Passing Tests and Agent Self-Approval Are Not Verification

- **Discovered:** 2026-07-14 — Abdulrahman, during Stage 4 (BUY+INTG) live device testing
- **Lesson:** Stage 4 was logged DONE (DEC-035) on the strength of `flutter analyze` clean, `flutter test` 34/34 passing, and the swarm's own Zero-Trust Auditor + SCSI Guardian both signing off APPROVE with 0 CRITICAL findings. Live device testing plus direct Supabase queries then found 5 critical bugs none of those gates caught: a purchase-confirmation insert against columns that don't exist on the live table (100% failure rate), a submit button that never disabled (unlimited duplicate writes), success messages showing the same sentence twice, Arabic-Indic numerals silently failing every form-field parse, and — most instructively — a regression introduced *by* the fix for the disable-button bug, where a key rename (`_form_kind` → `form_kind`) got silently dropped, breaking every commitment/goal/income save for hours with zero errors shown anywhere.
- **Impact:** None of the 5 bugs were reachable by static analysis or by tests that never call the real class under test (a related, separate finding: the Stage-4 unit tests re-derive their target formulas as local constants instead of instantiating the actual service — they would pass unchanged even against a broken implementation). Every one was found by: reproducing the exact user flow live on a real device, then independently querying the live database directly (not trusting the app's own "success" message) to confirm a matching row actually exists with the right values and the right timestamp.
- **Rule:** For this project, "tests pass" and "an agent/auditor approved it" are necessary but never sufficient. Before accepting any "done" report — especially one involving a database write, a widget-to-handler payload, or a fix for a previous bug (fixes are exactly where regressions hide) — reproduce the flow live and check the live data source directly. Route B's own audit/guardian layer is not a substitute for this; it missed all 5 bugs above despite explicitly claiming to check for exactly this class of issue.
- **Source:** `12_decision_log.md` DEC-036, this session's Stage 4 verification transcript

---

## LL-011: A Local Regex Gate May Decide Cost, Never Correctness — And a "Disabled" Style Isn't Automatically Your Style

- **Discovered:** 2026-07-15 — Abdulrahman, second live-device retest of Stage 4, escalated to an Opus 4.8 consultation
- **Lesson:** Two distinct traps found in the same retest. (1) `_looksLikeBuyIntent`/`_looksLikeSetupIntent`/`_looksLikeIntegrityQuery` are cheap local `RegExp` pre-filters that gate whether the real LLM classifier ever gets called. They required exact hamza spelling (`أبي أشتري`), so common dialectal typing that drops it (`ابي اشتري`) silently missed the gate entirely — the message fell through to a generic, fluent-sounding coach reply that could pass for a real answer without ever running `PurchaseDecisionService`. A regex pre-filter is a fine *cost* optimization; it must never be the *only* path to a correctness-critical feature, because a miss degrades to confidently-wrong-and-silent, not "slower but correct." (2) Separately, `ElevatedButton.styleFrom(backgroundColor:, foregroundColor:)` only styles the *enabled* state — once `onPressed: null` (every "answered" widget in this app relies on this to prevent re-submission), Flutter silently substitutes its own default disabled palette, discarding the custom colors entirely. An opacity-value fix applied first (0.55→0.85) looked plausible but was treating the wrong layer; only direct pixel-sampling of a live screenshot (measuring actual RGB at text-stroke locations) revealed the real mechanism.
- **Impact:** Both bugs were invisible to `flutter analyze`/`flutter test` and to a first plausible-looking fix attempt (the opacity bump). Both needed a live device + a technique one level more rigorous than "look at the screenshot" — reading actual pixel values for the color bug, and reproducing the exact reported phrase for the regex bug — before the real mechanism became clear.
- **Rule:** (1) Any local keyword/regex gate standing in front of an LLM classifier for a correctness-critical feature must have a fallback path for a miss — never let it be the sole gate to the feature firing at all; when in doubt, add a cheap safety-net classifier call at the point where the message would otherwise silently fall through to generic chat. (2) Any `ElevatedButton`/`OutlinedButton` style block that sets custom `backgroundColor`/`foregroundColor` must also set the `disabled*` variants explicitly if the button will ever be disabled — otherwise Material's defaults silently apply once `onPressed` becomes null, regardless of any `Opacity` wrapper around it.
- **Source:** DEC-037, DEC-037-B, this session's Opus 4.8 consultation transcript

---

## LL-012: Behavior-Preserving Refactor — Move, Don't Delete

- **Discovered:** 2026-07-20 — Phase 0 Foundation, IntentRouter extraction
- **Lesson:** When extracting logic from a monolithic widget into a dedicated service class, move code verbatim — don't rewrite. The IntentRouter extraction from `chat_screen.dart` moved all 6 regexes character-for-character, and the behavior-preservation was independently verified by both QA Tester (t_d6f9fcf5) and SCSI Guardian (t_9ff4830f): 0 CRITICAL, 0 MEDIUM findings, and each regex confirmed present and unchanged.
- **Impact:** DEC-036 bug #5 showed exactly what happens when a fix silently drops a key rename (`_form_kind` → `form_kind`) — every commitment/goal/income save broke for hours with zero errors. Behavior-preserving extraction — move, don't rewrite — prevents this entire class of regression. A refactor that passes `git diff --word-diff` with zero logic changes is the target; the only diff should be imports and class wrappers.
- **Rule:** Any extraction or refactor of existing working logic must move, not rewrite. The diff must show only imports and class wrappers — no character changes to the logic itself. Verify by independent audit (SCSI Guardian + QA Tester), not self-review.
- **Source:** Phase 0 IntentRouter extraction, SCSI Guardian audit report (t_9ff4830f), QA validation report (t_d6f9fcf5)
- **Linked Decision ID:** DEC-048

---

## LL-013: Golden Intent Matrix as Router Migration Safety Net

- **Discovered:** 2026-07-20 — Phase 0 Foundation
- **Lesson:** Before replacing a routing system (regex gates → Gemini function-calling per DEC-050), encode the current router's behavior as an exhaustive ground-truth matrix. The 32 Saudi-dialect rows with 10 `expected_intent` values and 5 `GateDecision` values capture every routing decision the current code makes — including LL-011's hamza-dropped variants (GM-008 vs GM-009) — so the replacement can be verified to agree on every row before hitting a real device. A matrix miss on any row is a guaranteed regression.
- **Impact:** This becomes the DEC-050 migration's acceptance test. The matrix covers every intent, every gate, the `requires_llm_classify` flag per row, explicit ground-truth payloads, and a `FakeGeminiService` interface spec so the harness can run without a real LLM or internet connection. The 32 rows achieve ≥2 per intent (the coverage rule). Without the matrix, a router migration is blind — you ship, find regressions on a real device, and trace them back one at a time (the exact pattern DEC-036/037/039 established as broken).
- **Rule:** Any classifier/router/parser migration must start with a golden matrix that encodes current behavior as ground truth. The matrix must explicitly cover every known edge case and regression from the project's own lesson log. No migration ships without the matrix passing against the replacement.
- **Source:** `23_golden_intent_matrix.md`, DEC-050, LL-011
- **Linked Decision ID:** DEC-050

---

## LL-014: Hand-Computed Seed Fixtures Close the Fake-Coverage Gap

- **Discovered:** 2026-07-20 — Phase 0 Foundation
- **Lesson:** DEC-048 proved that tests re-deriving service formulas as local constants catch nothing — the test passes unchanged against a broken implementation because it recomputes the same (buggy) math. The 10 hand-computed seed fixture cases (A through I plus DEC-048 regression) close this gap: every intermediate value in every formula is traced step-by-step from the formula spec, and the expected output is pre-computed independently of running the code.
- **Impact:** If a test fails, the formula trace tells you exactly which step diverged — no guessing. The fixture covers: DTI boundary at 33% (pass/no), soft-deleted profile rows, active-goal 'wait' verdict, `max(profileEstimate, itemizedSum)` for commitments, `calculateRemainingBudget()`, and the DEC-048 heavy-deletion integrity score case (3 kept / 10 deleted → score=41). Each case documents exact seed rows + hand-computed expected JSON output. The cross-check procedure (§6) enforces: "If mismatch → BLOCK — do not adjust the expected value to match the code. Find which is wrong."
- **Rule:** Every financial/math service must have hand-computed seed fixtures where each formula step is traced with explicit values, and the expected output is pre-computed from the formula spec — never from running the code. Assert against these pre-computed values; never adjust the expected value to match a buggy implementation.
- **Source:** `24_test_seed_fixture.md`, DEC-048, LL-010
- **Linked Decision ID:** DEC-048

---

## LL-037: Live Schema Verification Before Writing Tests

- **Discovered:** 2026-07-20 — Phase 0 Foundation
- **Lesson:** Before designing test seed fixtures, verify every database column the services reference actually exists on the live schema with the correct type. The Backend/DB Architect queried `information_schema.columns` against the live Supabase instance (`kqhyjngtquutzdvjfbnf`, Frankfurt) for all 4 tables (`financial_profile`, `commitments`, `transactions`, `goals`) and confirmed 0 missing columns — preventing the DEC-036 class of bugs where code inserts into non-existent columns and every write fails silently (100% failure rate on purchase confirmations, discovered only by live device testing + direct Supabase queries).
- **Impact:** Also verified RLS policies on all 6 public tables (3 policies each on SELECT/INSERT/UPDATE for 5 tables, 2 for `purchase_decisions`), confirmed `transactions` and `goals` have no DELETE policy (correct — soft-delete is application-level via `is_deleted`), and documented that the local `supabase/migrations/` directory contains only 1 migration file while the live database has 6 tables — the other 5 were deployed via Dashboard SQL Editor or earlier migrations not in the repo. Recommended `supabase db pull` to sync before any local schema changes.
- **Rule:** Before writing any test that depends on a database schema, run a live schema verification: query `information_schema.columns` for every table the test touches, and assert every column referenced in the service code exists with the correct name and type. Zero-tolerance for assumption-based schema references. Also verify RLS policies are present on all tables (select/insert/update at minimum).
- **Source:** `24_test_seed_fixture.md` §2, DEC-036
- **Linked Decision ID:** DEC-048

---

## LL-044: Documentation Path Drift Is a Traceability Defect

- **Discovered:** 2026-07-21 — Phase 7 Documentation Closeout
- **Lesson:** When service files are referenced in documentation under the wrong directory path (e.g., `lib/core/services/` for files that actually live at `lib/features/chat/services/`), every reference becomes a dead link for anyone reading the spec pack. Phase 7 found 2 wrong service paths in `00_active_capabilities.md`, 2 in `12_decision_log.md` (DEC-035's impact field), and 2 cross-file path references — plus a stale repo path in `00_project_context.md` (`/Users/abdurrahmanjahfali/Azdal` instead of `/Users/abdurrahmanjahfali/Projects/Azdal`). Each wrong path is a silent traceability break — the capability claims to derive from a file that doesn't exist at the stated location.
- **Impact:** The path drift went undetected across multiple stages (from Stage 4 through Phase 0) because no gate checks that file paths in documentation match the actual file tree. A reader checking `lib/core/services/purchase_decision_service.dart` against the stated capability would find no such file — the real service is at `lib/features/chat/services/purchase_decision_service.dart`. The `gemini_service.dart` path (`lib/core/services/`) IS correct — the drift only affects the services that live under `lib/features/chat/services/`, which is most of them. The `swarm.yaml` repo path drift (`/Azdal` → `/Projects/Azdal`) was flagged but not fixed — it's outside `app-spec/` and falls under DevOps scope.
- **Rule:** At every stage close, the Documentation Steward must verify that every file path referenced in the spec pack's File/Evidence columns resolves to an actual file. A `search_files(target='files')` check against `lib/` for each referenced filename catches the mismatch. This check should be part of the DEC-045 gate protocol.
- **Source:** `00_active_capabilities.md`, `12_decision_log.md` (DEC-035 impact field), `00_project_context.md`, `goal_phase_0.5_tool_calling_router_DRAFT.md` line 178
- **Linked Decision ID:** DEC-045

---

## LL-045: Decision Flipping Requires a Trail — the DEC-050 SDK Case

- **Discovered:** 2026-07-21 — Phase 7 Documentation Closeout
- **Lesson:** When a decision's key parameter changes (e.g., DEC-050's target SDK from `firebase_ai` to `googleai_dart`), the flip must be explicit in the decision record itself — a new "SDK decision (flipped)" field, an updated date, and a clear rationale trail. A silent flip would leave downstream consumers (the personal build plan, the research doc, the goal DRAFT) referencing the old SDK, creating a fork between the decision log and the execution plan.
- **Impact:** DEC-050 originally recommended `firebase_ai` behind a `RouterLlm` interface (2026-07-18 research). The Phase 7 closeout flipped it to `googleai_dart` as primary — no Firebase dependency, works with the sideloaded APK that is the personal build's distribution path. `firebase_ai` remains the alternative, gated on the App Check pre-flight. The flip is recorded inline in DEC-050's own record (the "SDK decision (flipped 2026-07-21)" field), in the summary table status, and in `00_active_capabilities.md`. The personal build plan (`21_personal_build_plan.md`) still says `firebase_ai` at line 158 — that's now a drift that the next stage must reconcile.
- **Rule:** Any change to a decision's core parameter (SDK, architecture, timing) must be recorded as an explicit inline update to the decision record itself, not just in a separate DEC or the summary table. The update must include: the date it was flipped, the new recommendation, the rationale, and a flag noting any downstream documents that now drift and need reconciliation.
- **Source:** `12_decision_log.md` DEC-050, `21_personal_build_plan.md` line 158, `23_research_tool_calling_router.md`
- **Linked Decision ID:** DEC-050

---

## Key Decisions (Permanent)

| ID | Decision | Date | Rationale |
|----|----------|------|-----------|
| DEC-001 | 3-tier system: Coach → Smart Lender → Wealth Builder | 2026-05-21 | Each tier feeds the next; solves sustainability |
| DEC-002 | Track: Financial Education | 2026-05-21 | Core product is educational; better fit than GenAI track |
| DEC-003 | Hybrid architecture: LLM understands, SQL calculates, GenUI displays | 2026-05-16 | Prevents financial math hallucination |
| DEC-004 | Phase 1 free, Phase 2 B2B credit scoring, Phase 3 lending | 2026-05-21 | Avoids needing SAMA license for MVP |
| DEC-005 | Hackathon MVP = Tier 1 Coach ONLY, Tier 2-3 = vision slides | 2026-05-21 | Sharp solution wins; scattered loses |
| DEC-006 | Chat UI as sole screen — widgets inline | 2026-05-20 | Zero navigation, zero friction |
| DEC-007 | Dark mode only, Cairo font, Western numerals | 2026-05-20 | Visual identity consistency |
| DEC-008 | Flutter + Gemini Flash + Supabase + Riverpod | 2026-05-19 | Proven stack for rapid mobile AI |
| DEC-009 | Hybrid verification: Open Banking + AI + Integrity | 2026-05-21 | Anti-gaming for behavioral scoring |
| DEC-010 | No hard delete — isDeleted flag | 2026-06-29 | Anti-ghost protocol per global contract |

---

## Related
- `12_decision_log.md` — Formal decision records
- `13_assumptions_risks.md` — Risk registers
- `docs/archive/raw-ideas-brainstorming.md` — Original brainstorming sessions
