# Azdal — ER Diagram (MVP + Growth Path)

> **Date:** 2026-05-19 (Updated)
> **Decision:** Three tables for MVP. TEXT category with CHECK. No profiles table. No categories table.
> **Agreed by:** Sulaiman (Hermes) + Eng. Abdulrahman

---

## Database: Supabase PostgreSQL

### Table 1: `transactions` (Core — MVP Week 1)

```sql
CREATE TABLE transactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    TEXT NOT NULL,
  amount_sar    NUMERIC(10,2) NOT NULL CHECK (amount_sar > 0),
  category      TEXT NOT NULL CHECK (category IN (
    'سكن','مواصلات','طعام','قهوة','تسوق','صحة','تعليم',
    'فواتير','ترفيه','اشتراكات','سفر','صدقة/زكاة','أخرى'
  )),
  merchant      TEXT,
  tx_date       DATE NOT NULL DEFAULT CURRENT_DATE,
  source        TEXT DEFAULT 'manual',         -- 'manual' | 'ocr' | 'voice'
  group_id      UUID,                          -- for compound transactions (multi-category)
  is_deleted    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tx_session_month 
  ON transactions(session_id, tx_date) 
  WHERE is_deleted = FALSE;
```

**`group_id`**: When user says "اشتريت بـ475 — قهوة وخضار ومطعم", all 3 rows share one `group_id`. Enables "show me this group" and "delete all".

---

### Table 2: `commitments` (Recurring — MVP Week 2-3)

```sql
CREATE TABLE commitments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      TEXT NOT NULL,
  name            TEXT NOT NULL,              -- "تمارا", "إيجار", "قسط سيارة"
  total_amount    NUMERIC(10,2),              -- 1000
  monthly_amount  NUMERIC(10,2) NOT NULL,     -- 200
  remaining       NUMERIC(10,2),              -- 1000 → 800 → 600...
  category        TEXT DEFAULT 'التزامات',
  provider        TEXT,                       -- "تمارا", "الراجحي"
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_commitments_session 
  ON commitments(session_id) 
  WHERE is_active = TRUE;
```

**Purpose:** User says "عندي تمارا 1000 ياخذون 200 كل شهر" → system detects recurring commitment, tracks remaining balance, includes in "Can I buy?" calculations.

---

### Table 3: `goals` (Savings Goals — MVP Week 3-4)

```sql
CREATE TABLE goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      TEXT NOT NULL,
  name            TEXT NOT NULL,              -- "تجميع 20 ألف"
  target_amount   NUMERIC(10,2) NOT NULL,     -- 20000
  monthly_save    NUMERIC(10,2) NOT NULL,     -- 556
  current_saved   NUMERIC(10,2) DEFAULT 0,    -- 0 → 556 → 1112...
  start_date      DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date        DATE NOT NULL,
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_goals_session 
  ON goals(session_id) 
  WHERE is_active = TRUE;
```

**Purpose:** User says "أبغى أجمع 20 ألف في 3 سنوات" → system calculates monthly needed, tracks progress, adjusts "Can I buy?" to protect goals.

---

### Table 4: `receipt_items` (SKU Data — Post-Hackathon)

```sql
CREATE TABLE receipt_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id  UUID REFERENCES transactions(id),
  sku_name        TEXT NOT NULL,              -- "حليب المراعي كامل الدسم"
  quantity        NUMERIC(10,2) DEFAULT 1,
  unit_price_sar  NUMERIC(10,2) NOT NULL,
  total_price_sar NUMERIC(10,2) NOT NULL
);
```

**Purpose:** OCR extracts line items from receipts. This is the B2B data goldmine. **NOT in MVP.** Added when OCR line-item extraction is ready.

---

## Full Schema Diagram

```
┌─────────────────┐
│  transactions   │
│                 │
│ session_id ─────┼───┐
│ amount_sar      │   │
│ category (TEXT) │   │    ┌─────────────────┐
│ merchant        │   │    │  commitments    │
│ tx_date         │   │    │                 │
│ group_id ───────┼───┤    │ session_id      │
│ is_deleted      │   │    │ name            │
└────────┬────────┘   │    │ monthly_amount  │
         │            │    │ remaining       │
         │ 1:N        │    │ is_active       │
         ▼            │    └─────────────────┘
┌─────────────────┐   │
│ receipt_items   │   │    ┌─────────────────┐
│ (POST-MVP)      │   │    │     goals       │
│                 │   │    │                 │
│ transaction_id  │   │    │ session_id      │
│ sku_name        │   │    │ target_amount   │
│ quantity        │   │    │ monthly_save    │
│ unit_price_sar  │   │    │ current_saved   │
└─────────────────┘   │    │ is_active       │
                      │    └─────────────────┘
                      │
         ┌────────────┘
         │
    SharedPreferences (on-device)
    • monthly_income_sar
    • monthly_commitments_sar (simple sum)
    • days_to_salary
```

---

## User Data Strategy (Updated)

| Data | MVP Storage | Growth Phase |
|------|------------|-------------|
| Transactions | Supabase | Same |
| Commitments (detailed) | Supabase `commitments` | Same |
| Savings Goals | Supabase `goals` | Same |
| Income | SharedPreferences | → Supabase (encrypted) |
| Simple commitments sum | SharedPreferences | → Derived from `commitments` table |
| Days to salary | SharedPreferences | → Supabase |

**Privacy:** All cloud tables use `session_id` only. No PII. No name, email, phone, national ID. B2B data is aggregated across 100+ users per bucket, fully anonymized.

---

## Key Queries (New)

### 7. Active Commitments Sum
```sql
SELECT COALESCE(SUM(monthly_amount), 0) AS total_commitments
FROM commitments
WHERE session_id = $1 AND is_active = TRUE;
```

### 8. Active Goals Progress
```sql
SELECT name, target_amount, current_saved, monthly_save,
       ROUND(current_saved / target_amount * 100, 1) AS progress_pct
FROM goals
WHERE session_id = $1 AND is_active = TRUE;
```

### 9. Compound Transaction Group
```sql
SELECT * FROM transactions
WHERE group_id = $1 AND is_deleted = FALSE
ORDER BY created_at;
```

### 10. Goal Impact on Purchase
```
Used by "Can I buy?" calculator:
  If user has active goals:
    effective_commitments = commitments + SUM(goals.monthly_save)
    Then recalculate affordability.
```

---

## Migration Path (Post-Hackathon)

When you add login/accounts later:
- Add `user_id` to all tables (nullable, alongside `session_id`)
- Guest users stay on `session_id`
- Logged-in users get `user_id` populated
- B2B data remains anonymized regardless
