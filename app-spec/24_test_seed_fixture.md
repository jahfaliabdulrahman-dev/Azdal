# Azdal — Test Seed Fixture Design

> **Status:** 🔵 Adopted
> **Date:** 2026-07-20
> **Phase:** Phase 0 Foundation — pre-test-infrastructure
> **Author:** Backend/DB Architect (live-schema-verified)
> **Source trace:** DEC-024, DEC-025, DEC-026, DEC-048, LL-010, LL-011, LL-037

---

## 1. Purpose

Design deterministic seed rows for `financial_profile`, `commitments`, `transactions`, and `goals` — plus hand-computed expected verdicts/scores — so that real `PurchaseDecisionService` and `IntegrityScoreService` calls against a seeded local Supabase produce verifiable, pre-computed outputs.

This closes the **fake-coverage gap** documented in `00_active_capabilities.md` §Stage 4: the existing Stage-4 tests re-derive formulas as local constants instead of calling the real services. These seed rows are the first step toward real tests.

---

## 2. Live Schema Verification (LL-037)

**All columns verified against LIVE Supabase** (`kqhyjngtquutzdvjfbnf`, Frankfurt 🇩🇪) via:

```sql
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('financial_profile', 'commitments', 'transactions', 'goals')
ORDER BY table_name, ordinal_position;
```

**Result: ALL columns referenced by both services EXIST with matching types. Zero missing columns.**

| Service | Table | Column | Live Type | Present? |
|---------|-------|--------|-----------|----------|
| PurchaseDecisionService.evaluate() | financial_profile | user_id | uuid NOT NULL | YES |
| | | monthly_income | numeric NULLABLE | YES |
| | | monthly_commitments_estimate | numeric NULLABLE | YES |
| | | is_deleted | boolean NOT NULL | YES |
| | commitments | user_id | uuid NOT NULL | YES |
| | | monthly_amount | numeric NOT NULL | YES |
| | | is_deleted | boolean NOT NULL | YES |
| | | status | text NOT NULL | YES |
| | transactions | user_id | uuid NOT NULL | YES |
| | | amount | numeric NOT NULL | YES |
| | | type | text NOT NULL | YES |
| | | is_deleted | boolean NOT NULL | YES |
| | | created_at | timestamptz NOT NULL | YES |
| | goals | user_id | uuid NOT NULL | YES |
| | | monthly_contribution | numeric NOT NULL | YES |
| | | is_deleted | boolean NOT NULL | YES |
| | | status | text NOT NULL | YES |
| PurchaseDecisionService.calculateRemainingBudget() | (same tables as above) | — | — | — |
| IntegrityScoreService.calculate() | transactions | user_id | uuid NOT NULL | YES |
| | | id | uuid NOT NULL | YES |
| | | type | text NOT NULL | YES |
| | | is_deleted | boolean NOT NULL | YES |
| | | created_at | timestamptz NOT NULL | YES |
| | | receipt_url | text NULLABLE | YES |

### RLS Verification

All 6 public tables have `rowsecurity = true` and ownership policies (`auth.uid() = user_id`) on SELECT, INSERT, and UPDATE:

```
financial_profile  → 3 policies (select/insert/update own)
commitments        → 3 policies (select/insert/update own)
transactions       → 3 policies (select/insert/update own)
goals              → 3 policies (select/insert/update own)
integrity_scores   → 3 policies (select/insert/update own)
purchase_decisions → 2 policies (select/insert own)
```

⚠️ **Note:** `transactions` and `goals` have no explicit DELETE policy (soft-delete is application-level via `is_deleted=true`, matching the anti-ghost protocol). This is correct — the services only UPDATE `is_deleted`, never DELETE.

### `supabase db pull` Recommendation

The local `supabase/migrations/` directory contains only **one** migration file (`20260713000000_financial_profile.sql`), but the LIVE database has **6 tables** (`financial_profile`, `commitments`, `transactions`, `goals`, `integrity_scores`, `purchase_decisions`). The other tables were deployed via the Supabase Dashboard SQL Editor or earlier migrations that are not in the repo.

**RECOMMENDED:** Run `supabase db pull` to sync local migrations with the deployed schema BEFORE any local schema changes. Without this, future `supabase db push` or `supabase db diff` will see a mismatch between local state and the live database.

