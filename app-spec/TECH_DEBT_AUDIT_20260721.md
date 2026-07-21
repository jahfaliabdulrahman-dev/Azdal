# Azdal — Tech Debt Audit (2026-07-21)

> Whole-codebase sweep, done directly against the repo (grep/read/line-count,
> not assumption). 9,501 lines across 35 `lib/` files, 1,368 lines across 8
> `test/` files. Companion to `12_decision_log.md` and `00_active_capabilities.md`.

## How to read this

Each item is scored **Priority = (Impact + Risk) × (6 − Effort)**, all fields
1–5, Effort inverted (lower effort → higher priority). Higher score = fix
sooner. This is a sweep, not a verdict — a few items (the digit-normalization
one especially) are code-level evidence of a likely bug, not a device-verified
one; per this project's own LL-010, treat it as a strong hypothesis to
confirm on-device, not a confirmed fact.

A number of items below are *deliberate, disclosed* debt (the dual-SDK state,
debug-signed APK, client-side API key) rather than accidents — that's worth
noting because it changes the remediation posture: these need a scheduled
payoff, not a fire drill.

---

## Prioritized findings

| # | Item | Category | Impact | Risk | Effort | Priority |
|---|------|----------|:-:|:-:|:-:|:-:|
| 1 | Digit-normalization duplicated with **divergent behavior** — likely live bug | Code | 4 | 5 | 2 | **36** |
| 2 | 63% of `lib/` files have zero test coverage, incl. money-adjacent code | Test | 4 | 4 | 3 | **24** |
| 3 | No crash/error monitoring beyond `print()` | Infra | 3 | 3 | 2 | **24** |
| 4 | Release APK signed with the Android **debug** key | Infra | 2 | 3 | 2 | **20** |
| 5 | `00_active_capabilities.md` says "CI is lint-only" — false | Docs | 2 | 2 | 1 | **20** |
| 6 | No structured logging (52 raw `print()` calls, 8 files) | Code | 2 | 2 | 2 | **16** |
| 7 | `mocktail` dependency structurally unusable (`final class` everywhere) | Arch/Dep | 3 | 2 | 3 | **15** |
| 8 | Gemini API key compiled into APK — decision predates "permanent build" | Infra | 2 | 3 | 3 | **15** |
| 9 | `chat_screen.dart` — 1,272-line, 46-method god-widget | Arch | 4 | 3 | 4 | **14** |
| 10 | Dual-SDK state: deprecated `google_generative_ai` still in `gemini_service.dart` | Dep | 3 | 3 | 4 | **12** |
| 11 | Test-count doc lines undercount current suite (stale by ~40 tests) | Docs | 1 | 1 | 1 | **10** |
| 12 | Stub-era header comments in `pubspec.yaml` / `analysis_options.yaml` | Docs | 1 | 1 | 1 | **10** |
| 13 | 6 app-spec docs untouched since 2026-06-29 (22 days, most active stretch) | Docs | 1 | 1 | 3 | **6** |

---

## Detail

### 1. Digit-normalization duplication (Priority 36) — ✅ RESOLVED 2026-07-21

**Fixed same day.** Extracted `normalizeArabicNumerals()` to
`lib/core/utils/arabic_numerals.dart` (digits + comma-stripping, the more
complete of the two original behaviors). Both `chat_screen.dart` (13 call
sites) and `router/tools.dart` (1 call site) now import and call the same
function; the two divergent private implementations are deleted. Added
`test/core/arabic_numerals_test.dart` (6 tests, including the exact
comma-formatted-input regression). **Toolchain-verified same day** via Route
A on Abdulrahman's real machine: all 6 tests pass as part of a clean
105/105 `flutter test` run, 0 `flutter analyze` errors/warnings. **Still not
done:** an actual on-device run (LL-010) — toolchain-clean confirms it
compiles and the unit tests pass, not that it behaves correctly in the live
app. Original finding preserved below for context.

Two separate implementations of "convert Arabic-Indic digits to Western"
exist and **behave differently**:

- `lib/features/chat/chat_screen.dart:605` — `_arabicToWestern()` — converts
  digits only. **14 call sites**, all in the quick-input-form flows (income,
  commitments, weekly spend, commitment/goal amounts, cold-start setup).
- `lib/features/router/tools.dart:27` — `_normalizeDigits()` — converts
  digits **and strips commas**. Used by the new router tools; explicitly
  tested for `'50,000'` → `50000.0` in `test/router_test.dart`.

`double.tryParse` does not accept comma thousands-separators. A user typing
`50,000` into any of the 14 `chat_screen.dart` form fields almost certainly
gets a silent `?? 0` fallback instead of the real amount — in a coach whose
entire trust model is "the Dart math is always right" (DEC-024). None of
the 14 call sites have test coverage, so this would not show up in
`flutter test`.

**Fix:** delete `_arabicToWestern`, have `chat_screen.dart` call the shared
normalizer (move it somewhere both files can import, e.g. a small
`lib/core/utils/arabic_numerals.dart`). Add a regression test with a
comma-formatted input. Verify on-device per LL-010 before trusting it's
fixed — this is exactly the class of bug that only showed up on a real
device historically (DEC-036/037).

