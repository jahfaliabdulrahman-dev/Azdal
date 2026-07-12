# Azdal — Implementation Backlog & Build Plan

> **Status:** Populated — Reconciled 2026-07-12 against real runway  
> **Source:** Synthesized from `docs/business/build-plan.md` and `docs/business/hackathon-strategy.md`

---

## Overview

**MVP scope:** Tier 1 Coach — 8 features  
**Team:** Abdulrahman (Flutter/AI, + AI agent swarm per `.hermes/swarm.yaml`) + Deema (UI) + Saja (Business/Pitch) + Hala (Forms/Presentation)

### Revised Timeline (2026-07-12) — the original 4-week / 9-day plan is void

As of today, `lib/` and `test/` are still empty and `pubspec.yaml` is a stub — **zero code written**, against a plan that assumed 9 build days ending July 14. That plan is gone. Good news: AMAD is now **online, no travel** — the 2 days that were going to be lost to travel (July 14-15) are recovered as build time.

| Window | Dates | What happens |
|--------|-------|---------------|
| Build sprint | **July 12-15** (~3.5 days) | Stage 1-4 below — scaffold through Goals/Integrity. This is the core feature build. |
| Event window | **July 16-18** (3 days, online) | Stage 5 — testing, audit, demo polish, pitch rehearsal, and any cut-list items if the sprint finishes early. Real working time, not just a presentation slot. |

**Total estimated effort across Stage 1-5: ~101 hours.** Across ~6.5 available days that's ~15h/day solo — not sustainable for one person. This is exactly why the AI agent swarm (`.hermes/swarm.yaml`, currently marked "Activated during Stage 1+") needs to switch on **today**, not get deferred — solo manual coding at this pace doesn't close the gap.

**If the swarm isn't ready to activate today:** cut scope, don't cut sleep. Re-check the cut list in Risk Mitigation below daily, starting from Stage 4 polish items inward.

---

## Stage 1 — Project Init (July 12, today)

**Goal:** Flutter scaffold + Gemini connection

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| INIT-01 | Scaffold Flutter project with Riverpod + go_router | State Engineer | None | 2h |
| INIT-02 | Configure Gemini API package + test connection | State Engineer | INIT-01 | 1h |
| INIT-03 | Set up Supabase project + create tables | Backend Architect | None | 1h |
| INIT-04 | Set up CI (GitHub Actions — lint only) | DevOps | INIT-01 | 1h |
| INIT-05 | Load Cairo font + configure RTL | State Engineer | INIT-01 | 1h |

---

## Stage 2 — Chat + Transaction Entry (July 12-13)

**Goal:** Working chat with AI + voice/text transaction logging

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| CHAT-01 | Build Chat UI (input bar, bubbles, typing indicator) | State Engineer | INIT-01 | 4h |
| CHAT-02 | Implement ChatProvider (Riverpod) | State Engineer | CHAT-01 | 3h |
| CHAT-03 | Integrate Gemini Flash — system prompt, response parsing | State Engineer | INIT-02 | 3h |
| CHAT-04 | Implement voice input (speech_to_text, cross-platform per DEC-016) | State Engineer | CHAT-01 | 2h |
| CHAT-05 | Build transaction entry flow: AI classification → confirmation | State Engineer | CHAT-03 | 4h |
| CHAT-06 | Compound transaction splitting (group_id) | State Engineer | CHAT-05 | 2h |
| CHAT-07 | Cold Start Intelligence — 3 questions → instant insight | State Engineer | CHAT-03 | 2h |
| CHAT-08 | Widget tests: ChatProvider, Gemini mock responses | QA Tester | CHAT-02 | 3h |

---

## Stage 3 — OCR (July 13-14)

**Goal:** Receipt scanning only. "Can I Buy?" (BUY-01→04) moved to Stage 4 —
see DEC-019. It needs commitments + active goals data that don't exist
until Stage 4's COMMIT-01/GOAL-01 land; building it here would ship a
verdict engine silently missing half its inputs.

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| OCR-01 | Camera/gallery integration (image_picker) | State Engineer | CHAT-01 | 2h |
| OCR-02 | System share sheet (receive_sharing_intent) | State Engineer | OCR-01 | 1h |
| OCR-03 | Gemini Vision OCR integration | State Engineer | OCR-01 | 3h |
| OCR-04 | Receipt line items extraction → compound split card | State Engineer | OCR-03, CHAT-06 | 3h |
| OCR-05 | Cancel-before-confirm on compound_split_card + transaction undo (soft-delete) on the confirmation message — DEC-020, found during live testing | State Engineer | OCR-04 | 2h |

---

## Stage 4 — Commitments + Goals + Integrity + "Can I Buy?" + Polish (July 14-15)

**Goal:** Savings goals, commitments tracking, integrity score, purchase
decision engine, Tier 2 simulation

