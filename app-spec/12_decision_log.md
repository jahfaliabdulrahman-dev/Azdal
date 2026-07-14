# Azdal — Decision Log

> **Purpose:** Formal record of ALL architecture and product decisions.  
> **Status:** Populated from historical brainstorming (DEC-001 through DEC-010)  
> **Rule:** Every decision requires: ID, date, summary, rationale, alternatives considered, and impact.

---

## Open Decisions

None at Stage 4. All decisions below are closed.

---

## Closed Decisions

### DEC-029: Bounded Reply Pattern — Mandatory for All New LLM-Authored Fields

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Status** | ✅ Closed |
| **Summary** | Any new LLM-authored text field (verdict explanations, buy-intent `reply`, integrity summaries) follows the Bounded Reply Pattern (DEC-022): a single fenced JSON field, an explicit one-line purpose in the prompt, tone/length bounds, 2-3 concrete in-prompt few-shot examples, and a deterministic Dart fallback. Any new intent-detection call must be history-free. |
| **Rationale** | DEC-022 established the pattern for all existing LLM fields. The buy-intent detector and verdict engine introduce new LLM-authored fields — these must follow the same BRP guardrails. |
| **Impact** | gemini_service.dart gains one new isolated system prompt (`_buyIntentSystemPrompt`) following the exact structure of `_setupIntentSystemPrompt`. All number-bearing fields are Dart-computed; the LLM authors only the `reply` text. |
| **Related** | DEC-022 (BRP), DEC-003 (LLM never calculates) |

---

### DEC-026: "Can I Buy?" MVP Formula — No Proration, DTI 33% Cap, Unknown-Income Refusal

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Status** | ✅ Closed |
| **Summary** | The "Can I Buy?" verdict engine uses MVP formula: Verdict = f(disposable_after_commitments, current-month expense total, active-goal impact). Days-to-salary proration dropped. DTI > 33% forces NO. Unknown/zero income triggers need-info. All aggregations filter `type='expense' AND is_deleted=false`. |
| **Rationale** | Original PRD required `days_remaining_to_salary` — no capture mechanism. DTI 33% is hard safety rule from ACID constraints. |
| **Impact** | `PurchaseDecisionService` (pure Dart per DEC-024). Backlog BUY-02 (Edge Function) cancelled. |
| **Related** | DEC-024, `17_data_architecture_acid_constraints.md §2` |

---

### DEC-025: Integrity Score — 3 Real Factors Only, 2 Locked (Post Bank-Linking)

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Status** | ✅ Closed |
| **Summary** | Integrity Score MVP computes ONLY 3 real factors: `logging_consistency`, `receipt_upload_rate`, `no_deletion_rate` — re-weighted to sum 100%. The 2 factors needing bank-linking (`data_match_accuracy`, `response_time_factor`) are displayed as locked ("قادم مع الربط البنكي") and NEVER assigned a numeric value. DB columns for all 5 remain — the 2 locked stay NULL. |
| **Rationale** | Assigning fabricated values creates trust-fabrication risk in a product whose core value proposition IS trustworthiness. |
| **Impact** | `IntegrityScoreService` (pure Dart) computes from 3 factors. The fabricated "92% match" example in `03_user_flows_navigation.md` is replaced. |
| **Related** | DEC-024, `05_data_model_erd.md §4`, `03_user_flows_navigation.md` |

---

### DEC-024: All Financial Math in Dart — No Edge Functions, No LLM Arithmetic

| Field | Value |
|-------|-------|
| **Date** | 2026-07-14 |
| **Status** | ✅ Closed |
| **Summary** | All financial calculations (disposable income, DTI, verdict, integrity factors) are implemented in pure Dart. No Supabase Edge Functions compute any financial math. No LLM performs arithmetic — the LLM's role is strictly bounded to natural-language tasks (intent detection, generating `reply` text per DEC-029/BRP). |
| **Rationale** | DEC-003 established "LLM understands and routes — SQL calculates." Original backlog assigned BUY-02 to an Edge Function, violating this constraint. Dart-side is testable, debuggable, keeps financial logic in-repo. |
| **Impact** | `PurchaseDecisionService` + `IntegrityScoreService` are pure Dart. BUY-02 Edge Function cancelled. |
| **Related** | DEC-003, DEC-025, DEC-026, `07_flutter_architecture.md §10` |

---