### 2. Test coverage gaps (Priority 24)

22 of 35 `lib/` files have no direct test reference. The ones that matter:

- `transaction_service.dart` (211 lines) — writes real financial
  transactions; zero tests, despite being one of the `final class`
  money-adjacent services the rest of DEC-024's discipline protects.
- `auth_service.dart` — session/auth handling, zero tests.
- `widget_catalog.dart` (954 lines, second-largest file in the app) — renders
  every chat widget type; zero tests.
- `router_llm.dart`'s concrete `GeminiRouterLlm` — only the `RouterLlm`
  *interface* is exercised (via a hand-written `FakeRouterLlm` in
  `router_test.dart`); the real class that actually calls `googleai_dart` has
  never been invoked in a test, not even an `isConfigured`-gated smoke test
  like `gemini_service_test.dart` already does for its own `ping()`.
- All 8 screen widgets (auth, bank-link, onboarding, splash, journey,
  courses, account, main shell) — expected for hackathon speed, but worth
  tracking now that the build is permanent.

**Not debt, a strength worth keeping:** the DEC-048 "fake test" failure mode
(tests re-deriving formulas locally instead of exercising real service code)
was found and fully deleted this session, replaced by the golden intent
matrix + `tool/mutation_check.sh` (deliberately re-introduces known bugs and
confirms the real tests go red). Extend this pattern to `transaction_service`
next rather than inventing a new one.

### 3. No crash/error monitoring (Priority 24)

Error visibility today is 52 `print()` statements across 8 files
(`ignore: avoid_print`-suppressed) — readable only if someone is watching a
terminal at the exact moment. No Crashlytics/Sentry/equivalent. The new
`tool_calls` trace table (this session) covers router decisions specifically
but nothing else. For a chat-only personal build meant to run indefinitely
on one real device, an unwatched crash currently leaves no record at all.

### 4. Debug-signed release APK (Priority 20)