```bash
cd /Users/abdurrahmanjahfali/Projects/Azdal
npx supabase db pull --linked
```

---

## 3. Hand-Computed Test Cases

### 3.1 Fixed User ID

All seed rows use a deterministic test user ID:
```
TEST_USER_ID = '00000000-0000-0000-0000-000000000001'
```
This UUID is deliberately distinct from any real account and easy to recognize in Supabase queries.

---

### 3.2 Case A: DTI Exactly 33% (Boundary — Passes)

**Formula trace (from `PurchaseDecisionService.evaluate()`):**

```
income = 10000
commitmentsEstimate = 3300 (financial_profile, no itemized commitments)
totalCommitments = max(0, 3300) = 3300
DTI = 3300 / 10000 = 0.33 → NOT > 0.33 → passes

monthlySpend = 0 (no transactions)
goalMonthly = 0 (no active goals)

purchase amount = 6700
disposable = 10000 - 3300 - 0 - 0 - 6700 = 0

→ disposable >= 0 → verdict 'yes'
```

**Expected Output:**
```json
{
  "verdict": "yes",
  "disposable": 0.0,
  "dti": 0.33,
  "goalImpact": null
}
```

**Seed rows:**

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted | TEST_USER_ID, 10000, 3300, false |

No rows needed in commitments, transactions, goals (services handle empty sets).

---

### 3.3 Case B: DTI Just Over 33% (34% — Hard NO)

```
income = 10000
commitmentsEstimate = 3400
DTI = 3400 / 10000 = 0.34 → > 0.33 → verdict 'no'
```

**Expected Output:**
```json
{
  "verdict": "no",
  "dti": 0.34,
  "disposable": 0.0,
  "goalImpact": null
}
```

**Seed rows:**

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted | TEST_USER_ID, 10000, 3400, false |

---

### 3.4 Case C: DTI Under 33% (32%) + Purchase Within Budget → Yes

```
income = 10000
commitmentsEstimate = 3200
DTI = 3200/10000 = 0.32 → passes
monthlySpend = 0, goalMonthly = 0
purchase = 6800
disposable = 10000 - 3200 - 0 - 0 - 6800 = 0 → 'yes'
```

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted | TEST_USER_ID, 10000, 3200, false |

---

### 3.5 Case D: Income = 0 (No Profile / Need Info)

No financial_profile row exists → `income = 0` → verdict `need_info`.

**Expected Output:**
```json
{
  "verdict": "need_info",
  "disposable": 0.0,
  "dti": 0.0,
  "goalImpact": null
}
```

No seed rows needed (empty tables).

---

### 3.6 Case E: Soft-Deleted Profile Row (Must Not Count)

A `financial_profile` with `is_deleted = true` → service filters `eq('is_deleted', false)` → empty result → `income = 0` → `need_info`.

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted, deleted_at | TEST_USER_ID, 10000, 3300, **true**, NOW() |

---

### 3.7 Case F: Active Goal Causes 'wait' Verdict (Disposable Negative)

```
income = 5000
commitmentsEstimate = 1500
totalCommitments = 1500
DTI = 1500/5000 = 0.30 → passes

monthlySpend = 500 (one transaction this month, expense type)
totalGoalMonthly = 1000 (one active goal)
purchase = 2300

disposable = 5000 - 1500 - 500 - 1000 - 2300 = -300 → < 0, AND totalGoalMonthly > 0 → 'wait'
```

**Expected Output:**
```json
{
  "verdict": "wait",
  "disposable": -300.0,
  "dti": 0.30,
  "goalImpact": "عندك أهداف ادخار نشطة — الشراء الآن يأخر تحقيقها."
}
```

**Seed rows:**

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted | TEST_USER_ID, 5000, 1500, false |
| transactions | user_id, amount, type, is_deleted, created_at | TEST_USER_ID, 500, 'expense', false, this month's timestamp |
| goals | user_id, name, target_amount, current_amount, monthly_contribution, status, is_deleted | TEST_USER_ID, 'Emergency Fund', 10000, 2000, 1000, 'active', false |

---

### 3.8 Case G: Same Finances Without Goals → 'no' (Not 'wait')

Same as Case F but no goal row → totalGoalMonthly = 0 → disposable < 0, totalGoalMonthly = 0 → `'no'`.

**Expected:** verdict = `'no'`, goalImpact = null.