### DEC-020: Cancel-Before-Confirm + Transaction Undo (Hackathon MVP Scope)

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | Two additions to close a real gap found during live OCR testing: (1) `compound_split_card` gets a "❌ إلغاء" discard action alongside "✅ تأكيد الكل" — lets the user drop a wrong/bad receipt upload before anything is written to Supabase. (2) A short-lived "تراجع" (undo) quick-action attached to the "تم تسجيل بنجاح ✅" confirmation message, soft-deleting that specific transaction (`is_deleted = true`) if tapped. Both target the moment a mistaken image upload can turn into a duplicated transaction. |
| **Rationale** | Live device testing surfaced a real scenario: user uploads a wrong/miscropped image, has no way to discard it before confirming, and if they confirm-then-reupload-correct, both get saved as separate transactions — a genuine duplicate-data risk, not just a UI annoyance. Fix (1) prevents bad data from ever reaching the database — cheapest, highest-leverage fix, since it stops the problem at its source. Fix (2) covers the case where the mistake is only noticed after confirming; it costs almost nothing to add since `transactions.is_deleted`/`deleted_at` already exist and are already used everywhere else in the schema (anti-ghost, no-hard-delete principle) — this is wiring up a UI trigger for a capability the data model already has, not new infrastructure. |
| **Alternatives** | (A) Full transaction list/edit/delete management view — rejected for now: real feature, bigger scope than this bug warrants, not what actually broke during testing. Revisit in Stage 4/5 if full transaction management becomes a real product need, not as a fix for this. (B) Do nothing, rely on users being careful — rejected: this is a hackathon MVP demoed live in front of judges; a stuck bad transaction with no recovery path is a real risk during a live demo, not a hypothetical edge case. |
| **Impact** | `lib/features/chat/widgets/widget_catalog.dart` (compound_split_card cancel action), `lib/features/chat/chat_screen.dart` (undo quick-action wiring + soft-delete call), `lib/features/chat/services/transaction_service.dart` (needs a `deleteTransaction(id)` / soft-delete method — doesn't exist yet). No schema change — `is_deleted`/`deleted_at` already deployed. Scoped to the OCR/image flow where the bug was found; the undo mechanism itself is generic enough to reuse for any confirmed transaction later, not OCR-specific. |
| **Related** | `16_implementation_backlog.md §Stage 3` (OCR-05 added), `app-spec/INIT-03_supabase_schema.md` (existing soft-delete columns), `lib/features/chat/widgets/widget_catalog.dart` |

### DEC-021: Auto-Save Simple Transactions, Drop Confirm Tap

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Single-item transactions save immediately on classification; the ✅ صحيح / 🔄 تعديل confirm step is removed for this case. `↩️ تراجع` (undo, DEC-020) is the safety net. |
| **Rationale** | The app's own empty-state tagline promises "بدون تعب" (effortless) — a mandatory confirm-tap on every logged expense contradicts that. The old "🔄 تعديل" never did real inline editing anyway (just replied with a plain-text re-prompt), so undo-then-retype is strictly cleaner than edit-then-retype. Zero-tap auto-logging reads as stronger AI confidence in a live demo. |
| **Alternatives** | (A) Keep confirm-before-save — rejected, contradicts product positioning and adds a tap with no real correction benefit over undo. (B) Auto-save with no undo — rejected, removes the only safety net for misclassification. |
| **Impact** | `compound_split_card` (multi-item messages) is unaffected — it keeps its real ❌ إلغاء / ✅ تأكيد step, since the user can genuinely adjust amounts there before anything saves. Deleted `_confirmTransaction`, `_isConfirming`, `_tryAutoClassify`, and the confirm/edit `action_buttons` handler cases. |
| **Related** | DEC-020 (undo/cancel), `03_user_flows_navigation.md` Flow: Transaction Entry |

### DEC-022: Bounded Reply Pattern (BRP) — Mandatory for All LLM-Authored Text Fields

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Any bot-facing text authored by an LLM (not hardcoded Dart strings) must be: (1) a single named JSON field, never a whole free-form message; (2) given an explicit one-line purpose in its prompt; (3) bounded by an explicit tone/length/don't-list; (4) backed by 2-3 concrete few-shot examples written directly into the prompt (never conversation history); (5) given a deterministic Dart fallback for empty/malformed output. |
| **Rationale** | The prior session's 7 prompt iterations (history-leak fix saga) drifted because there was no standing rule to check new prompt text against — instructions were added and removed ad hoc under time pressure, causing new regressions each time (bare-number parsing broke, responses became incoherent). BRP gives future prompt edits a checklist so this doesn't recur. |
| **Alternatives** | (A) Fully free-form LLM text everywhere — rejected, risks inconsistency/drift and cannot guarantee JSON safety. (B) Fully hardcoded strings everywhere — rejected, loses the actual value of personalization at the moments that matter most (Cold Start first impression, per-transaction reaction, OCR receipt summary). |
| **Impact** | Applies to: router `reply` (3 kinds), coach prompt replies, `reactToColdStart`, `ocrReceipt`'s new `reply` field. Does NOT apply to structural/systemic strings (loading states, error boundaries, button labels, undo/cancel acks) — those stay hardcoded permanently by design, not as an oversight. |
| **Related** | DEC-003 (LLM never calculates), DEC-020 (undo), DEC-021 (auto-save) |

### DEC-023: `financial_profile` Table — Durable Home for Cold Start Estimates

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | New table stores income, commitments estimate, weekly-spend estimate, and an unused-for-now salary_day, one row per user. Cold Start now persists all 3 submitted answers here instead of discarding 2 of them. |
| **Rationale** | Income was only a loosely-tagged transaction row; commitments/weekly-spend estimates were computed for the insight message and thrown away, breaking DEC-019's promise that commitments would reuse them. Without this, COMMIT-01/BUY-01 silently block. |
| **Alternatives** | (A) On-device key-value store — rejected, loses Supabase single-source-of-truth. |

### DEC-033: Commitment/Goal Setup Intent — Pre-Router Heuristic

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Cheap local keyword heuristic runs before the existing digit-gate router; on match, isolated history-free `classifySetupIntent` decides `commitment_add|view|edit`, `goal_add|view|edit`, or `none`. On `none`/failure, falls through to unmodified existing router. |
| **Rationale** | Closes entry-point gap for commitments/goals without touching `_classifySystemPrompt` (stabilized over 3 MoA rounds). Digit-bearing commitment phrases are intercepted by digit gate first — a real blind spot. |
| **Impact** | New prompt + method + handlers; zero changes to existing router/coach prompts. |

### DEC-034: `quick_input_form` — Optional `prefill` + `_form_kind`

| Field | Value |
|-------|-------|
| **Date** | 2026-07-13 |
| **Status** | ✅ Closed |
| **Summary** | Fields gain optional `prefill` (TextEditingController). Widget JSON gains optional `_form_kind` echoed as `form_kind` in submit payload. Both default to today's behavior when absent. |
| **Rationale** | Needed for LLM-draft pre-filling and clean form routing. Replaces fragile key-sniffing that doesn't scale past one form. |

---

### DEC-019: "Can I Buy?" (BUY-01→04) Moved From Stage 3 to Stage 4

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | BUY-01→04 removed from Stage 3 and rescheduled into Stage 4, sequenced after the new COMMIT-01 and existing GOAL-01. Stage 3 is now OCR-only (OCR-01→04). |
| **Rationale** | `01_prd.md:133` defines "Can I buy?" inputs as income + commitments + current spend + days-to-salary + active goals. Checked what actually exists: income is a single loosely-tagged row in `transactions` (usable but fragile), commitments has **no capture mechanism anywhere** — Cold Start (CHAT-07) asks the user for `monthly_commitments` and computes an insight ratio with it, then discards the value without saving it, and no commitments-tracking task existed anywhere in the original backlog despite the PRD listing it as a Tier 1 feature. Active goals depend on GOAL-01 (Stage 4, not built). Building BUY-01→04 in Stage 3 as originally scheduled would ship a verdict engine silently missing 2 of 4 required inputs — the kind of gap that looks like a working feature until a judge or teammate tests the exact scenario it can't actually reason about. |
| **Alternatives** | (A) Build BUY-01 now with commitments/goals hardcoded to zero — rejected: produces a verdict engine that's systematically over-optimistic (always ignoring debt/goals), worse than not shipping it, especially since this is the product's core differentiator and a judge is likely to probe exactly this. (B) Leave BUY-01→04 in Stage 3 as originally scheduled and just accept the gap — rejected, same reasoning as (A). |
| **Impact** | `16_implementation_backlog.md`: Stage 3 is now OCR-only; Stage 4 gains COMMIT-01 (new task — commitments CRUD, seeded from the Cold Start estimate instead of re-asking the user) and BUY-01→04, resequenced so BUY-01 depends on COMMIT-01 + GOAL-01. SIM-01 already depended on BUY-01 in the original backlog, so this also fixes a latent same-stage ordering problem, not just a stage-boundary one. |
| **Related** | `01_prd.md:133`, `16_implementation_backlog.md §Stage 3, §Stage 4`, `05_data_model_erd.md` (commitments table, already deployed), `lib/features/chat/chat_screen.dart` (`_handleColdStartSubmit` — where the commitments value currently gets discarded) |

---

### DEC-018: Voice Input UX — Mic Button Added to Input Bar

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | Add a dedicated microphone button 🎤 to the input bar alongside the existing camera button 📷. Layout (RTL): `↑ │ text │ 🎤 📷`. Voice is the primary input method for Arabic users per PRD — it must be always visible, one-tap, no hidden gestures. |
| **Rationale** | PRD §Tier 1 Coach declares "Zero-friction tracking: Voice, OCR, chat — no manual entry" with voice listed FIRST. Arabic-speaking users overwhelmingly prefer voice over typing. DEC-016 already corrected the platform from iOS-only to cross-platform Android-first with `speech_to_text`. But the UX spec (`03_user_flows_navigation.md`) still showed the old camera-only input bar with no mic. Four options were evaluated: (A) replace camera with mic, (B) add mic as 4th element, (C) long-press on send, (D) toggle between camera/mic. Option B chosen because: voice deserves its own dedicated always-visible button (not hidden behind long-press or toggle), camera is also core to Tier 1 for receipt OCR and cannot be removed, and a 4-element bar is clean enough on modern phones. |
| **Alternatives** | (A) Replace camera with mic — rejected: camera/OCR is also a core Tier 1 feature. (C) Long-press on send ↑ — rejected: not discoverable for non-tech-savvy Arabic users. (D) Toggle between 📷 and 🎤 — rejected: adds extra tap friction, contradicts "zero-friction" principle. |
| **Impact** | `03_user_flows_navigation.md` input bar section updated. CHAT-01 (Build Chat UI) must implement this 4-element layout. CHAT-04 (voice input) now has a defined trigger point. |
| **Related** | `03_user_flows_navigation.md`, `16_implementation_backlog.md §CHAT-01, CHAT-04`, `DEC-016` |

---

### DEC-012: Hala Joins Team as Presentations & Forms Lead

| Field | Value |
|-------|-------|
| **Date** | 2026-06-29 |
| **Status** | ✅ Closed |
| **Summary** | Hala joins as 4th team member, responsible for AMAD form completion and presentation preparation. |
| **Rationale** | The AMAD form (14-page PDF) requires dedicated effort. Separating presentation/form work from technical design allows specialists to focus. |
| **Impact** | Team now 4 members. `HALA_GUIDE.md` created (21KB) with form field answers mapped to spec files. `assets/AZDAL_AMAD_2026_FORM.pdf` added. All team files updated. |
| **Related** | `HALA_GUIDE.md`, `assets/AZDAL_AMAD_2026_FORM.pdf`, `00_project_context.md` |

---

### DEC-011: Preliminary Acceptance Received

| Field | Value |
|-------|-------|
| **Date** | 2026-06-28 |
| **Status** | ✅ Closed |
| **Summary** | AMAD hackathon preliminary acceptance received. Project advances to build phase. |
| **Rationale** | Registration completed before June 1. Track confirmed: Financial Education. Team of 3 locked. |
| **Impact** | 17-day countdown begins. Specification review phase (3 days) → Finalize (3 days) → Build sprint (~9 days) → Travel → Hackathon. |
| **Related** | `00_project_context.md`, `docs/business/hackathon-strategy.md` |

---

### DEC-001: 3-Tier System Architecture

| Field | Value |
|-------|-------|
| **Date** | 2026-05-21 |
| **Status** | ✅ Closed |
| **Summary** | Adopt 3-tier system: Coach → Smart Lender → Wealth Builder |
| **Rationale** | Each tier feeds the next. Solves sustainability (revenue path) and product cohesion (one journey). Avoids being "just a tracking app." |
| **Alternatives** | (A) Coach-only — rejected: no revenue path, judges said "no solution." (B) Lender-only — rejected: needs SAMA license before MVP, no user base. |
| **Impact** | Defines entire product architecture, monetization strategy, and hackathon MVP scope. |
| **Related** | `00_product_discovery.md`, `01_prd.md`, `02_monetization_entitlements.md` |

---

### DEC-002: Track Selection — Financial Education

| Field | Value |
|-------|-------|
| **Date** | 2026-05-21 |
| **Status** | ✅ Closed |
| **Summary** | Hackathon track: Financial Education (التعليم المالي) |
| **Rationale** | Core product is educational (AI coach teaches awareness). "Can I buy?" is a teaching moment. Better fit than Generative AI for FinTech — judges value behavioral science + user transformation. Saja pushed based on past finals experience. |
| **Alternatives** | (A) Generative AI for FinTech — rejected: less fit, more competition. |
| **Impact** | Shapes pitch, demo narrative, judge Q&A preparation. |
| **Related** | `docs/business/hackathon-strategy.md` |

---

### DEC-003: Hybrid Architecture

| Field | Value |
|-------|-------|
| **Date** | 2026-05-16 |
| **Status** | ✅ Closed |
| **Summary** | LLM understands and routes — SQL calculates, GenUI displays |
| **Rationale** | LLMs hallucinate math. Financial calculations must be deterministic. Multi-agent unanimous validation. |
| **Alternatives** | (A) Full LLM — rejected: hallucination risk in finance is unacceptable. (B) No LLM — rejected: can't handle Arabic NLP without AI. |
| **Impact** | Defines the fundamental architecture constraint for all implementation. |
| **Related** | `07_flutter_architecture.md`, `00_lessons_learned.md §LL-006` |

---

### DEC-004: Phased Revenue Model

| Field | Value |
|-------|-------|
| **Date** | 2026-05-21 |
| **Status** | ✅ Closed |
| **Summary** | Phase 1 free (growth), Phase 2 B2B behavioral credit scoring (revenue), Phase 3 lending (margins), Phase 4 investment referrals (commissions) |
| **Rationale** | Avoids needing SAMA license for MVP. Builds user base and behavioral data before monetizing. B2B credit scoring leverages data without lending. |
| **Alternatives** | (A) Premium subscription — rejected: limits growth, wrong for financial education. (B) Lending from day 1 — rejected: needs SAMA license. |
| **Impact** | Defines monetization strategy and license timeline. |
| **Related** | `02_monetization_entitlements.md`, `19_financial_model_unit_economics.md` |

---

### DEC-005: Hackathon MVP Scope Lock

| Field | Value |
|-------|-------|
| **Date** | 2026-05-21 |
| **Status** | ✅ Closed |
| **Summary** | Build ONLY Tier 1 Coach. Tier 2 gateway simulated. Tier 3 = vision slides. |
| **Rationale** | Judges penalize scattered solutions. Sharp + working > broad + shallow. Saja's intel: past teams failed because they tried too much. |
| **Alternatives** | (A) Full 3 tiers — rejected: impossible in 4 weeks, diluted impact. |
| **Impact** | Defines build plan and demo strategy. |
| **Related** | `01_prd.md`, `16_implementation_backlog.md` |

---

### DEC-006: Chat UI as Sole Screen

| Field | Value |
|-------|-------|
| **Date** | 2026-05-20 |
| **Status** | ✅ Closed |
| **Summary** | Single chat screen. All features are widgets inline. No navigation. No tab bars. |
| **Rationale** | Zero navigation = zero friction. Matches conversational AI form factor. Widget catalog provides feature richness without screen complexity. |
| **Alternatives** | (A) Multi-screen app with chat as one tab — rejected: adds navigation complexity, reduces immersion. |
| **Impact** | Defines all UI architecture and widget catalog design. |
| **Related** | `03_user_flows_navigation.md`, `04_ui_design_system.md` |

---

### DEC-007: Visual Identity Lock

| Field | Value |
|-------|-------|
| **Date** | 2026-05-20 |
| **Status** | ✅ Closed |
| **Summary** | Dark mode only. Cairo font. Western numerals. Navy #001F5E + Cyan #32C2FF. |
| **Rationale** | Dark mode = premium fintech feel. Cairo = best Arabic font on mobile. Western numerals = Saudi convention. Navy/Cyan = trust + intelligence. |
| **Alternatives** | (A) Light mode — rejected: fintech apps are dark. (B) Eastern Arabic numerals — rejected: not Saudi convention. |
| **Impact** | Defines all visual design decisions. |
| **Related** | `04_ui_design_system.md`, `docs/design/visual-identity.md` |

---

### DEC-008: Technology Stack Selection

| Field | Value |
|-------|-------|
| **Date** | 2026-05-19 |
| **Status** | ✅ Closed |
| **Summary** | Flutter + Gemini Flash + Supabase + Riverpod + Isar local cache |
| **Rationale** | Flutter = single codebase iOS/Android. Gemini = best Arabic LLM. Supabase = free tier + PostgreSQL. Riverpod = compile-safe state. Isar = offline support. |
| **Alternatives** | (A) React Native — rejected: Flutter better Arabic/RTL, superior performance. (B) Firebase — rejected: Supabase has PostgreSQL, better SQL support. (C) GPT-4o — rejected: Gemini superior Arabic NLP. |
| **Impact** | Defines entire development stack. |
| **Related** | `07_flutter_architecture.md` |

---

### DEC-009: Hybrid Verification Architecture

| Field | Value |
|-------|-------|
| **Date** | 2026-05-21 |
| **Status** | ✅ Closed |
| **Summary** | Behavioral credit scoring requires: Open Banking ground truth + AI enrichment + Integrity cross-validation |
| **Rationale** | Goodhart's Law: "When a measure becomes a target, it ceases to be a good measure." Users will game the system if they know data entry = credit access. Ground truth layer prevents gaming. |
| **Alternatives** | (A) Self-reported only — rejected: easily gamed. (B) Bank data only — rejected: loses granularity (bank sees "Carrefour 350", Azdal sees line items). |
| **Impact** | Defines the anti-gaming architecture for B2B credit scoring. |
| **Related** | `07_flutter_architecture.md §6`, `00_lessons_learned.md §LL-005` |

---

### DEC-010: Anti-Ghost Protocol Adoption

| Field | Value |
|-------|-------|
| **Date** | 2026-06-29 |
| **Status** | ✅ Closed |
| **Summary** | No physical deletion. isDeleted=true, deletedAt=timestamp. Follows Flutter Operation Global Contract Rule 4. |
| **Rationale** | Standard across all Flutter projects. Audit trail integrity. Regulatory compliance (PDPL right to correction, not deletion of financial records). |
| **Impact** | Applies to all database tables. |
| **Related** | `05_data_model_erd.md`, `08_security_privacy.md` |

---

### DEC-013: Visual Identity Amendment — Logo & Theme

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed — supersedes part of DEC-007 |
| **Summary** | Logo changed from Solomon's Seal (🜔) to a shield + upward bar-chart icon. Theme changed from dark-mode-only to light mode. Cairo font, Western numerals, Navy #001F5E + Cyan #32C2FF unchanged from DEC-007. |
| **Rationale** | Both the actual production logo asset and the AMAD demo deck screenshots (Visily mockups) had already diverged from the original spec — shield+chart icon in use, light-theme screens throughout. Resolved via the team's open-questions review (7 items in `FEEDBACK.md`) by updating the spec to match what was actually built rather than rebuilding assets to match a stale spec, given ~4 days to AMAD. |
| **Alternatives** | (A) Revert logo to Solomon's Seal and rebuild mockups in dark mode — rejected: no time, and light mode already reads fine in the existing demo screens. |
| **Impact** | `04_ui_design_system.md` (color palette + layout rule), `docs/design/visual-identity.md` (logo section) updated to match. Any future dark-mode work is a post-hackathon nice-to-have, not MVP scope. |
| **Related** | `04_ui_design_system.md`, `docs/design/visual-identity.md`, `FEEDBACK.md` |

---

### DEC-016: Voice/TTS Platform Corrected — iOS-Only → Cross-Platform Android-First

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | Voice input and TTS specs corrected from iOS-only Apple frameworks (`Apple Speech`, `AVSpeechSynthesizer`) to cross-platform packages (`speech_to_text`, `flutter_tts`). Azdal is Android-only — the previous specs referenced APIs not accessible on the target platform. |
| **Rationale** | `07_flutter_architecture.md` §1, §2, and §3 all specified Apple Speech and AVSpeechSynthesizer — iOS/macOS on-device frameworks with no Android equivalent. `speech_to_text` wraps Android's native `SpeechRecognizer` (same on-device privacy properties) and provides an identical Dart API if iOS is ever added. `flutter_tts` is the standard cross-platform TTS package. Both are now pre-approved in `00_project_overrides.md` per Global Contract Rule 7. |
| **Alternatives** | (A) Keep Apple-only specs and add conditional platform channels — rejected: unnecessary complexity for a platform the app doesn't target. (B) `record` + cloud STT — rejected: adds latency and network dependency for basic voice input. |
| **Impact** | `07_flutter_architecture.md` §1 table, §2 layer diagram, and §3 stack block updated. `00_project_overrides.md` package exceptions table updated. No code changes — voice input is Stage 3 scope. |
| **Related** | `07_flutter_architecture.md`, `00_project_overrides.md`, `01_prd.md §194` |

---

### DEC-015: Isar Local Storage Deferred (Post-Hackathon)

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | Isar (`^3.1.0`) + `isar_flutter_libs` (`^3.1.0`) removed from `pubspec.yaml` (commented out, not deleted). No production code depends on Isar — zero functional impact. |
| **Rationale** | Isar was re-enabled in pubspec.yaml earlier today (Stage-1 rework). Release builds (`flutter build apk --release`) failed with `AAPT: error: resource android:attr/lStar not found` during `isar_flutter_libs:verifyReleaseResources`. The working fix (patching `namespace` into `~/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle`) is a local-only hack — not reproducible on any other machine or CI runner. Isar 3.1.0 targets AGP 4.2; Azdal targets AGP 8.8. The AGP compatibility gap is the root cause. |
| **Alternatives** | (A) Fork Isar and port to AGP 8+ — rejected: too large for hackathon timeline, and no code needs it yet. (B) `hive_ce` — considered but not evaluated; Isar's query performance was the original draw. (C) `drift` (SQLite) — also valid; evaluate alongside Isar fork when local caching is actually needed. |
| **Impact** | `path_provider` stays (no AGP issues). When Stage 2 reaches a point that actually needs local caching (offline receipt storage, draft persistence), the task will explicitly evaluate either a maintained AGP 8-compatible Isar fork or an alternative (`drift`, `hive_ce`) — instead of patching the pub cache again. |
| **Related** | `pubspec.yaml`, `07_flutter_architecture.md` |

---

### DEC-014: Gemini API Key Shipped Client-Side (Hackathon MVP)
| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed — accepted risk for hackathon |
| **Summary** | The Gemini API key is compiled into the APK via `--dart-define-from-file=.env`. Any client-side key is extractable by reverse-engineering the APK. This is a known, accepted risk for the hackathon MVP. |
| **Rationale** | Building a backend proxy (Supabase Edge Function) to mediate all Gemini calls is the proper long-term fix, but it adds latency, a new failure domain, and ~4h of work that the hackathon timeline cannot absorb. The key is a free-tier key with low quota — abuse surface is minimal. |
| **Alternatives** | (A) Backend proxy now — rejected: too large for hackathon timeline. (B) Hardcode the key — rejected: `--dart-define-from-file` at least keeps it out of version control. |
| **Impact** | The key will be rotated post-hackathon. A Supabase Edge Function proxy task is added to the post-MVP backlog. This decision is tracked so it doesn't become a silent production gap. |
| **Related** | `07_flutter_architecture.md §9`, `16_implementation_backlog.md`, `scripts/build_debug.sh` |

---

### DEC-017: Guest-First RLS Resolution — Anonymous Auth

| Field | Value |
|-------|-------|
| **Date** | 2026-07-12 |
| **Status** | ✅ Closed |
| **Summary** | Resolve the RLS guest-write deadlock by enabling **Supabase Anonymous Sign-In** (`signInAnonymously`). The app calls `supabase.auth.signInAnonymously()` on first launch — Supabase creates a real `auth.users` row with `is_anonymous: true`. This gives every guest user a real UUID-backed JWT, so `auth.uid()` returns a valid value and all 14 existing RLS policies (`auth.uid() = user_id`) work unchanged. No DDL changes, no new columns, no RLS policy modifications needed. |
| **Rationale** | **The Problem:** All 5 tables (transactions, commitments, goals, integrity_scores, purchase_decisions) have FK `user_id REFERENCES auth.users(id)` and RLS policies using `auth.uid() = user_id`. For unauthenticated users, `auth.uid()` returns NULL — blocking ALL writes. **Why not alternatives:** (A) Drop FK + add anon RLS policies with device-generated UUID — breaks referential integrity, requires ALTER on all 5 tables, and creates two code paths (auth vs guest) forever. (B) Edge Function with `service_role` bypass — bypasses RLS entirely, loses per-user data isolation, adds server-side complexity and latency for every write. (C) Add `guest_id` column + modify RLS — same complexity as (A) with worse data model. **Why anonymous auth wins:** Zero DDL changes (no ALTER TABLE risk on deployed data), all FK constraints remain valid, all 14 RLS policies work as-is, clean upgrade path (`linkIdentity()` converts anonymous → email/phone for Tier 2 lending), transparent UX (no form, no registration — just open app and use it). This is the Supabase-recommended pattern for guest-first apps. |
| **Alternatives** | (A) Drop FK to auth.users + anon RLS policies with client-generated UUID — rejected: schema changes on already-deployed tables, breaks referential integrity, creates dual code paths. (B) Edge Function with service_role — rejected: loses per-user isolation, adds server-side complexity, overkill for MVP writes. (C) Shared guest user_id — rejected: no data isolation, all guests share one row namespace. |
| **Impact** | **Database (zero changes):** No DDL, no RLS policy changes needed. All 5 tables and 14 policies work as-is. **Supabase dashboard:** Enable "Anonymous Sign-ins" in Authentication → Providers. **Flutter app:** Add `supabase.auth.signInAnonymously()` call on first launch (when `currentSession == null`). Session persists on-device — guest data survives app restarts. **Security:** Anonymous users get real JWT tokens with `is_anonymous: true` claim. Data is isolated per anonymous user. Accepted risk for MVP: anonymous users can't recover data if they clear app data (no email/password to sign back in). This is acceptable per PRD hackathon exceptions: "No real PII collected — demo data only." **Upgrade path:** When Tier 2 requires real identity (`linkIdentity()` or `signUp()`), existing anonymous data is preserved under the same `user_id`. |
| **Related** | `08_security_privacy.md`, `INIT-03_supabase_schema.md`, `01_prd.md §68-74` (Phase 0: no registration), `05_data_model_erd.md` |

---

## Decision Summary

| ID | Decision | Date | Status |
|----|----------|------|--------|
| DEC-021 | Auto-save simple transactions — drop confirm tap | 2026-07-13 | ✅ |
| DEC-022 | Bounded Reply Pattern (BRP) — mandatory for all LLM text | 2026-07-13 | ✅ |
| DEC-020 | Cancel-before-confirm (compound split) + transaction undo | 2026-07-12 | ✅ |
| DEC-019 | "Can I buy?" (BUY-01→04) moved from Stage 3 to Stage 4 | 2026-07-12 | ✅ |
| DEC-018 | Voice input UX — mic button added to input bar | 2026-07-12 | ✅ |
| DEC-017 | Guest-first RLS resolution — Supabase Anonymous Sign-In | 2026-07-12 | ✅ |
| DEC-016 | Voice/TTS platform corrected — iOS-only → cross-platform Android-first | 2026-07-12 | ✅ |
| DEC-015 | Isar local storage deferred (post-hackathon) | 2026-07-12 | ✅ |
| DEC-014 | Gemini API key shipped client-side (hackathon MVP accepted risk) | 2026-07-12 | ✅ |
| DEC-013 | Visual identity amendment — shield+chart logo, light mode | 2026-07-12 | ✅ |
| DEC-012 | Hala joins team (Presentations & Forms) | 2026-06-29 | ✅ |
| DEC-011 | Preliminary acceptance received | 2026-06-28 | ✅ |
| DEC-001 | 3-tier system | 2026-05-21 | ✅ |
| DEC-002 | Financial Education track | 2026-05-21 | ✅ |
| DEC-003 | Hybrid architecture | 2026-05-16 | ✅ |
| DEC-004 | Phased revenue model | 2026-05-21 | ✅ |
| DEC-005 | MVP scope lock | 2026-05-21 | ✅ |
| DEC-006 | Chat UI sole screen | 2026-05-20 | ✅ |
| DEC-007 | Visual identity lock | 2026-05-20 | ✅ |
| DEC-008 | Tech stack selection | 2026-05-19 | ✅ |
| DEC-009 | Hybrid verification | 2026-05-21 | ✅ |
| DEC-010 | Anti-ghost protocol | 2026-06-29 | ✅ |

---

## Related
- `00_lessons_learned.md` — Lesson log with LL references
- `13_assumptions_risks.md` — Risk register
