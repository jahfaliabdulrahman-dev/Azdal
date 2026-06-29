# Azdal — Project Context

> **Type:** Project-specific  
> **Status:** 🟢 Stage 0 — Planning (Accepted to AMAD Hackathon)  
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
| Event | **AMAD Hackathon** |
| Track | Financial Education (التعليم المالي) |
| Dates | July 16-18, 2026 |
| Location | Riyadh (mandatory attendance) |
| Registration | ✅ **Completed** (before June 1 deadline) |
| Acceptance | ✅ **Preliminary acceptance received — June 28, 2026** |
| Days remaining | **~17 days** (June 29 → July 16) |
| Current phase | Team review & feedback (Stage 0) |
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

## Key Timeline (Updated — June 29)

| Date | Milestone | Status |
|------|-----------|--------|
| ~May 2026 | Registration submitted | ✅ Completed |
| **June 28, 2026** | **Preliminary acceptance received** | ✅ **Received** |
| **June 29 → July 2** | Team review of spec pack | 🔄 In progress |
| July 3-5 | Apply feedback, finalize specs | ⬜ Pending |
| July 5-14 | Implementation sprint (~9 days) | ⬜ Pending |
| July 14-15 | Travel to Riyadh | ⬜ Pending |
| **July 16-18** | **HACKATHON** | ⬜ Pending |

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
- `REVIEW_GUIDE.md` — Current review process
- `FEEDBACK.md` — Team feedback tracker
