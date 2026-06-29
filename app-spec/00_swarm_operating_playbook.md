# Azdal — Swarm Operating Playbook

> **Purpose:** How the 8 Hermes agent profiles operate for the Azdal project.  
> **Status:** Template — populated when swarm is activated (Stage 1+).  
> **Last Updated:** 2026-06-29

---

## Profile Assignments

| # | Profile | Emoji | Azdal Role | Status |
|---|---------|-------|------------|--------|
| 1 | flutter-lead-architect | 🜔 | Orchestration, approvals, conflict resolution | Active (Stage 0) |
| 2 | flutter-product-steward | 📋 | PRD, user stories, scope, MVP boundaries | Standby |
| 3 | flutter-ui-ux-designer | 🎨 | Screens, flows, design tokens, widget catalog | Standby |
| 4 | flutter-backend-db-architect | 🗄️ | ERD, OpenAPI, ACID, authorization | Standby |
| 5 | flutter-state-engineer | 💻 | Flutter code, state management, widgets, API integration | Standby |
| 6 | flutter-qa-tester | 🧪 | Test coverage, acceptance, regression | Standby |
| 7 | flutter-zero-trust-auditor | 🔴 | Hostile audit, Black Swan, attack vectors | Standby |
| 8 | flutter-devops-release-engineer | 🚀 | CI/CD, secrets, build flavors, release gates | Standby |

---

## Human Team (4 Members)

| # | Name | Role | Linked Agents |
|---|------|------|--------------|
| 1 | Abdulrahman Jahfali | AI / Backend / Flutter | Lead Architect, State Engineer |
| 2 | Saja | Business / SWOT / Pitch | Product Steward |
| 3 | Deema | UI / UX Design | UI/UX Designer |
| 4 | Hala | Presentations & AMAD Form | QA Tester (presentation review) |

**Note:** Hermes agents (#1-8 above) are AI profiles that execute technical work. Human members review agent outputs, provide strategy, and prepare presentations.

---

## Stage 0 (Planning) — Active Profiles

Only the Lead Architect is active during Stage 0:
- Create and maintain spec pack
- Route lessons to `00_lessons_learned.md`
- Maintain Decision Log and Traceability Matrix
- Activate Kanban for Stage 0 cards

---

## Stage Activation Plan

| Stage | Profiles Activated | Trigger |
|-------|-------------------|---------|
| Stage 1 — Project Init | Lead Architect + DevOps | All spec files approved |
| Stage 2 — Chat + Transaction | Architect + State Engineer + Product Steward | Flutter project scaffolded |
| Stage 3 — OCR + "Can I Buy?" | Architect + State Engineer + QA Tester | Chat core working |
| Stage 4 — Goals + Simulation | Architect + State Engineer + QA Tester | Purchase engine working |
| Stage 5 — Polish + Audit | All 8 profiles | All features implemented |
| Stage 6 — Release | Architect + DevOps + Auditor | QA passed |

---

## Communication Protocol

- **Spec changes:** Route through Lead Architect only
- **Implementation questions:** State Engineer → Architect escalation
- **Design questions:** UI/UX Designer → Product Steward → Architect
- **Security concerns:** Zero Trust Auditor → Architect (direct)
- **Release decisions:** DevOps → Architect (final approval)

---

## Related
- Flutter Operation Global Contract (Loaded in all profile SOUL files)
- `00_project_overrides.md` — Azdal-specific rules
