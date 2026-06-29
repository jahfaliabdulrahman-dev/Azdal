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
| Location | Riyadh, Saudi Arabia |
| Status | 🟡 **Stage 0 — Pre-Code Planning** |

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

## Project Structure

```
Azdal/
├── app-spec/           ← ALL specification files (source of truth — 25 files)
├── docs/               ← Reference materials
│   ├── business/       ← SWOT, PESTLE, Porter's, BMC, etc.
│   ├── research/       ← Financial Knowledge Layer (23 academic refs)
│   ├── design/         ← UI screens, visual identity
│   └── archive/        ← Historical brainstorming, agent critiques
├── assets/branding/    ← Logo, app icons
├── lib/                ← Flutter source (EMPTY — pre-code)
├── test/               ← Tests (EMPTY — pre-code)
└── README.md           ← You are here
```

---

## Quick Start — Navigate the Spec Pack

| Start Here | If You Want |
|-----------|-------------|
| [`app-spec/00_product_discovery.md`](app-spec/00_product_discovery.md) | The vision, problem, solution, and competitive moat |
| [`app-spec/01_prd.md`](app-spec/01_prd.md) | Complete product requirements and behaviors |
| [`app-spec/07_flutter_architecture.md`](app-spec/07_flutter_architecture.md) | Technical architecture and stack |
| [`app-spec/12_decision_log.md`](app-spec/12_decision_log.md) | All architecture decisions (DEC-001–010) |
| [`app-spec/16_implementation_backlog.md`](app-spec/16_implementation_backlog.md) | Build plan and task breakdown |

---

### For Non-Technical Team Members

- 📊 **Business strategy:** [`docs/business/`](docs/business/) — SWOT, PESTLE, BMC, Pitch Deck
- 🧠 **Behavioral foundation:** [`docs/research/financial-knowledge-layer.md`](docs/research/financial-knowledge-layer.md) — 23 academic references
- 🎨 **Design:** [`docs/design/`](docs/design/) — UI prototypes, visual identity guide
- 🎤 **Pitch preparation:** [`docs/business/pitch-deck.md`](docs/business/pitch-deck.md) — 9-slide investor pitch

---

## Tech Stack (Planned)

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Dart) — Material 3, RTL, Dark Mode |
| State | Riverpod |
| AI | Gemini 2.5 Flash + Pro + Vision |
| Backend | Supabase (PostgreSQL) |
| Local Cache | Isar |
| Dynamic UI | GenUI / A2UI |

---

## Rules

1. **No code before specification** — all 25 spec files exist before first `flutter create`
2. **app-spec is the source of truth** — docs/ are reference only
3. **No hard delete** — isDeleted flag (anti-ghost protocol)
4. **Backend validates entitlements** — client is UX-only
5. **Traceability mandatory** — every feature → spec files → test cases

---

## License & Regulatory

- **Phase 1 (Coach):** No license required — educational tool
- **Phase 2 (B2B Insights):** No license — anonymized behavioral scores
- **Phase 3 (Smart Lender):** SAMA Consumer Finance License required
- **Privacy:** PDPL-compliant. Guest-first. On-device default.
