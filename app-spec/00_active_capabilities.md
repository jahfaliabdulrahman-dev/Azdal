# Azdal — Active Capabilities

> **Status:** 🟢 Stage 4 (BUY+INTG+COMMIT+GOAL) complete and device-verified end-to-end, after 5 critical post-ship fixes (DEC-036) + 4 more found on retest (DEC-037) + a buy-intent detection hardening pass (DEC-037-B) + a new remaining-budget query feature (DEC-038) + an advanced-scenario retest fixing 2 more bugs and explicitly deferring 3 product gaps (DEC-039). 🟢 Phase 0 Foundation complete — golden intent matrix, real service tests, mutation check, fake test deletion, IntentRouter extraction (DEC-051). 🟢 Personal build direction adopted (DEC-049 through DEC-054). 🟡 Phase 0.5 router substantially implemented (DEC-050 — SDK migrated to `googleai_dart`, router wired into `chat_screen.dart`, 40 unit tests, redundant `gemini_service.dart` classifiers removed) but not device-verified or fully closed.  
> **Last Updated:** 2026-07-21

---

## Current Capabilities (Planning Stage)

### ✅ COMPLETE — Business Strategy

| Capability | Evidence | File |
|------------|----------|------|
| Product vision defined | 3-tier system + 5-phase journey | `00_product_discovery.md` |
| Business model designed | BMC with 4 revenue phases | `docs/business/business-model-canvas.md` |
| Market research complete | 20+ refs incl. SAMA, Forbes | `docs/business/market-research.md` |
| Competitive analysis | SWOT + PESTLE + Porter's | `docs/business/` |
| Pitch deck ready | 9-slide investor pitch | `docs/business/pitch-deck.md` |
| Hackathon strategy locked | Track, team, timeline, demo script | `docs/business/hackathon-strategy.md` |

### ✅ COMPLETE — Technical Architecture (Planning)

| Capability | Evidence | File |
|------------|----------|------|
| Architecture decision final | Hybrid: LLM understands, SQL/Dart calculates, GenUI displays | `07_flutter_architecture.md` |
| Tech stack chosen | Flutter + Gemini + Supabase + Riverpod, voice via `speech_to_text` (cross-platform, DEC-016) | `07_flutter_architecture.md` |
| API design drafted | Behavioral Credit Score API schema | `07_flutter_architecture.md` |
| Cost analysis done | Gemini Flash ~$1.50/user/month | `02_monetization_entitlements.md` |
| Hybrid verification arch designed | Open Banking ground truth + AI enrichment + Integrity | `07_flutter_architecture.md` |
| Multi-agent validation | 3 agents + Gemini critique complete | `docs/archive/` |

### ✅ COMPLETE — Stage 1 (Project Init), device-verified on TECNO LJ7 (Android)

| Capability | Evidence | File |
|------------|----------|------|
| Flutter scaffold | Riverpod + go_router, single `/` route | `lib/main.dart`, `lib/app/` |
| Gemini connection | Real API round-trip confirmed (`pong`), compile-time key via `--dart-define-from-file=.env` — `Platform.environment` doesn't work on Android, this bit the project twice before landing correctly | `lib/core/services/gemini_service.dart` |
| Supabase live | Real project, Frankfurt, 5 tables + 14 RLS policies deployed, Anonymous Sign-In enabled | `app-spec/INIT-03_supabase_schema.md`, DEC-017 |
| Cairo font | Bundled local `.ttf` files, zero network dependency (not `google_fonts` runtime fetch) | `assets/fonts/` |
| CI | GitHub Actions, lint only (`flutter analyze`) | `.github/workflows/lint.yml` |
| Isar (local cache) | **Deferred, not built** — re-enabling it broke `flutter build apk --release` (AGP 8.8 incompatibility); revisit with a maintained fork or `drift`/`hive_ce` when Stage 2+ actually needs local caching | DEC-015 |

### ✅ COMPLETE — Stage 2 (Chat + Transaction Entry), device-verified

