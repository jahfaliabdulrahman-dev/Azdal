# 🜔 Azdal — درعك المالي

> **المستخدم يدخل مديونًا — ويخرج مستثمرًا.**
> *You enter in debt. You exit as an investor.*

---

## What Is Azdal?

Azdal is the **first Arabic 3-tier financial rehabilitation program**. We transform debt-trapped consumers into conscious investors through AI, behavioral science, and a proven progression system.

We are **not** a budgeting app. We are **not** a BNPL clone. We are a **financial transformation platform**.

---

## Hackathon Context

| Field | Value |
|-------|-------|
| Event | **AMAD Hackathon** |
| Track | Financial Education (التعليم المالي) |
| Dates | July 16–18, 2026 |
| Format | Online |
| Status | 🟢 **Stage 4 complete + investor-facing demo shell — ready for AMAD** |

---

## Team

| # | Role | Name |
|---|------|------|
| 1 | AI / Backend / Flutter | **Abdulrahman Jahfali** |
| 2 | Business Model / SWOT / Pitch | **Saja** |
| 3 | UI / UX Design | **Deema** |
| 4 | Presentations & Forms | **Hala** |

---

## The Three Tiers

```
COACH (المستشار)  →  SMART LENDER (المُقرِض الواعي)  →  WEALTH BUILDER (باني الثروة)
   Free                   SAMA License Required                Partnerships
```

---

## What's Built

The Coach tier (Tier 1) is real and functional end-to-end — real Supabase-backed chat, transactions, commitments, goals, and purchase-affordability decisions. The Lender and Wealth Builder tiers are represented in the app as an investor-facing vision layer (mock content, clearly a preview, not wired to real backends) so the full 3-tier story is demonstrable in one build.

| App area | What it does |
|---|---|
| **المحادثة (Chat)** | Natural-language expense logging, voice input, receipt photo OCR, remaining-budget queries, commitments/goals tracking, "can I afford this?" purchase decisions (DTI-aware) |
| **حسابي (Account)** | Guest → real account upgrade (same data, zero migration), bank-linking flow (mock), "start as new guest" reset for demo/testing |
| **خطتك نحو الاستثمار (Journey)** | The 3-tier vision made tangible — mock net-worth projection, unlock requirements tied to real app concepts (DTI, integrity score) |
| **الدورات (Courses)** | Financial education content (mock, preview) |

Auth is **anonymous-first** (DEC-017): every guest gets a real Supabase user with full data persistence from message one — no signup wall. Creating a real account later upgrades the same identity in place; nothing is lost.

See [`app-spec/00_active_capabilities.md`](app-spec/00_active_capabilities.md) for the authoritative, up-to-date capability list, and [`app-spec/12_decision_log.md`](app-spec/12_decision_log.md) for every architecture/product decision with full rationale.

---

## Project Structure

```
Azdal/
├── app-spec/           ← Specification + decision log (source of truth — 30 files)
├── docs/               ← Reference materials
│   ├── business/       ← SWOT, PESTLE, Porter's, BMC, pitch deck
│   ├── research/       ← Financial Knowledge Layer (23 academic refs)
│   ├── design/         ← Visual identity, design system
│   └── archive/        ← Historical brainstorming, stage handoffs, superseded analysis
├── assets/branding/    ← Logo, brand assets
├── lib/                ← Flutter source
│   ├── app/            ← Router, theme, brand tokens, providers
│   ├── core/services/  ← Gemini AI service
│   └── features/
│   │   ├── chat/        ← Core coach chat (screen, providers, services, widget catalog)
│   │   ├── auth/        ← Signup/login, anonymous-upgrade service
│   │   ├── account/      ← Account tab (identity, bank-link entry, reset-to-guest)
│   │   ├── launch/       ← Splash + onboarding
│   │   ├── shell/        ← Bottom-nav tab shell (IndexedStack)
│   │   ├── bank/         ← Mock bank-linking flow
│   │   ├── courses/      ← Mock courses tab
│   │   └── journey/      ← Investment-journey vision screen
├── test/               ← Unit/widget tests
├── supabase/           ← Schema/migrations reference
└── README.md           ← You are here
```

---

## Getting Started

```bash
flutter pub get

# Copy the template and fill in your own Supabase + Gemini credentials
cp .env.template .env

# Run on a connected device/emulator
flutter run --dart-define-from-file=.env

# Build a debug APK
flutter build apk --debug --dart-define-from-file=.env
```

Credentials are compile-time constants (`--dart-define-from-file=.env`), **not** read from the OS environment — this matters on Android, where `Platform.environment` doesn't see your shell's variables.

---

## Quick Start — Navigate the Spec Pack

| Start Here | If You Want |
|-----------|-------------|
| [`app-spec/00_active_capabilities.md`](app-spec/00_active_capabilities.md) | The live, accurate status of every feature |
| [`app-spec/00_product_discovery.md`](app-spec/00_product_discovery.md) | The vision, problem, solution, and competitive moat |
| [`app-spec/01_prd.md`](app-spec/01_prd.md) | Complete product requirements and behaviors |
| [`app-spec/07_flutter_architecture.md`](app-spec/07_flutter_architecture.md) | Technical architecture and stack |
| [`app-spec/12_decision_log.md`](app-spec/12_decision_log.md) | Every architecture/product decision, with rationale (DEC-001 → DEC-047+) |
| [`app-spec/16_implementation_backlog.md`](app-spec/16_implementation_backlog.md) | Build plan and task breakdown |

---

### For Non-Technical Team Members

- 📊 **Business strategy:** [`docs/business/`](docs/business/) — SWOT, PESTLE, BMC, Pitch Deck
- 🧠 **Behavioral foundation:** [`docs/research/financial-knowledge-layer.md`](docs/research/financial-knowledge-layer.md) — 23 academic references
- 🎨 **Design:** [`docs/design/`](docs/design/) — visual identity guide, design system
- 🎤 **Pitch preparation:** [`docs/business/pitch-deck.md`](docs/business/pitch-deck.md) — investor pitch

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — Material 3, RTL (real localization, not a manual wrapper), **light mode only** |
| State | Riverpod |
| Routing | go_router |
| AI | Gemini (Flash + Pro + Vision) |
| Backend | Supabase (PostgreSQL, Row-Level Security, Anonymous Auth) |
| Voice | `speech_to_text` (cross-platform, Android-first) |
| Local Cache | None yet — Isar deferred post-hackathon (DEC-015) |

---

## Rules

1. **app-spec is the source of truth** — docs/ are reference only
2. **No hard delete on app data** — `is_deleted`/`deleted_at` flags (anti-ghost protocol); this is a data-model rule, unrelated to repo file housekeeping
3. **Backend validates entitlements** — client is UX-only
4. **Traceability mandatory** — every feature → spec files → decision log entry
5. **All financial math is pure Dart** — no LLM arithmetic, no Edge Functions for calculations (DEC-024)

---

## License & Regulatory

- **Phase 1 (Coach):** No license required — educational tool
- **Phase 2 (B2B Insights):** No license — anonymized behavioral scores
- **Phase 3 (Smart Lender):** SAMA Consumer Finance License required
- **Privacy:** PDPL-compliant. Guest-first. Anonymous by default, real identity opt-in only.