---

### 3.9 Case H: Itemized Commitments Exceed Cold Start Estimate

```
income = 10000
financial_profile.monthly_commitments_estimate = 3000
commitments (itemized): one row, monthly_amount = 4500, status='active', is_deleted=false
  → itemizedCommitments = 4500
  → totalCommitments = max(4500, 3000) = 4500
DTI = 4500/10000 = 0.45 → > 0.33 → 'no'
```

**Expected:**
```json
{
  "verdict": "no",
  "dti": 0.45,
  "disposable": 0.0,
  "goalImpact": null
}
```

| Table | Columns | Values |
|-------|---------|--------|
| financial_profile | user_id, monthly_income, monthly_commitments_estimate, is_deleted | TEST_USER_ID, 10000, 3000, false |
| commitments | user_id, name, total_amount, remaining, monthly_amount, type, status, is_deleted | TEST_USER_ID, 'Rent', 4500, 4500, 4500, 'rent', 'active', false |

---

### 3.10 Case I: `calculateRemainingBudget()` — Normal Case

```
income = 8000
commitmentsEstimate = 2000
itemized commitments: rent 1500/month
totalCommitments = max(1500, 2000) = 2000
monthlySpend = 300 (one transaction)
goalMonthly = 500 (one goal)
remaining = 8000 - 2000 - 300 - 500 = 5200
```

**Expected Output (partial):**
```json
{
  "hasProfile": true,
  "income": 8000,
  "commitments": 2000,
  "monthlySpend": 300,
  "goalMonthly": 500,
  "remaining": 5200
}
```

---

## 4. DEC-048 Regression: Heavy Deletion Integrity Score

### Formula (from `IntegrityScoreService.calculate()`, post-DEC-048 fix):

```
no_deletion_rate = totalCount / (totalCount + deletedCount) * 100
  where totalCount = kept (is_deleted=false), deletedCount = deleted (is_deleted=true)

score = (loggingConsistency + receiptUploadRate + noDeletionRate) / 3
  rounded, clamped 0-100
```

### Target: score ≈ 41 with 3 kept / 10 deleted

**Design (confirmed by hand-computation):**

- **3 kept transactions** (is_deleted=false, type='expense'), created on **10 distinct calendar days** within a 30-day window
  - dates: day 1, 4, 7, 10, 13, 16, 19, 22, 25, 28 (10 unique days)
  - first tx = 30 days ago → `daysSince = 30` (clamped to 30)
  - `loggingConsistency = 10/30 * 100 = 33.33… → 33`

- **2 of 3 kept transactions have receipt_url** (not null)
  - `receiptUploadRate = 2/3 * 100 = 66.67 → 67`

- **10 deleted transactions** (is_deleted=true, type='expense')
  - `totalEver = 3 + 10 = 13`
  - `noDeletionRate = 3/13 * 100 = 23.0769… → 23`

- **Score:**
  ```
  (33 + 67 + 23) / 3 = 123/3 = 41.0 → 41
  ```

- **Locked factors:** `data_match_accuracy: null`, `response_time_factor: null`

### Seed rows (kept — 3 rows):