| Capability | Evidence | File |
|------------|----------|------|
| Chat UI | 4-element input bar (📷 🎤 text ↑), bubbles, typing indicator, offline banner | `lib/features/chat/chat_screen.dart` |
| ChatProvider | Riverpod `StateNotifier<ChatState>` | `lib/features/chat/providers/chat_provider.dart` |
| Gemini integration | Saudi-dialect system prompt, 6-widget JSON catalog, `gemini-flash-latest` | `lib/core/services/gemini_service.dart` |
| Voice input | `speech_to_text`, live interim transcription (~2s feedback), Riverpod-reactive listening state (icon no longer desyncs from the real mic state) | `lib/features/chat/services/voice_service.dart` |
| Transaction entry | Confirm reuses the first (already-shown) Gemini classification instead of re-classifying — a stale "✅ saved" message that silently didn't save was found and fixed | `lib/features/chat/chat_screen.dart` |
| Compound splitting | Total computed client-side from line items (Dart, not LLM) — matches "LLM never calculates"; a $0-total bug from trusting Gemini's own total was found and fixed | `lib/features/chat/widgets/widget_catalog.dart` |
| Cold Start Intelligence | 3 questions → instant insight, income saved to `transactions`. **Known gap:** the `monthly_commitments` answer is used for the insight ratio then discarded — Stage 4's COMMIT-01 must reuse it, not re-ask (DEC-019) | `lib/features/chat/chat_screen.dart` |
| Tests | 16/16 passing (`chat_provider_test.dart`, `gemini_service_test.dart`, `widget_test.dart`) | `test/` |

### ✅ COMPLETE — Stage 3 (OCR), device-verified with a real photographed receipt

| Capability | Evidence | File |
|------------|----------|------|
| Camera/gallery picker | Bottom sheet — photograph or pick from gallery | `lib/features/chat/chat_screen.dart` |
| Supabase Storage | `receipts` bucket, private, 10MB limit, 3 RLS policies (select/insert/delete own) — verified directly via SQL, not just trusted from a report | `app-spec/INIT-03_supabase_schema.md` |
| Gemini Vision OCR | Real receipt photographed on-device → correct line items + total extracted. Was broken on first real test (`gemini-2.5-flash` deprecated, rejected by the live API) — fixed by unifying to `gemini-flash-latest` (same alias already proven for chat) | `lib/core/services/gemini_service.dart` |
| OCR failure fallback (State 3) | Confirmed on a real non-receipt image — correctly detected, manual-entry form shown | `lib/features/chat/widgets/ocr_widgets.dart` |
| Processing bubble lifecycle | Was leaving a stuck "جاري تحليل..." bubble behind on both success and failure — fixed via `ChatProvider.removeMessage(id)`, confirmed one bubble only after processing | `lib/features/chat/providers/chat_provider.dart` |
|| System share sheet (OCR-02) | **Not wired up** — `receive_sharing_intent` package builds fine at the pinned version (1.8.0), so it's not actually build-blocked despite earlier reports; the handler code in `main.dart` is just still commented out and untested. `pubspec.yaml` also has a leftover duplicate declaration (one commented, one active) that should be cleaned up | `lib/main.dart` |

### ✅ COMPLETE — Stage 4 (BUY + INTG), device-verified (DEC-036/037/037-B — two rounds of critical fixes before this was genuinely solid)

**Note on this section's history:** the initial implementation was logged as DEC-035 "implemented without deviations" — that claim was premature. Round 1 (DEC-036): independent live-device + direct-database verification found and fixed 5 critical bugs: (1) `purchase_decisions` insert used non-existent columns, (2) `quick_input_form` submit button never disabled, allowing unlimited duplicate writes, (3) success bubbles showed the same sentence twice, (4) Arabic-Indic numerals silently failed `double.tryParse` in every form field, (5) a regression from fixing #2 — the widget-to-handler key was renamed `_form_kind` but the handler still read `form_kind`, silently breaking commitment/goal/income-clarification saves entirely. Round 2, on retest (DEC-037): (6) `financial_profile.upsert()` never cleared `is_deleted`, so a once-soft-deleted profile row made "Can I Buy?" loop asking for income forever; (7) the commitment list showed the same number three times for recurring/open-ended commitments; (8) receipt images uploaded successfully but the URL was never attached to the transaction row, so `receipt_upload_rate` was stuck at 0% forever; (9) `ElevatedButton`'s disabled state silently used Material's default palette instead of the app's custom colors, making answered-widget text/fills nearly invisible. A further retest found the local Arabic-keyword regex gates required exact hamza spelling and missed common dialectal typing entirely — escalated to an Opus 4.8 consult (DEC-037-B) given this is the product's signature feature; fix shipped as a safety-net classifier call plus a `buy_intent`/`buy_query` prompt-overlap fix, with the larger unified-router redesign explicitly deferred to post-hackathon. See DEC-036, DEC-037, DEC-037-B, LL-010, LL-011.

