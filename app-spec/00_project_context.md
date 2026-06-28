# Azdal — Project Context

> **Type:** Project-specific  
> **Status:** Stage 0 — Planning  
> **Last Updated:** 2026-06-29

---

## Project Identity

| Field | Value |
|-------|-------|
| Project Name | Azdal (أزدل) — درعك المالي |
| Type | Mobile App (Flutter) |
| Category | FinTech — Financial Education |
| Stage | Pre-code — Specification & Planning |
| Repository | `/Users/abdurrahmanjahfali/Azdal` |
| Language | Arabic-first (Saudi dialect), English technical |

---

## Hackathon Context

| Field | Value |
|-------|-------|
| Event | AMAD Hackathon |
| Track | Financial Education (التعليم المالي) |
| Dates | July 16-18, 2026 |
| Location | Riyadh (mandatory attendance) |
| Registration Deadline | June 1, 2026 |
| Type | FinTech / AI / Education |

---

## Team

| Role | Name | Responsibility |
|------|------|----------------|
| AI/Backend/Flutter | Abdulrahman Jahfali | Technical architecture, AI, Flutter app, demo |
| Business Model / SWOT / Pitch | Saja | Business case, market research, judge Q&A, revenue |
| UI/UX Design | Deema | Visual design, pitch deck aesthetics, UI screens |

**Saja's experience:** Previously reached AMAD finals with family finance app. Knows judges, winning patterns, and pitfalls.

---

## Key Deadlines

| Date | Milestone |
|------|-----------|
| June 1, 2026 | AMAD registration deadline |
| ~July 1 | Acceptance notifications |
| July 14-15 | Travel to Riyadh |
| July 16-18 | Hackathon days |

---

## Brand Identity

| Element | Value |
|---------|-------|
| Primary Color | Navy #001F5E (trust, authority) |
| Accent Color | Cyan #32C2FF (intelligence, clarity) |
| Font | Cairo (Google Fonts) — Arabic-optimized |
| Numerals | Western (1, 2, 3) |
| Direction | RTL |
| Mode | Dark mode only |
| Symbol | 🜔 Solomon's Seal |

---

## Project Structure (CarSah Model)

```
Azdal/
├── app-spec/           # All specification files (source of truth)
├── docs/               # Reference materials
│   ├── business/       # SWOT, PESTLE, Porter's, BMC, etc.
│   ├── research/       # Financial Knowledge Layer
│   ├── design/         # UI screens, visual identity
│   └── archive/        # Historical brainstorming, critiques
├── assets/branding/    # Logo, app icons
├── lib/                # Flutter source (empty — pre-code)
├── test/               # Tests (empty — pre-code)
├── android/            # Android platform (stub)
├── ios/                # iOS platform (stub)
├── .github/workflows/  # CI/CD (empty — pre-code)
├── .hermes/            # Swarm configuration
└── .taskmaster/        # Kanban state
```

---

## Rules & Constraints

1. **No code before specification** — all spec files must exist and be approved
2. **app-spec is source of truth** — docs/ are reference only
3. **Arabic-first** — user-facing content in Arabic, technical in English
4. **File names:** kebab-case English, never Arabic in paths
5. **No hard delete** — follow anti-ghost protocol
6. **Backend validates** — client is UX-only for entitlements
7. **Traceability mandatory** — every feature → spec files → test cases
8. **MVP scope locked** — Tier 1 Coach only for hackathon

---

## Related
- `00_product_discovery.md` — Full product vision
- `docs/business/hackathon-strategy.md` — Detailed hackathon plan
- `01_prd.md` — Product requirements
