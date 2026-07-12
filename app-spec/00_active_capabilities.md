# Azdal — Active Capabilities

> **Status:** 🟢 Stage 2 complete, device-verified — Stage 3 (OCR) starting  
> **Last Updated:** 2026-07-12

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
| Stage 3 — OCR | Not yet started | `CAMERA` permission not declared, no Supabase Storage bucket exists yet — both needed before OCR-01/03 |

---

### ⬜ NOT STARTED

| Capability | Required For Stage | Notes |
|------------|-------------------|-------|
| Camera/gallery + share sheet | Stage 3 | `image_picker` + `receive_sharing_intent`, OCR-01/02 |
| Gemini Vision OCR | Stage 3 | Verify the vision API call works before building the pipeline on top of it — never exercised yet |
| Supabase Storage bucket | Stage 3 | Zero buckets currently exist; required for receipt images per `08_security_privacy.md` |
| Commitments tracking (CRUD) | Stage 4 | No task existed for this anywhere until DEC-019 — PRD lists it as Tier 1 but it was never scheduled. Must seed from the Cold Start estimate, not re-ask |
| Goals + gap detection | Stage 4 | `goals` table deployed, empty — no CRUD yet |
| Integrity Score tracker | Stage 4 | Moved here from an earlier "Stage 3" label — see `16_implementation_backlog.md` |
| "Can I buy?" engine | Stage 4 (moved from Stage 3, DEC-019) | Needs commitments + goals data — didn't exist when originally scheduled |
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