| Capability | Evidence | File |
|------------|----------|------|
| Integrity Score calculator | Pure Dart `IntegrityScoreService` — 3 active factors (`logging_consistency`, `receipt_upload_rate`, `no_deletion_rate`), 2 locked (bank-link future). Score 0-100. INTG-01 ✅ | `lib/features/chat/services/integrity_score_service.dart` |
| Integrity Score widget | `summary_card` widget — score display + 3-factor breakdown + 2 locked badges ("قادم مع الربط البنكي"). INTG-02 ✅ | `lib/features/chat/widgets/widget_catalog.dart` |
| Commitments CRUD | `CommitmentService` — seed from Cold Start `monthly_commitments` estimate, reusable `financial_profile` table. COMMIT-01 ✅, device-verified: a real commitment ("قسط سيارة", 678 SAR/month) saved and confirmed via direct Supabase query. List rendering now collapses recurring (no-fixed-total) commitments to a single "X ريال شهرياً" line instead of repeating the same number 3x | `lib/features/chat/services/commitment_service.dart`, `lib/features/chat/chat_screen.dart` |
| Goals CRUD | `GoalService` — add/view/complete/adjust, mirrors commitment flow. GOAL-01/02 ✅ | `lib/features/chat/services/goal_service.dart` |
| "Can I buy?" engine | Pure Dart `PurchaseDecisionService` — DTI 33% cap, no-proration MVP per DEC-026. Unknown income = need-info refusal. BUY-01 ✅, device-verified end-to-end including the purchase-confirmation write (real transaction row + undo). Income-clarification submit now re-runs the pending purchase decision automatically instead of asking the user to retype it | `lib/features/chat/services/purchase_decision_service.dart` |
| Buy-intent detector | Isolated history-free `_buyIntentSystemPrompt` per DEC-029 (BRP), rewritten so item+amount always classifies as `buy_intent` regardless of interrogative phrasing ("هل أقدر أشتري..."). Backed by a hamza/ta-marbuta-normalized keyword gate (`_normalizeArabic`) plus a `classifyBuyIntent` safety-net call in the general-chat fallback for any digit-bearing message the gate misses (DEC-037-B) | `lib/core/services/gemini_service.dart`, `lib/features/chat/chat_screen.dart` |
| Verdict widget | YES/WAIT/NO verdict card with Arabic explanation + DTI breakdown. BUY-03 ✅ | `lib/features/chat/widgets/widget_catalog.dart` |
| Remaining-budget query | New (DEC-038): "كم باقي من ميزانيتي؟" — pure Dart `PurchaseDecisionService.calculateRemainingBudget()`, zero LLM calls, mirrors the integrity-score-query pattern. Replaces a prior free-form-chat answer that had no real computation behind it and was observed going stale/off-topic | `lib/features/chat/services/purchase_decision_service.dart`, `lib/features/chat/chat_screen.dart` |
| BUY-02 (Edge Function) | **Cancelled** — DEC-024/026 moved all financial math to pure Dart. No Supabase Edge Function needed. | — |
| Arabic-Indic numeral input | `_arabicToWestern` helper applied to all form-field numeric parses (commitment/goal add/adjust, buy-intent income clarification, OCR manual entry, Cold Start) | `lib/features/chat/chat_screen.dart` |
| Receipt-to-transaction linkage | `receipt_url` now threaded through `saveCompoundSplits` and attached to every row in a compound-split group, fixing a permanently-stuck 0% `receipt_upload_rate` | `lib/features/chat/services/transaction_service.dart`, `lib/features/chat/chat_screen.dart` |
| Answered-widget legibility | `ElevatedButton.styleFrom` now sets `disabled*` colors explicitly everywhere (action_buttons, quick_input_form submit, compound_split_card confirm) so Material's default disabled palette can't silently override the app's colors once a widget is answered | `lib/features/chat/widgets/widget_catalog.dart` |
| Known gap (test-quality) | `test/purchase_decision_service_test.dart`/`integrity_score_service_test.dart` don't call the real service classes — they re-derive the formulas as local constants. "34/34 passing" did not and will not catch bugs in these two services. Real coverage still needed. | `test/` |
| Known deferred item | Unified single-classifier router to fully retire the 3 local regex intent-gates (DEC-037-B) — explicitly deferred to post-hackathon; the safety-net fix covers the demo-critical path in the meantime | `lib/features/chat/chat_screen.dart` |
| Coach-chat history hygiene | Widget-bearing bot replies (verdict/form/list/summary cards) now excluded from the history sent to the general coach LLM — fixes an observed case where an unrelated question got an answer contaminated by an earlier isolated-flow reply | `lib/features/chat/chat_screen.dart` |
| Commitment/goal completion detection | Adjusting remaining-to-zero or current-to-target now auto-completes the row (`markCompleted`/`markAchieved` + congratulatory reply) instead of silently leaving it `active` with a generic "updated" reply | `lib/features/chat/chat_screen.dart` |
| Known deferred item (DEC-039) | Single-message multi-item buy requests ("جوال بـ 2000 ودراجة بـ 800" in one message) confuse single-item extraction — works correctly as two separate messages; not fixed, documented as a narrow by-design limitation | `lib/core/services/gemini_service.dart` |
| Known deferred item (DEC-039) | No direct "كم نسبة التزاماتي؟" (DTI ratio) query — only surfaced as a side effect of a buy-intent verdict. Same shape as the gap DEC-038 closed for remaining budget; natural low-risk follow-up, not done for the hackathon | `lib/features/chat/chat_screen.dart` |
| Known deferred item (DEC-039) | Marking a commitment "خلصته بالكامل" only flips status — does not create a real expense transaction, so that month's spending/remaining-budget/integrity-score figures don't reflect the payoff. Valid data-completeness gap raised by the founder directly; deliberately deferred as too large/risky to land before the demo, not because it's low-priority for production | `lib/features/chat/chat_screen.dart` |

