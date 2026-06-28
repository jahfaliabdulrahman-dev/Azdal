# Azdal — Implementation Backlog & Build Plan

> **Status:** Populated — Stage 0 Plan  
> **Source:** Synthesized from `docs/business/build-plan.md` and `docs/business/hackathon-strategy.md`

---

## Overview

**Total build window:** 4 weeks (pre-hackathon) + hackathon refinement  
**MVP scope:** Tier 1 Coach — 8 features  
**Team:** Abdulrahman (Flutter/AI) + Deema (UI) + Saja (Business/Pitch)

---

## Stage 1 — Project Init (Week 0)

**Goal:** Flutter scaffold + Gemini connection

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| INIT-01 | Scaffold Flutter project with Riverpod + go_router | State Engineer | None | 2h |
| INIT-02 | Configure Gemini API package + test connection | State Engineer | INIT-01 | 1h |
| INIT-03 | Set up Supabase project + create tables | Backend Architect | None | 1h |
| INIT-04 | Set up CI (GitHub Actions — lint only) | DevOps | INIT-01 | 1h |
| INIT-05 | Load Cairo font + configure RTL | State Engineer | INIT-01 | 1h |

---

## Stage 2 — Chat + Transaction Entry (Week 1)

**Goal:** Working chat with AI + voice/text transaction logging

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| CHAT-01 | Build Chat UI (input bar, bubbles, typing indicator) | State Engineer | INIT-01 | 4h |
| CHAT-02 | Implement ChatProvider (Riverpod) | State Engineer | CHAT-01 | 3h |
| CHAT-03 | Integrate Gemini Flash — system prompt, response parsing | State Engineer | INIT-02 | 3h |
| CHAT-04 | Implement voice input (Apple Speech on-device) | State Engineer | CHAT-01 | 2h |
| CHAT-05 | Build transaction entry flow: AI classification → confirmation | State Engineer | CHAT-03 | 4h |
| CHAT-06 | Compound transaction splitting (group_id) | State Engineer | CHAT-05 | 2h |
| CHAT-07 | Cold Start Intelligence — 3 questions → instant insight | State Engineer | CHAT-03 | 2h |
| CHAT-08 | Widget tests: ChatProvider, Gemini mock responses | QA Tester | CHAT-02 | 3h |

---

## Stage 3 — OCR + "Can I Buy?" (Week 2)

**Goal:** Receipt scanning + purchase decision engine

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| OCR-01 | Camera/gallery integration (image_picker) | State Engineer | CHAT-01 | 2h |
| OCR-02 | System share sheet (receive_sharing_intent) | State Engineer | OCR-01 | 1h |
| OCR-03 | Gemini Vision OCR integration | State Engineer | OCR-01 | 3h |
| OCR-04 | Receipt line items extraction → compound split card | State Engineer | OCR-03, CHAT-06 | 3h |
| BUY-01 | "Can I buy?" domain logic (Riverpod provider) | State Engineer | None | 4h |
| BUY-02 | Supabase Edge Function: purchase_calculation | Backend Architect | BUY-01 | 2h |
| BUY-03 | Verdict widget (YES/WAIT/NO) with Arabic explanation | State Engineer | BUY-01 | 3h |
| BUY-04 | Integration test: full "Can I buy?" flow | QA Tester | BUY-03 | 2h |

---

## Stage 4 — Goals + Integrity + Polish (Week 3)

**Goal:** Savings goals, integrity score, Tier 2 simulation

| ID | Task | Assignee | Depends On | Est. |
|----|------|----------|-----------|------|
| GOAL-01 | Goals CRUD + UI (quick_input_form widget) | State Engineer | CHAT-01 | 3h |
| GOAL-02 | Goal progress tracking (goal_progress_card) | State Engineer | GOAL-01 | 2h |
| GOAL-03 | Gap detection: data vs reality reconciliation | State Engineer | GOAL-02 | 3h |
| INTG-01 | Integrity Score calculator (Edge Function) | Backend Architect | None | 2h |
| INTG-02 | Integrity Score display widget (summary_card) | State Engineer | INTG-01 | 2h |
| SIM-01 | Tier 2 gateway simulation logic | State Engineer | BUY-01, INTG-01 | 3h |
| SIM-02 | Demo script wiring ("show me Tier 2 readiness") | State Engineer | SIM-01 | 2h |
| POL-01 | Silent Triage logic (Green/Gray/Red) | State Engineer | CHAT-05 | 2h |
| POL-02 | Evening check-in scheduling | State Engineer | CHAT-02 | 2h |
| POL-03 | Progress summary widget (weekly wins) | State Engineer | GOAL-02 | 2h |

---

## Stage 5 — Testing, Audit, Polish (Week 4 + Hackathon Prep)

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

---

## Dependency Graph

```
INIT-01 → CHAT-01 → CHAT-02 → CHAT-03 → CHAT-05 → CHAT-06
                                    → CHAT-07
                                    → CHAT-04
                                    → OCR-01 → OCR-02, OCR-03 → OCR-04

CHAT-01, CHAT-03 → BUY-01 → BUY-03 → BUY-04
                → SIM-01 → SIM-02
                → GOAL-01 → GOAL-02 → GOAL-03

INTG-01 → INTG-02 → SIM-01

Stage 2-4 → QA-01, QA-02, QA-03, QA-04
        → AUD-01
        → DEMO-01 → DEMO-02
```

---

## Parallel Work Opportunities

| Week | Parallel Tasks |
|------|---------------|
| Week 1 | CHAT-01 (+ QA CHAT-08 in parallel) |
| Week 2 | OCR-01/02 + BUY-01 (in parallel) |
| Week 3 | GOAL-01 + INTG-01 (in parallel) |
| Week 4 | QA + Audit + Demo (all parallel) |

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Gemini API issues | DeepSeek fallback, local mock responses |
| GenUI/A2UI beta fails | Native Flutter widgets from same JSON schemas |
| Time runs short | Cut SIM-02 (Tier 2 simulation) first. Core 6 features non-negotiable. |

---

## Related
- `01_prd.md` — Feature definitions
- `09_testing_acceptance.md` — Test cases
- `docs/business/hackathon-strategy.md` — Demo day plan