| # | user_id | amount | type | receipt_url | is_deleted | created_at |
|---|---------|--------|------|-------------|------------|------------|
| 1 | TEST_USER_ID | 100 | expense | `https://example.com/rec1.jpg` | false | NOW() - 30 days |
| 2 | TEST_USER_ID | 200 | expense | `https://example.com/rec2.jpg` | false | NOW() - 28 days (different day from #1) |
| 3 | TEST_USER_ID | 150 | expense | NULL | false | NOW() - 25 days |

Wait — 10 distinct days across only 3 rows is impossible. The logging_consistency formula counts **unique calendar days** from `created_at`. With only 3 rows, max unique days = 3. Let me recalculate:

3 unique days / 30 daysSince = 10% → loggingConsistency = 10

Hmm, that breaks the target. Let me adjust.

Actually, re-reading the code more carefully:

```dart
final uniqueDays = (distinctRows as List)
    .map((r) => DateTime.parse(
            (r as Map<String, dynamic>)['created_at'] as String)
        .toIso8601String()
        .substring(0, 10))
    .toSet()
    .length;
```

So uniqueDays counts from ALL kept transactions (the same `totalCount` rows). With only 3 kept rows, uniqueDays ≤ 3.

Let me re-target. If I have 3 kept rows on 3 distinct days:
- loggingConsistency = 3/30 * 100 = 10
- receiptUploadRate: 2/3 * 100 = 67
- noDeletionRate: 3/13 * 100 = 23
- Score = (10 + 67 + 23) / 3 = 100/3 = 33.33 → 33

That's not 41. To hit ~41 with 3 kept, I need higher loggingConsistency.

If the 3 kept are on 3 days, and daysSince is smaller:
- daysSince = 7: loggingConsistency = 3/7 * 100 = 42.86 → 43
- receiptUploadRate: 2/3 → 67
- noDeletionRate: 23
- Score = (43 + 67 + 23) / 3 = 133/3 = 44.33 → 44

Or daysSince = 6: loggingConsistency = 3/6 * 100 = 50
- Score = (50 + 67 + 23) / 3 = 140/3 = 46.67 → 47

Or with 1 receipt: receiptUploadRate = 1/3 * 100 = 33
- daysSince = 7: (43 + 33 + 23) / 3 = 99/3 = 33
- daysSince = 6: (50 + 33 + 23) / 3 = 106/3 = 35.33 → 35

With 0 receipts: receiptUploadRate = 0
- daysSince = 6: (50 + 0 + 23) / 3 = 73/3 = 24.33 → 24

To hit ~41: need loggingConsistency closer to 50 and receiptUploadRate closer to 50:
- daysSince = 10: loggingConsistency = 3/10 * 100 = 30
  - 2 receipts: (30 + 67 + 23) / 3 = 120/3 = 40 → exactly 40!

So:
- 3 kept, on 3 distinct days within last 10 days, first tx 10 days ago
- 2 receipts
- 10 deleted
- Score = (30 + 67 + 23) / 3 = 120/3 = 40 → 40

That's close to 41. Let me try:
- daysSince = 9: loggingConsistency = 3/9 * 100 = 33.33 → 33
  - (33 + 67 + 23) / 3 = 123/3 = 41 ✓

So: **3 kept on 3 distinct days, first tx 9 days ago, 2 receipts, 10 deleted → score = 41.**

Let me also verify what happens with `daysSince` calculation. The code does:

```dart
final firstDate = DateTime.parse(firstTxRow['created_at'] as String);
final daysSince = DateTime.now().difference(firstDate).inDays.clamp(1, 30);
```

So `daysSince` = the actual number of days between NOW and the first transaction. In a test, this is variable based on when the test runs. To make this deterministic, I need to calculate `daysSince` relative to a fixed "now" or use a specific date.

For a seed fixture, the simplest approach: the document specifies `created_at` relative to a test timestamp, and the expected value is computed from that.

Let me use: first tx = 9 days before test run. So `daysSince = 9`.

3 kept rows on 3 distinct dates within the 9-day window.

Updated:

| # | user_id | amount | type | receipt_url | is_deleted | created_at |
|---|---------|--------|------|-------------|------------|------------|
| K1 | TEST_USER_ID | 100 | expense | `https://example.com/r1.jpg` | false | NOW - 9 days |
| K2 | TEST_USER_ID | 200 | expense | `https://example.com/r2.jpg` | false | NOW - 5 days |
| K3 | TEST_USER_ID | 150 | expense | NULL | false | NOW - 2 days |

10 deleted rows (any dates/amounts, same user_id, type='expense', is_deleted=true):
| D1-D10 | TEST_USER_ID | any | expense | NULL | true | any |

**Expected:**
```json
{
  "score": 41,
  "logging_consistency": 33,
  "receipt_upload_rate": 67,
  "no_deletion_rate": 23,
  "data_match_accuracy": null,
  "response_time_factor": null
}
```

---

## 5. Seed Insertion Instructions

### Option A: SQL (Recommended for local Supabase)

```sql
-- Must be run against the local Supabase instance, not the linked project.
-- Start local: npx supabase start

-- 1. Clean any prior test data
DELETE FROM transactions WHERE user_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM commitments WHERE user_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM goals WHERE user_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM financial_profile WHERE user_id = '00000000-0000-0000-0000-000000000001';

-- 2. Insert Case A seed (DTI exactly 33%)
INSERT INTO financial_profile (user_id, monthly_income, monthly_commitments_estimate, is_deleted)
VALUES ('00000000-0000-0000-0000-000000000001', 10000, 3300, false);

-- Save this SQL as supabase/seed_test.sql and run:
--   npx supabase db reset  (if seed is configured)
--   OR: psql < supabase/seed_test.sql
```

### Option B: Dart Script (for programmatic seeding)

```dart
// run: dart run tool/seed_test_fixture.dart
import 'package:supabase_flutter/supabase_flutter.dart';

const testUserId = '00000000-0000-0000-0000-000000000001';

Future<void> main() async {
  await Supabase.initialize(
    url: 'http://localhost:54321',
    anonKey: 'sb_publishable_...', // local anon key
  );
  final client = Supabase.instance.client;

  // Clean
  await client.from('transactions').delete().eq('user_id', testUserId);
  await client.from('commitments').delete().eq('user_id', testUserId);
  await client.from('goals').delete().eq('user_id', testUserId);
  await client.from('financial_profile').delete().eq('user_id', testUserId);

  // Seed Case A
  await client.from('financial_profile').insert({
    'user_id': testUserId,
    'monthly_income': 10000,
    'monthly_commitments_estimate': 3300,
  });
  print('Seed complete for $testUserId');
}
```

---

## 6. LL-010 Cross-Check Procedure

### Manual/Local Gate (NOT CI — runs on developer's machine against local Supabase)

**Step 1: Start local Supabase**

```bash
cd /Users/abdurrahmanjahfali/Projects/Azdal
npx supabase start
```

Wait for:
```
supabase local development setup is running.
         API URL: http://127.0.0.1:54321
     GraphQL URL: http://127.0.0.1:54321/graphql/v1
          DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres
      Studio URL: http://127.0.0.1:54323
```

**Step 2: Seed the database**

```bash
npx supabase db reset  # applies migrations + seed.sql
```

Or run the specific seed SQL for the test cases above.

**Step 3: Verify seed landed**

```sql
SELECT * FROM financial_profile WHERE user_id = '00000000-0000-0000-0000-000000000001';
```

**Step 4: Run the real service against local Supabase**

```dart
// In a Dart test or script pointing at local Supabase:
final service = PurchaseDecisionService(client);
final result = await service.evaluate('Test Item', 6700);
print(result); // Must match: {verdict: yes, disposable: 0.0, dti: 0.33, ...}
```

**Step 5: Assert against hand-computed values**

For each test case in §3–§4:
1. Seed the specific rows
2. Call the real service method
3. Assert every field matches the hand-computed expected value
4. If mismatch → BLOCK (do not adjust the expected value to match the code — find which is wrong)

**Step 6: Record results**

After each run, record:
- Date/time of run
- Supabase version (local)
- Service code HEAD commit
- Which cases passed/failed
- Any discrepancies

---

## 7. Test Cases Summary

| Case | Service | Scenario | Expected Verdict/Score |
|------|---------|----------|----------------------|
| A | PurchaseDecision.evaluate() | DTI exactly 33% | verdict='yes', disposable=0, dti=0.33 |
| B | PurchaseDecision.evaluate() | DTI 34% (over cap) | verdict='no', dti=0.34 |
| C | PurchaseDecision.evaluate() | DTI 32% + within budget | verdict='yes', disposable=0, dti=0.32 |
| D | PurchaseDecision.evaluate() | No income (no profile) | verdict='need_info' |
| E | PurchaseDecision.evaluate() | Soft-deleted profile | verdict='need_info' |
| F | PurchaseDecision.evaluate() | Active goal + negative disposable | verdict='wait' |
| G | PurchaseDecision.evaluate() | No goal + negative disposable | verdict='no' |
| H | PurchaseDecision.evaluate() | Itemized > Cold Start estimate | verdict='no', dti=0.45 |
| I | PurchaseDecision.calculateRemainingBudget() | Normal case | remaining=5200 |
| DEC-048 | IntegrityScore.calculate() | 3 kept / 10 deleted | score=41, no_deletion_rate=23 |

---

## 8. Related

- `12_decision_log.md` — DEC-024, DEC-025, DEC-026, DEC-048
- `00_lessons_learned.md` — LL-010, LL-011, LL-037
- `00_active_capabilities.md` — §Known gap (test-quality)
- `21_personal_build_plan.md` — Phase 0 real tests milestone