### ✅ COMPLETE — Design

| Capability | Evidence | File |
|------------|----------|------|
| Visual identity locked | Navy `#001F5E` / Cyan `#32C2FF`, Cairo font, light mode only | `docs/design/visual-identity.md`, DEC-013 |
| Logo | Shield + upward bar-chart (not Solomon's Seal — corrected by DEC-013 to match the actual submitted AMAD deck) | `assets/Azdal logo.jpeg` |
| Design system defined | 6-widget catalog, chat screen, 4-element input bar (📷🎤 + text + ↑) | `docs/design/design-system-original.md`, DEC-018 |
| UI screens prototyped | HTML prototype | `docs/design/ui-screens.html` |

### ✅ COMPLETE — Knowledge Foundation

| Capability | Evidence | File |
|------------|----------|------|
| Financial knowledge layer | 23 academic references | `docs/research/financial-knowledge-layer.md` |
| Behavioral science applied | Fogg, Eyal, Amabile, Kahneman | `00_product_discovery.md` |
| Saudi-specific market layer | SAMA, CMA, PDPL, platforms | `docs/research/financial-knowledge-layer.md` |

### ✅ COMPLETE — AMAD Hackathon Application

| Capability | Evidence | File |
|------------|----------|------|
| Registration submitted | Before June 1 deadline | `00_project_context.md` |
| **Preliminary acceptance** | **Received June 28, 2026** ✅ | `00_project_context.md` |
| Track locked | Financial Education (التعليم المالي) | `docs/business/hackathon-strategy.md` |
| Team registered | Abdulrahman + Saja + Deema | `00_project_context.md` |

---

### ✅ COMPLETE — Phase 0 Foundation (Personal Build groundwork, DEC-051)

| Capability | Evidence | File |
|------------|----------|------|
| Golden intent matrix | 32 Saudi-dialect rows, 10 `expected_intent` values, 5 `GateDecision` values. JSONL fixture at `test/fixtures/golden_intent_matrix.jsonl` with deterministic `flutter test` harness (`test/golden_intent_matrix_test.dart`, 8 tests, all GREEN). Covers every known edge case and regression from LL-011. Three rows reconciled to `general_chat` with documented annotations (GM-015, GM-020, GM-032 — genuine current-router behavior, not aspirational). | `app-spec/23_golden_intent_matrix.md`, `test/fixtures/golden_intent_matrix.jsonl`, `test/golden_intent_matrix_test.dart` |
| Real service tests (DEC-048 gap closed) | Hand-computed seed fixtures (cases A–I + DEC-048 regression) with formula traces. Old fake groups deleted (`group('IntegrityScoreService', ...)` from integrity test, `group('PurchaseDecisionService', ...)` from purchase test) — both re-derived formulas locally as constants and passed when the real service was buggy. Coverage-equivalence mapping: `test/fixtures/coverage_equivalence_mapping.md`. | `test/purchase_decision_service_test.dart`, `test/integrity_score_service_test.dart`, `test/fixtures/coverage_equivalence_mapping.md` |
| Mutation check | Repeatable `tool/mutation_check.sh` — 4/4 PASS. Re-introducing DEC-048 bug makes real test RED (expected 23, got 0). Weakening DTI cap (0.33→0.99) makes real test RED. Evidence at `test/fixtures/mutation_evidence/`. | `tool/mutation_check.sh`, `test/fixtures/mutation_evidence/` |
| IntentRouter extraction | All 6 regexes moved character-for-character from `chat_screen.dart` into `lib/features/router/intent_router.dart`. MD5 of regexes preserved (7a900abbc1f563511b8900b408639b8d). Zero behavioral change — verified by QA Tester + SCSI Guardian. | `lib/features/router/intent_router.dart` |
| Live schema verification | `information_schema.columns` queried against live Supabase for all 4 tables — 0 missing columns. RLS policies confirmed on all 6 public tables. Recommended `supabase db pull` to sync local migrations. | `24_test_seed_fixture.md` §2, LL-037 |
| flutter test | 59/59 pass (32 harness rows + real group tests + pre-existing tests). flutter analyze: 0 errors. | `test/` |

### ✅ COMPLETE — Personal Build Planning (DEC-049 through DEC-054)

| Capability | Evidence | File |
|------------|----------|------|
| Personal build direction | Chat-only, founder as first real user. Falsifiable metrics (5 real measures). Coach tone philosophy: blunt honesty, no gloating. | DEC-049, `20_personal_vision_and_goals.md`, `21_personal_build_plan.md` |
| Tool-calling router (Phase 0.5) | SDK migrated to `googleai_dart` (2026-07-21) — no Firebase dependency, no App Check gate needed for this path (G1 only ever applied to the unused `firebase_ai` alternative). Router built and wired into `chat_screen.dart`; `gemini_service.dart`'s remaining 3 responsibilities (cold-start, general chat, OCR) also migrated the same day, closing the dual-SDK window. | DEC-050, `23_research_tool_calling_router.md` |
| Account durability plan (Phase 0) | Remove guest sign-in → require login from first launch. Nightly pg_dump backups. | DEC-051, `22_research_account_durability.md` |
| Memory + proactivity plan | `user_facts` + `preference_profile` tables. Deterministic recall, no embeddings. On-device nudges with anti-nagging guardrails. | DEC-052, `24_research_memory_and_proactivity.md` |
| Financial engines plan | Fixed category taxonomy (14 keys), habit detection, unit economics, payoff-vs-invest (IRR in Dart), CMA/SAMA advice line. | DEC-053, `25_research_financial_intelligence_engines.md` |
| World-facing tools plan | Grounded Google Search for real KSA price/product lookup — two-call architecture, grounded-or-silent enforcement. | DEC-054, `26_research_world_facing_tools.md` |

---

### 🔄 IN PROGRESS

| Capability | Status | Next Action |
|------------|--------|-------------|
| OCR-05 — cancel-before-confirm + transaction undo | Not yet built (DEC-020) | Found during live testing: no way to discard a wrong image upload before it's saved, or undo after. `is_deleted`/`deleted_at` already exist on `transactions` — this is UI wiring, not a schema change |

---

### ⬜ NOT STARTED

| Capability | Required For Stage | Notes |
|------------|-------------------|-------|
| System share sheet (OCR-02) | Stage 3 | Deferred — package builds fine, just never wired up or tested. Not urgent for MVP since the camera/gallery path already covers the core flow |
| Goals + gap detection | Stage 4 | `goals` table deployed, GOAL-01/02 built — gap detection (GOAL-03) not yet done |
| Tier 2 simulation (demo) | Stage 4 | Gateway showcase |
| Full widget/integration test suite | Stage 5 | Beyond the 16 unit/widget tests that exist today |
| Hostile audit | Stage 5 | Pre-release security review |
| CI/CD build + release pipeline | Stage 5 | CI currently lint-only |
| Release | Stage 6 | App Store + Play Store |

---

### 🔮 FUTURE (Post-Hackathon)

| Capability | Phase |
|------------|-------|
| B2B Behavioral Credit Score API | Phase 2 (Year 1-2) |
| SAMA license application | Phase 3 (Year 3+) |
| Murabaha lending infrastructure | Phase 3 |
| Investment platform integrations | Phase 4 |
| SMS parsing (Android) | Phase 2+ |
| Open Banking real integration | Phase 2+ |

---

### ➡️ NEXT PHASE — The Personal Build (the real successor to the hackathon)

The permanent next phase is **not** the roadmap above (that's the long-term
business vision). It's the **personal build**: a chat-only Azdal developed
indefinitely for the founder's own financial life, where his real turnaround is
the acceptance criterion. This is now the project's primary direction.

| Item | Where documented |
|------|------------------|
| The "why", the founder's goals, the coach's required tone | `20_personal_vision_and_goals.md` |
| The phased plan (Phase 0 durability → 0.5 router → 1–3 capabilities) | `21_personal_build_plan.md` |
| Personal-build direction decision | DEC-049 |
| Tool-calling router (replaces regex intent-gates, SDK: `googleai_dart`) | DEC-050 |
| Account durability — remove guest, require login from launch | DEC-051 |
| Memory layer + preference profile + proactivity engine | DEC-052 |
| Financial-intelligence engines + fixed category taxonomy | DEC-053 |
| World-facing tools — grounded KSA price/product lookup | DEC-054 |
| Deep-research consults (docs 22–26) | `22-26_research_*.md` |

**Phase 0 status (2026-07-21):** Golden intent matrix, real service tests,
mutation check, fake test deletion, and IntentRouter extraction are **COMPLETE**
(DEC-051). The account durability work (guest removal, backups) and
commitment-payoff → transaction fix are still outstanding.

**Phase 0.5 status (2026-07-21):** SDK decision resolved — **`googleai_dart`**,
which needs no Firebase App Check (the G1 gate only ever applied to the unused
`firebase_ai` alternative and is moot for this path). Implementation is
substantially done: `lib/features/router/` (`router_llm.dart`, `tool_types.dart`,
`tools.dart`, `route.dart`, `tool_call_trace_service.dart`) migrated to
`googleai_dart` and wired into `chat_screen.dart` as the live dispatch path;
`gemini_service.dart`'s 3 old classifier methods
(`classifyTransaction`/`classifySetupIntent`/`classifyBuyIntent`) deleted as
redundant; 4 dead intent-gate handlers removed from `chat_screen.dart`; 40
router unit tests added (`test/router_test.dart`); the `tool_calls` trace
table is live in production Supabase.

**Toolchain-verified 2026-07-21** (Route A, run on Abdulrahman's real machine
— Claude's sandbox has no Flutter and only 4.4GB free, confirmed genuinely
insufficient after an actual install attempt): `flutter analyze` → 0 errors,
0 warnings, 69 pre-existing infos. `flutter test` → **105 passed, 0 failed**,
including the digit-normalization fix's new test file. The per-file
breakdown in that report had several wrong numbers (independently caught via
direct `grep -c` on every test file), but the 105 total matches the real
sum exactly, so the aggregate result holds up.

**Device-verified 2026-07-21 (LL-010).** Fresh debug build installed on a
real connected device (TECNO LJ7, Android 15). A real chat message sent
through the live app round-tripped through the actual `googleai_dart`→Gemini
call (never exercised outside `FakeRouterLlm` before this), correctly
dispatched to the log-expense tool, and produced the expected auto-logged
confirmation bubble. Confirmed directly in Supabase: the transaction row
landed with the correct amount, category, and timestamp. This is real
evidence the SDK migration works end to end, not just in tests.

**`gemini_service.dart` migration complete (2026-07-21).** SDK swapped to
`googleai_dart` for all 3 remaining responsibilities (coach chat, cold-start
reaction, receipt OCR); `google_generative_ai` fully removed from
`pubspec.yaml`/`pubspec.lock` — the dual-SDK window is closed.
**Toolchain-verified:** `flutter analyze` → 0 errors, 0 warnings, 72 infos
(3 new cosmetic const-hints, nothing load-bearing). `flutter test` →
105/105 passing.

**Device-verified — general chat path.** Abdulrahman sent two test messages
himself directly on the physical device (device-test execution is no longer
delegated to the Hermes swarm — see below), which I read directly from the
resulting screenshots. First message ("وش رايك في وضعي المالي؟") was
correctly dispatched by the router to `GetIntegrityScoreTool` — a
defensible read, but it didn't exercise the migrated `sendMessage()` path.
A second message avoiding every tool keyword ("ليش لازم اهتم بالتخطيط
المالي من الأساس؟") reached general chat and returned a real free-text
Bounded Reply Pattern response generated through the new `googleai_dart`
path — no fabricated numbers, ends with a concrete nudge to log expenses.
This is the specific migrated code path, confirmed working on a real device.

**Process change (2026-07-21):** device-test *execution* (tapping/typing/
sending on the physical Android device) must never be routed through the
Hermes swarm (`quick_task`/`lead_delegate`) — Abdulrahman performs the
on-device action himself; Claude only reads the resulting file and judges
pass/fail. This was prompted by a quick_task report that fabricated a
detailed but untrue account of how it entered Arabic text (an invented ADB
workaround) for a message Abdulrahman had actually typed by hand himself.

**Device-verified — receipt OCR path (2026-07-21).** Abdulrahman photographed
and uploaded a real receipt himself, in the app, on the physical device (no
Hermes involvement, per the process change above). Confirmed directly via
Supabase, not a report: the file landed in the `receipts` bucket
(`74e40a09-.../2026-07-21T21-00-28-090722_receipt.jpg`, 103KB, real
`image/jpeg`), and the Gemini Vision OCR call — now running through the
migrated `googleai_dart` path — correctly split the receipt into 2 line
items (`SEAMETAL المطاط سيارة الأختام حافة شرائط عزل 19MM*8M` — 34.00 SAR;
same product, 14MM variant — 27.00 SAR), both transaction rows written with
the shared `receipt_url` correctly linked, `is_deleted: false`. Specific
extracted brand/spec text, not a generic fallback category — real vision
extraction, not a stub. Only the on-screen rendering itself wasn't
double-checked (would need a screenshot); the persisted data is strong
enough evidence on its own.

**Cold-start device path — deliberately not live-tested.** `_checkColdStart()`
(`chat_screen.dart`) only fires when the account has zero transactions.
This device's account has weeks of real transaction history, so exercising
it would require either wiping real data (rejected — protects real financial
history) or creating a throwaway login account, which means typing a
password into an auth form — outside what gets automated regardless of
instruction. Deprioritized: `reactToColdStart()` uses the identical
`_client.models.generateContent(...)` call already proven live by the
general-chat test above, so the underlying migration risk here is low even
without a separate on-device pass.

**Still outstanding before Phase 0.5 can close:** SCSI Guardian final
sign-off (Kanban check timing out, bridge-side, retrying later).

**Immediate priority:** Guardian sign-off, whenever the Kanban bridge is responsive again.

---

## Related
- `00_project_context.md` — Project identity and team
- `16_implementation_backlog.md` — Build plan and timeline
- `20_personal_vision_and_goals.md` — the founder's why, goals, and coach tone
- `21_personal_build_plan.md` — the personal-build phased plan