`android/app/build.gradle.kts` — the release build config points
`signingConfig` at `signingConfigs.getByName("debug")`, explicitly to avoid
setting up a real keystore (documented in `build.yml`'s own header comment).
Fine for today's sideload-only distribution. The catch: Android refuses
in-place updates across a signing-key change, so switching to a real release
key *later* means every existing install (including Abdulrahman's own
device) needs a full uninstall/reinstall. Cheap to fix now, while there's
exactly one install; expensive to fix later.

### 5. Stale "CI is lint-only" claim (Priority 20)

`app-spec/00_active_capabilities.md:162` (the "NOT STARTED" table) says
*"CI/CD build + release pipeline — Stage 5 — CI currently lint-only."* This
is false today: `.github/workflows/build.yml` already builds a release APK
on every push to `main` and auto-publishes it to a rolling GitHub "latest"
release. `lint.yml` is the analyze+test job; `build.yml` is a second,
already-working pipeline the doc doesn't know about.

### 6. No structured logging (Priority 16)

52 raw `print()` calls across `gemini_service.dart` (20), `voice_service.dart`
(10), `transaction_service.dart` (9), `chat_provider.dart` (5), `main.dart`
(3), `route.dart`/`router_llm.dart`/`tool_call_trace_service.dart` (5
combined). No log levels, no filtering, no way to turn debug output off in a
release build short of the lint suppression. Low urgency, but every new
feature adds a few more `print()` calls to a pile with no structure.

### 7. `mocktail` present but structurally unusable (Priority 15)

`mocktail: ^1.0.0` is in `dev_dependencies`, but essentially every domain
class in the app — `GeminiService`, `ChatState`/`ChatProvider`,
`TransactionService`, `CommitmentService`, `GoalService`,
`PurchaseDecisionService`, `IntegrityScoreService`,
`FinancialProfileService`, `VoiceService`, every `RouterTool` subclass,
`ToolCallTraceService` — is declared `final class`. `final` blocks
`extends`/`implements`/`with` from other libraries, including mocktail's own
`Mock` base class. This session's `router_test.dart` worked around it by
constructing real service instances against throwaway/unreachable Supabase
clients — a workable pattern, but undocumented as *the* standard, so the
next person to write a test will rediscover the same blocker from scratch.
**Fix:** either write this pattern down as the project's actual testing
convention (cheapest), or introduce narrow abstract interfaces for the small
number of methods tests actually need to fake.

### 8. Client-side API key — re-confirm, don't just carry forward (Priority 15)

DEC-014 accepted shipping the Gemini API key compiled into the APK as a
"hackathon MVP accepted risk" (2026-07-12). The project's own framing has
since changed from "3-day hackathon demo" to "indefinite personal build,
real financial data" (`20_personal_vision_and_goals.md`). Not saying this is
wrong — sideloaded, single-user distribution genuinely lowers the exposure —
but the original decision's justification (temporary artifact) no longer
matches the project's current reality (permanent tool), so it's worth a
deliberate one-line re-confirm in the decision log rather than silently
inheriting a hackathon-era risk acceptance forever.

### 9. `chat_screen.dart` god-widget (Priority 14)

1,272 lines, ~46 methods, and its own header doc comment lists 9 distinct
responsibilities in one class: message list, widget-catalog rendering, voice
input, transaction logging, compound-split, cold-start intelligence,
commitment/goal setup, offline detection, typing/error state. This file is
already on record (this project's own prior QA cycles — DEC-036/037/037-B)
as the single most bug-prone file in the app, which tracks: concentrating
this much logic in one class is exactly what makes it hard to reason about
or test in isolation (only 2 shallow widget-render smoke tests exist for
it). A behavior-preserving extraction (voice/OCR/commitment-goal-setup into
separate controllers) is real, multi-day work — not urgent, but the
`IntentRouter` extraction earlier this session is proof the pattern
(extract-verbatim, verify byte-identical via MD5, then test) works here.

### 10. Dual-SDK state (Priority 12)

`google_generative_ai ^0.4.0` (deprecated upstream, frozen since 2025-04)
still backs `gemini_service.dart`'s 3 remaining responsibilities (cold-start
reaction, general chat, receipt OCR) alongside the new `googleai_dart ^9.0.0`
used by the router. Already disclosed and intentionally scoped this way —
DEC-050 explicitly says "migrate once, don't dual-wield SDKs," and the team's
own comment in `pubspec.yaml` flags this as a known, separate, larger,
higher-stakes follow-up rather than an oversight. Listed here for
completeness and so it has a number attached, not because it's a fresh find.

### 11–12. Cheap documentation fixes (Priority 10 each)

- `00_active_capabilities.md`'s "flutter test 59/59" (line 130) and "16
  unit/widget tests" (line 160) both predate this session's
  `test/router_test.dart` (40 more tests) — undercounts the current suite by
  a wide margin.
- `pubspec.yaml` still carries its original "STUB — Pre-implementation
  pubspec... No flutter create has been run. No code exists yet." header;
  `analysis_options.yaml` still says "Generated manually for the
  specification stub. Will be validated by dart analyze in Stage 1." Both
  false today — 9,501 lines exist and `flutter analyze` already runs in CI.

### 13. Six stale app-spec docs (Priority 6)

`09_testing_acceptance.md`, `10_devops_release_observability.md`,
`11_ai_agent_operating_contract.md`, `14_admin_panel_specification.md`,
`15_support_operations_playbook.md`, `18_zero_trust_red_team_audit.md` all
show **Last Updated: 2026-06-29** — 22 days stale as of this audit, spanning
the entire Stage 4 + Phase 0 + Phase 0.5 stretch. `10_devops_...md` is
explicitly self-labeled *"Template — populated during Stage 5"* and
describes an aspirational multi-flavor/fastlane/App-Store pipeline that
doesn't resemble the actual single-APK pipeline now running — not wrong,
since it's labeled a template, but worth a pass to mark which of the 6 are
still deliberately aspirational vs. quietly obsolete.

---

## What's already good (worth preserving, not re-litigating)

- Strict analyzer config (`strict-casts`, `strict-inference`,
  `strict-raw-types` all on) — stronger than Flutter's default.
- The golden intent matrix + `tool/mutation_check.sh` pattern: tests that
  deliberately re-introduce known bugs and confirm they go red — the fix for
  the DEC-048 failure mode, and a good template to extend.
- Nightly encrypted Supabase backups, no-hard-delete discipline
  (`is_deleted`/`deleted_at` everywhere) — genuine data-safety debt is low.
- Most of the debt above is *disclosed* debt (dual-SDK, debug signing,
  client-side key) with a named owner and reasoning already on record — this
  is a materially easier position than undocumented/accidental debt.

---

## Phased remediation plan (alongside feature work, not a standalone sprint)

**Phase A — this week, near-zero effort/risk, do anytime:**
Fix items 5, 11, 12 (three doc corrections, all one-line-to-one-paragraph
edits, zero code risk).

**Phase B — next, high value / low effort:**
Item 1 (digit-normalization fix + device verification per LL-010), item 3
(add a crash-reporting SDK — most are a half-day integration), item 4
(generate a real release keystore while there's only one install to
migrate).

**Phase C — alongside the next capability phase (Phase 1+), not before:**
Item 2 (backfill tests for `transaction_service.dart`/`auth_service.dart`,
add a `GeminiRouterLlm` smoke test), item 7 (write down the real-instance
test pattern as the documented convention).

**Phase D — scheduled, deliberate, not urgent:**
Item 10 (migrate `gemini_service.dart` off the deprecated SDK, then delete
`google_generative_ai` entirely), item 8 (re-confirm DEC-014 in writing for
the personal-build context), item 9 (extract `chat_screen.dart`'s
responsibilities into separate controllers, same verbatim-extraction +
MD5-check pattern already proven on `IntentRouter`).

**Phase E — housekeeping, whenever convenient:**
Item 13 (review the 6 docs stale since 2026-06-29).
