# Azdal — Active Capabilities

> **Status:** 🟢 Stage 4 (BUY+INTG+COMMIT+GOAL) complete and device-verified end-to-end, after 5 critical post-ship fixes (DEC-036) + 4 more found on retest (DEC-037) + a buy-intent detection hardening pass (DEC-037-B) + a new remaining-budget query feature (DEC-038) + an advanced-scenario retest fixing 2 more bugs and explicitly deferring 3 product gaps (DEC-039)  
> **Last Updated:** 2026-07-15

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
| Integrity Score calculator | Pure Dart `IntegrityScoreService` — 3 active factors (`logging_consistency`, `receipt_upload_rate`, `no_deletion_rate`), 2 locked (bank-link future). Score 0-100. INTG-01 ✅ | `lib/core/services/integrity_score_service.dart` |
| Integrity Score widget | `summary_card` widget — score display + 3-factor breakdown + 2 locked badges ("قادم مع الربط البنكي"). INTG-02 ✅ | `lib/features/chat/widgets/widget_catalog.dart` |
| Commitments CRUD | `CommitmentService` — seed from Cold Start `monthly_commitments` estimate, reusable `financial_profile` table. COMMIT-01 ✅, device-verified: a real commitment ("قسط سيارة", 678 SAR/month) saved and confirmed via direct Supabase query. List rendering now collapses recurring (no-fixed-total) commitments to a single "X ريال شهرياً" line instead of repeating the same number 3x | `lib/features/chat/services/commitment_service.dart`, `lib/features/chat/chat_screen.dart` |
| Goals CRUD | `GoalService` — add/view/complete/adjust, mirrors commitment flow. GOAL-01/02 ✅ | `lib/features/chat/services/goal_service.dart` |
| "Can I buy?" engine | Pure Dart `PurchaseDecisionService` — DTI 33% cap, no-proration MVP per DEC-026. Unknown income = need-info refusal. BUY-01 ✅, device-verified end-to-end including the purchase-confirmation write (real transaction row + undo). Income-clarification submit now re-runs the pending purchase decision automatically instead of asking the user to retype it | `lib/core/services/purchase_decision_service.dart` |
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

## Related
- `00_project_context.md` — Project identity and team
- `16_implementation_backlog.md` — Build plan and timeline
