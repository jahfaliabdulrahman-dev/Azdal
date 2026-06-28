# Azdal — Assumptions & Risks

> **Status:** Populated  
> **Source:** Synthesized from SWOT threats, Technical Architecture §9 risks, and Gemini Critique

---

## Key Assumptions

| ID | Assumption | Confidence | Validation |
|----|-----------|-----------|-----------|
| ASM-001 | Gemini Flash Arabic NLP is sufficient for Saudi dialect | HIGH | Validated — Gemini is best Arabic LLM |
| ASM-002 | SAMA Open Banking will be live by Year 2 | MEDIUM | Licensing started Mar 2026. SMS parsing as bridge. |
| ASM-003 | BNPL companies will pay for behavioral credit scores | MEDIUM | Validated — they have no salary assignment alternative |
| ASM-004 | Users will use voice input (not just text) | MEDIUM | Voice is the fastest input method. UX designed for it. |
| ASM-005 | 77% app abandonment stat applies to Saudi market | HIGH | Global + regional data consistent |
| ASM-006 | Guest-first (no registration) increases retention | HIGH | Consistent with behavioral UX research |
| ASM-007 | Single developer can build MVP in 4 weeks | MEDIUM | Scope locked to 8 features. Flutter single codebase. |
| ASM-008 | GenUI/A2UI will still be available and stable | LOW | Plan B: native Flutter widgets from same JSON schemas |
| ASM-009 | Hackathon judges value behavioral science | HIGH | Saja's finals experience confirms |
| ASM-010 | Dark mode is sufficient — no users demand light mode | HIGH | Fintech apps are dark. No competitor offers light mode. |

---

## Risk Register

| ID | Risk | Severity | Likelihood | Mitigation | Owner |
|----|------|----------|-----------|-----------|-------|
| RSK-001 | **LLM math hallucination** | CRITICAL | Medium | LLM NEVER calculates. SQL/Python for all math. | Architect |
| RSK-002 | **Goodhart's Law — user gaming** | HIGH | High | Hybrid verification: Open Banking ground truth + cross-validation | Architect |
| RSK-003 | **GenUI/A2UI beta failure** | HIGH | Medium | Fallback: native Flutter widgets from same JSON schemas | State Engineer |
| RSK-004 | **Cold start — no transaction history** | HIGH | Certain | Progressive Intelligence: never say "no data." Use brackets + estimates. | Product Steward |
| RSK-005 | **User retention — abandonment** | HIGH | High | Behavioral UX: Hook Model + Progress Principle + Silent Triage | UI/UX Designer |
| RSK-006 | **Gemini API cost at scale** | MEDIUM | Medium | Flash routing (80%) + DeepSeek fallback + B2B revenue covers cost | Architect |
| RSK-007 | **BNPL regulatory changes (SAMA)** | MEDIUM | Medium | Phase 1 = no license needed. Phase 2 = insights (not lending). | Product Steward |
| RSK-008 | **Open Banking delays in KSA** | MEDIUM | High | SMS parsing (Android) as bridge. Mock data for hackathon. | Architect |
| RSK-009 | **Copycat Saudi apps post-hackathon** | MEDIUM | Medium | Moat: Arabic NLP quality + hybrid architecture + "Can I buy?" engine. Hard to copy. | Product Steward |
| RSK-010 | **User trust — financial data fears** | MEDIUM | Medium | Guest-first (on-device default). Islamic branding. PDPL compliance. | Architect |
| RSK-011 | **Banks adding AI features** | LOW | Low | Banks are slow. Can't risk conversational UI. We have 1-2 year window. | Product Steward |
| RSK-012 | **Gemini API pricing changes** | LOW | Medium | Multi-model strategy. Not dependent on single vendor. | DevOps |
| RSK-013 | **Single developer bottleneck** | MEDIUM | Certain | Scope lock. 8 features only. Flutter = single codebase. | Architect |
| RSK-014 | **Hackathon demo failure** | HIGH | Low | Demo runbook + rehearsal + backup recorded video | Team |
| RSK-015 | **No academic financial advisor** | MEDIUM | Medium | In progress — searching. Adds credibility with judges. | Team |

---

## SWOT Summary (for reference)

| | POSITIVE | NEGATIVE |
|---|----------|----------|
| **INTERNAL** | Arabic AI, zero-friction, "Can I buy?", guest-first, hybrid arch, Gemini Arabic, domain expertise | No Open Banking, solo dev, GenUI beta, cost at scale, 1 month |
| **EXTERNAL** | $2.7B Saudi FinTech, no Arabic competitor, SAMA 2026, BNPL boom, 70% abandonment | Banks adding AI, Cleo expansion, PDPL, App Store policy, copycats |

---

## Related
- `12_decision_log.md` — All architecture decisions
- `00_lessons_learned.md` — Lessons captured
- `docs/business/swot-analysis.md` — Full SWOT
