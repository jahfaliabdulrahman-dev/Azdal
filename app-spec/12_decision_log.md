# Azdal — Decision Log

> **Purpose:** Formal record of ALL architecture and product decisions.  
> **Status:** Populated from historical brainstorming (DEC-001 through DEC-010)  
> **Rule:** Every decision requires: ID, date, summary, rationale, alternatives considered, and impact.

---

## Open Decisions

None at Stage 0. All Stage 0 decisions below are closed.

---

## Closed Decisions

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

## Decision Summary

| ID | Decision | Date | Status |
|----|----------|------|--------|
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
