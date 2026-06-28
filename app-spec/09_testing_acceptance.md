# Azdal — Testing & Acceptance Strategy

> **Status:** Template — populated during Stage 1+  
> **Last Updated:** 2026-06-29

---

## Testing Philosophy

- **Unit tests:** All Riverpod providers and domain logic
- **Widget tests:** Every widget from the catalog + chat UI
- **Integration tests:** Full flows: transaction entry, "Can I buy?", goal tracking
- **Hostile audit:** Pre-release security + behavioral edge cases

---

## Test Pyramid (Planned)

```
        /\
       /E2E\      Integration tests (full flows)
      /──────\
     /Integrat\   Widget tests + provider integration
    /──────────\
   /   Unit     \ Unit tests (providers, domain, services)
  /──────────────\
```

---

## Test Coverage Targets

| Layer | Target | Critical |
|-------|--------|----------|
| Domain logic | 90%+ | Purchase decision engine, Integrity Score calculator |
| Providers | 85%+ | ChatProvider, TransactionProvider, GoalProvider |
| Widgets | 70%+ | All 6 catalog widgets |
| Integration | Key flows only | "Can I buy?", transaction entry, goal creation |

---

## Critical Test Cases (Hackathon)

### FT-001: Transaction Entry — Voice
- Voice → transcription → classification → confirmation

### FT-002: Transaction Entry — OCR
- Photo → Gemini Vision → line items extraction → user confirmation

### FT-003: "Can I Buy?" — YES
- Income > spending, no goal conflict → YES with explanation

### FT-004: "Can I Buy?" — NO (Goal Impact)
- Active savings goal, purchase delays it → NO with timeline

### FT-005: Integrity Score Calculation
- Multiple factors → score computed correctly → tier assigned

### FT-006: Cold Start — No History
- Empty state → asks 3 questions → delivers instant insight

### FT-007: Compound Transaction Split
- "475 — coffee, groceries, restaurant" → 3 transactions with group_id

### FT-008: Commitment Tracking
- Add BNPL commitment → auto-include in "Can I buy?" → celebrate payoff

---

## QA Gate (Before Hackathon Demo)

- [ ] All 8 critical tests pass
- [ ] RTL layout verified (no text clipping)
- [ ] Dark mode consistent across all widgets
- [ ] Arabic text renders correctly (Cairo font loaded)
- [ ] Gemini API responses parsed correctly
- [ ] Offline behavior handled gracefully
- [ ] No hardcoded strings (all from constants/theme)
- [ ] No stub methods in critical paths

---

## Regression Suite (Post-Hackathon)

Will grow to include:
- B2B API contract tests
- Open Banking integration tests
- Performance tests (100+ transactions)
- Load tests (1000 concurrent users)
- Accessibility tests (WCAG AA)

---

## Related
- `16_implementation_backlog.md` — Feature build order
- `18_zero_trust_red_team_audit.md` — Hostile audit
- `docs/business/hackathon-strategy.md` — Demo day requirements
