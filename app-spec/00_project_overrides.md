# Azdal — Project Overrides

> **Purpose:** Any project-specific rule overrides, exceptions, or special configurations that differ from the Flutter Operation Global Contract.  
> **Status:** No overrides needed at Stage 0. Populate as project evolves.  
> **Last Updated:** 2026-06-29

---

## Global Contract Adherence

Azdal follows the Flutter Operation Global Contract in its entirety:

1. ✅ Zero Assumptions
2. ✅ Specification Before Code
3. ✅ Traceability Required
4. ✅ Backend as Source of Truth
5. ✅ No Hard Delete (isDeleted flag)
6. ✅ No Magic Strings
7. ✅ No Unapproved Packages
8. ✅ No Procedural Reduction
9. ✅ Escalate to Lead Architect
10. ✅ Respect Boundaries

---

## Azdal-Specific Overrides

| Global Rule | Override | Rationale | Approved |
|-------------|----------|-----------|----------|
| None | — | — | — |

---

## Azdal-Specific Additions

| ID | Rule | Rationale |
|----|------|-----------|
| AZ-001 | All user-facing text must be in Arabic (Saudi dialect). Technical content in English. | Arabic-first market |
| AZ-002 | LLMs must NEVER perform financial calculations — SQL/Python only. | LLMs hallucinate math |
| AZ-003 | Hybrid verification required for any credit-related metric: Open Banking ground truth + AI enrichment + Integrity cross-validation. | Goodhart's Law protection |
| AZ-004 | Chat UI is the SOLE screen. All features are widgets inline. | Zero navigation design |
| AZ-005 | Guest-first: no registration wall. On-device data default with opt-in cloud sync. | PDPL compliance + user trust |

---

## Package Exception Pre-Approvals

| Package | Purpose | Status |
|---------|---------|--------|
| `google_generative_ai` | Gemini API integration | Pre-approved |
| `supabase_flutter` | Backend | Pre-approved |
| `flutter_riverpod` | State management | Pre-approved |
| `receive_sharing_intent` | System share sheet | Pre-approved |
| `image_picker` | Camera/gallery | Pre-approved |

All other packages require Lead Architect escalation per Global Contract Rule 7.
