# Azdal — Lessons Learned

> **Purpose:** Capture ALL lessons, decisions, rejected approaches, and critical insights during the project lifecycle.  
> **Rule:** Route lessons here IMMEDIATELY when discovered — not later.  
> **Status:** Populated from historical brainstorming sessions.

---

## LL-001: Tracking Without Solution = Failure

- **Discovered:** 2026-05-21 — Team brainstorming with Saja
- **Lesson:** Finance tracking apps fail because they only track — they don't solve. Previous hackathon teams were rejected specifically because they had "متابعة فقط بدون حلول".
- **Impact:** Pivoted from "expense tracker" to "3-tier financial rehabilitation program."
- **Rule:** Every feature must have a behavioral intervention, not just observation.
- **Source:** `docs/archive/raw-ideas-brainstorming.md`

---

## LL-002: BNPL Is the Real Pain Point

- **Discovered:** 2026-05-21 — Saja's insight
- **Lesson:** Saudi users' biggest financial pain is unconscious BNPL debt accumulation across Tabby, Tamara, and other providers. They don't know their total commitments.
- **Impact:** Shifted B2B focus from "retail data analytics" to "behavioral credit scoring for BNPL companies."
- **Rule:** Solves a problem lenders have (high defaults) AND a problem consumers have (debt spiral).
- **Source:** `docs/business/business-model-canvas.md`

---

## LL-003: 3-in-1 Solves the Sustainability Problem

- **Discovered:** 2026-05-21 — Saja's vision
- **Lesson:** A standalone coach has no revenue path. A standalone lender needs a license. A standalone investment app has no users. Combined: Coach builds users → data proves creditworthiness → lending generates revenue → investment generates more revenue. Each tier feeds the next.
- **Impact:** Designed the 3-tier system (Coach → Smart Lender → Wealth Builder).
- **Source:** `docs/archive/raw-ideas-brainstorming.md`

---

## LL-004: Financial Education Track Is the Best Fit

- **Discovered:** 2026-05-21 — Saja pushed, Abdulrahman agreed
- **Lesson:** Our entire feature set is educational at its core — "Can I buy?" is a teaching moment, the 5-phase journey is a curriculum, and tiers reward learning.
- **Impact:** Changed track from "Generative AI for FinTech" to "Financial Education."
- **Rule:** Judges in education track value behavioral science, user transformation, measurable outcomes.
- **Source:** `docs/business/hackathon-strategy.md`

---

## LL-005: Goodhart's Law Threatens Behavioral Scoring

- **Discovered:** 2026-05-21 — Gemini paranoid architect critique
- **Lesson:** "When a measure becomes a target, it ceases to be a good measure." If users know data entry = credit access, they'll game the system.
- **Impact:** Designed hybrid verification architecture: Open Banking ground truth + AI enrichment + Integrity Score cross-validation. The Integrity Score is NEVER the only factor.
- **Rule:** Every behavioral metric needs an independent ground truth anchor.
- **Source:** `docs/archive/gemini-critique.md`

---

## LL-006: LLMs Must Never Calculate Financially

- **Discovered:** 2026-05-16 — Triple-agent validation
- **Lesson:** LLMs hallucinate math. Financial calculations must be deterministic.
- **Impact:** Architecture rule: "LLM understands and routes — SQL/Python calculates."
- **Rule:** NEVER route financial math through an LLM. SQL for queries, Python for complex calculations, LLM for understanding and summarization only.
- **Source:** `07_flutter_architecture.md`

---

## LL-007: Framing Beats Restrictions

- **Discovered:** 2026-05-14 — Abdulrahman original insight
- **Lesson:** "لما تقول اشتري بوعي انت تقتل المتعة" — telling users to "buy consciously" kills the joy. Position as empowerment, not restriction.
- **Impact:** Designed behavioral UX: Silent Triage (only intervene on red/gray), Framing Effect (focus on future gains, not current losses), evening check-in (not real-time nagging).
- **Rule:** Every intervention must be framed as "you chose better" not "we stopped you."
- **Source:** `00_product_discovery.md`

---

## LL-008: Zero-Friction Is Non-Negotiable

