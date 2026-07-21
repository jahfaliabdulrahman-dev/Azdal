# Coverage-Equivalence Mapping — Phase 4 Fake Group Deletion

Date: 2026-07-21
Context: Azdal Phase 4 closeout — deleting re-deriving test groups that never
called the real service (DEC-048 failure mode).

## Integrity Score Service

Fake group deleted: `group('IntegrityScoreService', ...)` (was lines 12-132)
- 10 tests that re-derived every factor as local constants

| Fake Test Scenario | Surviving Real Test | How |
|---|---|---|
| score range 0-100 (6 boundary cases) | `perfect score — all 100s` (:135) + `new account — no transactions` (:149) + `all factors clamped individually` (:206) | Range + clamp enforced by the service's own `clamp(0,100)` — verified at extremes (0, 33, 100) and overflow (>100 clamped to 100) |
| equal weight (80+50+95)/3=75 | `typical account with some deletions` (:163) | Asserts all 3 factors individually + final score via actual `computeScore()` — (40+50+80)/3=56.67→57 |
| locked factors never numeric | `locked factors always null` (:181) | Direct `isNull` assertion on `computeScore()` output |
| divide-by-zero new account→33 | `new account — no transactions` (:149) | Assert `score:33, logging:0, receipt:0, deletion:100` via actual `computeScore(totalCount:0,...)` |
| no_deletion_rate = kept/(kept+deleted) → 80% | `typical account with some deletions` (:163) | `computeScore(totalCount:8, deletedCount:2)` → `no_deletion_rate:80` |
| heavy deletion → 23.08% (DEC-048 regression) | `heavy deletions — rate clamped to 0–100` (:193) | `computeScore(totalCount:3, deletedCount:10)` → `no_deletion_rate:23` — THIS IS THE DEC-048 CATCHER |
| receipt rate 3/5 → 60% | `typical account with some deletions` (:163) | `computeScore(totalCount:8, withReceipt:4)` → `receipt_upload_rate:50` |
| logging consistency 7/30 → 23.33% | `rounding — .67 rounds up` (:220) | `computeScore(uniqueDays:2, daysSince:30)` → `logging_consistency:7` |
| factor values clamped 0-100 | `all factors clamped individually` (:206) | uniqueDays(40) > daysSince(30) → clamped to 100; withReceipt(15) > totalCount(10) → clamped to 100 |

**Verdict: ALL 10 fake scenarios covered by 7 real computeScore tests. No scenario lost.**

## Purchase Decision Service

Fake group deleted: `group('PurchaseDecisionService', ...)` (was lines 12-85)
- 7 tests that re-derived DTI/disposable locally as constants

| Fake Test Scenario | Surviving Real Test | How |
|---|---|---|
| verdict constants (yes/wait/no/need_info) | All 8 decideVerdict tests | Every test asserts `result['verdict']` against one of the four constants |
| DTI 33% threshold correct | `DTI > 33% → hard no` (:101) + `DTI exactly 33% → allowed` (:115) | 40%→no, 33%→allowed via actual `decideVerdict()` |
| disposable formula correct (8000-2000-1500-500-1000=3000) | `positive disposable → yes` (:128) | Same inputs → asserts `disposable:3000` via actual `decideVerdict()` |
| negative disposable + no goals → no | `negative disposable + no goals → no` (:156) | 5000-1000-4500-0-1000=-1500 → verdict:'no' via actual `decideVerdict()` |
| negative disposable + goals → wait | `negative disposable + active goals → wait` (:142) | 5000-1000-4000-500-1000=-1500 → verdict:'wait' via actual `decideVerdict()` |
| zero income → need_info | `zero income → need_info` (:88) | income:0 → verdict:'need_info' via actual `decideVerdict()` |
| — | `disposable exactly zero → yes` (:170) | Additional boundary case NOT in fake group — bonus coverage |
| — | `DTI with zero income → need_info` (:183) | Additional boundary case NOT in fake group — division-by-zero guard |

**Verdict: ALL 7 fake scenarios covered by 8 real decideVerdict tests. 2 bonus boundary cases not in the fake group. No scenario lost.**

## Summary

Both fake groups are fully covered. The real groups add value the fakes never could:
- The integrity real group catches the DEC-048 bug (proven by mutation check — goes RED when bug is re-introduced)
- The purchase real group catches DTI cap weakening (proven by mutation check)
- The real groups assert against actual service output, not re-derived constants

Deletion is safe. Coverage improved, not reduced.