**Reconciled 2026-07-12 (DEC-019):** BUY-01→04 moved in from Stage 3 —
"Can I buy?" needs commitments + active goals as inputs (01_prd.md:133),
neither existed until now. COMMIT-01 added — no commitments-tracking task
existed anywhere in the original backlog despite the PRD listing it as a
Tier 1 feature (gap flagged by Product Steward during the Stage 2 handoff).
COMMIT-01 must reuse the `monthly_commitments` estimate the user already
gave during Cold Start (CHAT-07) instead of asking again — that value is
currently computed for the initial insight message and then discarded;
fix that as part of this task, not as an afterthought.

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| COMMIT-01 | Commitments CRUD (reuses deployed `commitments` table/RLS). Seed from the Cold Start `monthly_commitments` estimate as a starting value the user can refine into itemized commitments, instead of re-asking from scratch | State Engineer | CHAT-07 | 3h |
| GOAL-01 | Goals CRUD + UI (quick_input_form widget) | State Engineer | CHAT-01 | 3h |
| GOAL-02 | Goal progress tracking (goal_progress_card) | State Engineer | GOAL-01 | 2h |
| GOAL-03 | Gap detection: data vs reality reconciliation | State Engineer | GOAL-02 | 3h |
| INTG-01 | Integrity Score calculator (Edge Function) | Backend Architect | None | 2h |
| INTG-02 | Integrity Score display widget (summary_card) | State Engineer | INTG-01 | 2h |
| BUY-01 | "Can I buy?" domain logic (Riverpod provider) — income + commitments + current spend + days-to-salary + active goals | State Engineer | COMMIT-01, GOAL-01 | 4h |
| BUY-02 | Supabase Edge Function: purchase_calculation | Backend Architect | BUY-01 | 2h |
| BUY-03 | Verdict widget (YES/WAIT/NO) with Arabic explanation | State Engineer | BUY-01 | 3h |
| BUY-04 | Integration test: full "Can I buy?" flow | QA Tester | BUY-03 | 2h |
| SIM-01 | Tier 2 gateway simulation logic | State Engineer | BUY-01, INTG-01 | 3h |
| SIM-02 | Demo script wiring ("show me Tier 2 readiness") | State Engineer | SIM-01 | 2h |
| POL-01 | Silent Triage logic (Green/Gray/Red) | State Engineer | CHAT-05 | 2h |
| POL-02 | Evening check-in scheduling | State Engineer | CHAT-02 | 2h |
| POL-03 | Progress summary widget (weekly wins) | State Engineer | GOAL-02 | 2h |

---

## Stage 5 — Testing, Audit, Polish (July 16-18, online event window)

**Goal:** All tests pass, demo rehearsed, pitch ready

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| QA-01 | Full widget test suite (all 6 catalog widgets) | QA Tester | Stage 2-4 | 4h |
| QA-02 | Integration tests: 8 critical flows | QA Tester | Stage 2-4 | 4h |
| QA-03 | RTL layout verification | QA Tester | Stage 2-4 | 1h |
| QA-04 | Offline behavior testing | QA Tester | Stage 2-4 | 2h |
| AUD-01 | Hostile audit: prompt injection, data integrity | Auditor | Stage 2-4 | 3h |
| DEMO-01 | Demo runbook (exact script + timings) | Product Steward | SIM-02 | 3h |
| DEMO-02 | Demo rehearsal (3 runs minimum) | Team | DEMO-01 | 3h |
| DEMO-03 | Backup recorded video demo | Team | DEMO-01 | 2h |
| PITCH-01 | Pitch deck polish (Deema — visual) | UI/UX Designer | None | 4h |
| PITCH-02 | Judge Q&A drilling (Saja leads) | Team | PITCH-01 | 2h |
| MON-01 | **Stretch, non-functional.** Static "Premium unlock" / course-store teaser card in-app (lock icon, price, CTA that does nothing or shows "coming soon") — visual proof of Day-1 revenue model for judges. Zero backend, zero payment logic. Build only after Stage 2-4 are demo-stable | State Engineer | Stage 2-4 complete | 1h |

---

## Dependency Graph

```
INIT-01 → CHAT-01 → CHAT-02 → CHAT-03 → CHAT-05 → CHAT-06
                                    → CHAT-07 → COMMIT-01
                                    → CHAT-04
                                    → OCR-01 → OCR-02, OCR-03 → OCR-04

CHAT-01 → GOAL-01 → GOAL-02 → GOAL-03

COMMIT-01, GOAL-01 → BUY-01 → BUY-02
                   → BUY-03 → BUY-04

INTG-01 → INTG-02 → SIM-01
BUY-01 → SIM-01 → SIM-02

Stage 2-4 → QA-01, QA-02, QA-03, QA-04
        → AUD-01
        → DEMO-01 → DEMO-02
```

---

## Parallel Work Opportunities

| Window | Parallel Tasks |
|--------|---------------|
| July 12-13 (Stage 2) | CHAT-01 (+ QA CHAT-08 in parallel) |
| July 13-14 (Stage 3) | OCR-01/02 (OCR only — BUY moved to Stage 4, DEC-019) |
| July 14-15 (Stage 4) | COMMIT-01 + GOAL-01 + INTG-01 (in parallel), then BUY-01 once COMMIT-01/GOAL-01 land |
| July 16-18 (Stage 5) | QA + Audit + Demo (all parallel) |

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Gemini API issues | DeepSeek fallback, local mock responses |
| GenUI/A2UI beta fails | Native Flutter widgets from same JSON schemas |
| Time runs short | Cut MON-01 (monetization teaser card) first, then SIM-02 (Tier 2 simulation). Core 6 features non-negotiable. |

---

## Related
- `01_prd.md` — Feature definitions
- `09_testing_acceptance.md` — Test cases
- `docs/business/hackathon-strategy.md` — Demo day plan