- **Discovered:** 2026-05-14 — Abdulrahman
- **Lesson:** Opening an app + typing price + photographing product = too much work. 77% of finance app users quit in 3 days due to manual entry.
- **Impact:** Input methods locked: Voice (3 seconds) + OCR (1 photo) + Chat (natural). Zero manual data entry forms.
- **Rule:** Every additional tap between user and expense logging reduces retention. Kill all friction.
- **Source:** `00_product_discovery.md`

---

## LL-009: Never Say "No Data"

- **Discovered:** 2026-05-16 — Triple-agent brainstorming
- **Lesson:** Apps that say "add more transactions to see insights" lose users. The first experience must deliver value.
- **Impact:** Designed Cold Start Intelligence: use income brackets, general estimates, confidence levels. Give value first, then ask minimal questions (3 max).
- **Rule:** Onboarding delivers insight before asking for input.
- **Source:** `01_prd.md`

---

## LL-010: Passing Tests and Agent Self-Approval Are Not Verification

- **Discovered:** 2026-07-14 — Abdulrahman, during Stage 4 (BUY+INTG) live device testing
- **Lesson:** Stage 4 was logged DONE (DEC-035) on the strength of `flutter analyze` clean, `flutter test` 34/34 passing, and the swarm's own Zero-Trust Auditor + SCSI Guardian both signing off APPROVE with 0 CRITICAL findings. Live device testing plus direct Supabase queries then found 5 critical bugs none of those gates caught: a purchase-confirmation insert against columns that don't exist on the live table (100% failure rate), a submit button that never disabled (unlimited duplicate writes), success messages showing the same sentence twice, Arabic-Indic numerals silently failing every form-field parse, and — most instructively — a regression introduced *by* the fix for the disable-button bug, where a key rename (`_form_kind` → `form_kind`) got silently dropped, breaking every commitment/goal/income save for hours with zero errors shown anywhere.
- **Impact:** None of the 5 bugs were reachable by static analysis or by tests that never call the real class under test (a related, separate finding: the Stage-4 unit tests re-derive their target formulas as local constants instead of instantiating the actual service — they would pass unchanged even against a broken implementation). Every one was found by: reproducing the exact user flow live on a real device, then independently querying the live database directly (not trusting the app's own "success" message) to confirm a matching row actually exists with the right values and the right timestamp.
- **Rule:** For this project, "tests pass" and "an agent/auditor approved it" are necessary but never sufficient. Before accepting any "done" report — especially one involving a database write, a widget-to-handler payload, or a fix for a previous bug (fixes are exactly where regressions hide) — reproduce the flow live and check the live data source directly. Route B's own audit/guardian layer is not a substitute for this; it missed all 5 bugs above despite explicitly claiming to check for exactly this class of issue.
- **Source:** `12_decision_log.md` DEC-036, this session's Stage 4 verification transcript

---

## Key Decisions (Permanent)

| ID | Decision | Date | Rationale |
|----|----------|------|-----------|
| DEC-001 | 3-tier system: Coach → Smart Lender → Wealth Builder | 2026-05-21 | Each tier feeds the next; solves sustainability |
| DEC-002 | Track: Financial Education | 2026-05-21 | Core product is educational; better fit than GenAI track |
| DEC-003 | Hybrid architecture: LLM understands, SQL calculates, GenUI displays | 2026-05-16 | Prevents financial math hallucination |
| DEC-004 | Phase 1 free, Phase 2 B2B credit scoring, Phase 3 lending | 2026-05-21 | Avoids needing SAMA license for MVP |
| DEC-005 | Hackathon MVP = Tier 1 Coach ONLY, Tier 2-3 = vision slides | 2026-05-21 | Sharp solution wins; scattered loses |
| DEC-006 | Chat UI as sole screen — widgets inline | 2026-05-20 | Zero navigation, zero friction |
| DEC-007 | Dark mode only, Cairo font, Western numerals | 2026-05-20 | Visual identity consistency |
| DEC-008 | Flutter + Gemini Flash + Supabase + Riverpod | 2026-05-19 | Proven stack for rapid mobile AI |
| DEC-009 | Hybrid verification: Open Banking + AI + Integrity | 2026-05-21 | Anti-gaming for behavioral scoring |
| DEC-010 | No hard delete — isDeleted flag | 2026-06-29 | Anti-ghost protocol per global contract |

---

## Related
- `12_decision_log.md` — Formal decision records
- `13_assumptions_risks.md` — Risk registers
- `docs/archive/raw-ideas-brainstorming.md` — Original brainstorming sessions
