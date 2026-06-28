# Azdal — Data Model (ERD)

> **Status:** Draft — Populated during Stage 1 implementation  
> **Source:** Synthesized from `docs/archive/er-diagram.md`

---

## Core Entities (Hackathon MVP)

### 1. transactions

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK, DEFAULT gen_random_uuid() | Unique identifier |
| user_id | uuid | FK → auth.users, NOT NULL | Owner |
| amount | numeric(10,2) | NOT NULL, > 0 | Transaction amount in SAR |
| category | text | NOT NULL | AI-classified category |
| subcategory | text | NULL | AI-classified subcategory |
| description | text | NULL | User-provided description |
| type | text | NOT NULL, DEFAULT 'expense' | 'income' or 'expense' |
| tone | text | NOT NULL, DEFAULT 'gray' | 'green', 'gray', 'red' |
| receipt_url | text | NULL | Supabase Storage URL |
| receipt_items | jsonb | NULL | OCR-extracted line items |
| group_id | uuid | NULL | FK → transactions.id for compound splits |
| is_commitment | boolean | DEFAULT false | Part of recurring commitment |
| commitment_id | uuid | NULL | FK → commitments.id |
| is_deleted | boolean | DEFAULT false | Anti-ghost protocol |
| deleted_at | timestamptz | NULL | Soft delete timestamp |
| created_at | timestamptz | DEFAULT now() | |
| updated_at | timestamptz | DEFAULT now() | |

**Indexes:**
- `idx_transactions_user_date` on (user_id, created_at)
- `idx_transactions_group` on (group_id)
- `idx_transactions_tone` on (user_id, tone)

---

### 2. commitments

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_id | uuid | FK → auth.users, NOT NULL |
| name | text | NOT NULL | "تابي — جوال", "إيجار" |
| provider | text | NULL | "تمارا", "بنك" |
| total_amount | numeric(10,2) | NOT NULL | Original commitment amount |
| remaining | numeric(10,2) | NOT NULL | Remaining to pay |
| monthly_amount | numeric(10,2) | NOT NULL | Monthly installment |
| type | text | NOT NULL | 'bnpl', 'rent', 'loan', 'subscription' |
| status | text | DEFAULT 'active' | 'active', 'paused', 'completed' |
| url | text | NULL | Link to BNPL provider/app |
| is_deleted | boolean | DEFAULT false | |
| created_at | timestamptz | DEFAULT now() | |

---

### 3. goals

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_id | uuid | FK → auth.users, NOT NULL |
| name | text | NOT NULL | "صندوق الطوارئ", "عمرة" |
| target_amount | numeric(10,2) | NOT NULL | Goal target in SAR |
| current_amount | numeric(10,2) | DEFAULT 0 | Current savings |
| monthly_contribution | numeric(10,2) | NOT NULL | Target monthly saving |
| priority | int | DEFAULT 1 | Order for Debt Avalanche |
| status | text | DEFAULT 'active' | 'active', 'paused', 'achieved' |
| achieved_at | timestamptz | NULL | Completion timestamp |
| is_deleted | boolean | DEFAULT false | |
| created_at | timestamptz | DEFAULT now() | |

---

### 4. integrity_scores

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_id | uuid | FK, UNIQUE | One score per user |
| score | int | NOT NULL, CHECK 0-100 | Current Integrity Score |
| logging_consistency | numeric(5,2) | | Days with transaction / total days |
| receipt_upload_rate | numeric(5,2) | | Receipts uploaded vs gray flagged |
| data_match_accuracy | numeric(5,2) | | User input vs bank ground truth |
| response_time_factor | numeric(5,2) | | Speed of evening check-in |
| no_deletion_rate | numeric(5,2) | | Transactions not deleted |
| calculated_at | timestamptz | DEFAULT now() | |

---

### 5. purchase_decisions (cache/audit)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_id | uuid | FK |
| query | text | NOT NULL | What user asked ("جوال بـ ٣٠٠٠") |
| verdict | text | NOT NULL | 'yes', 'wait', 'no' |
| disposable_income | numeric(10,2) | | Calculated at time of query |
| goal_impact | jsonb | NULL | Which goals affected, by how much |
| explanation | text | NOT NULL | Arabic explanation shown to user |
| created_at | timestamptz | DEFAULT now() | |

---

## Entity Relationships

```
auth.users (1) ───────── (N) transactions
auth.users (1) ───────── (N) commitments
auth.users (1) ───────── (N) goals
auth.users (1) ───────── (1) integrity_scores
auth.users (1) ───────── (N) purchase_decisions

transactions.commitment_id ── (N:1) ── commitments.id
transactions.group_id ── (N:1) ── transactions.id (self-referencing)
```

---

## Additional Tables (Post-MVP, Future Phases)

### Phase 2 — behavioral_credit_scores

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_hash | text | NOT NULL | Anonymized user identifier |
| score | int | 0-100 | Behavioral credit score |
| tier | text | | 'platinum', 'gold', 'silver', 'bronze' |
| confidence | numeric(3,2) | 0-1 | Data completeness |
| factors | jsonb | | DTI, impulse freq, savings rate |
| calculated_at | timestamptz | | |

### Phase 3 — loans

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK |
| user_id | uuid | FK |
| amount | numeric(10,2) | | Loan principal |
| murabaha_margin | numeric(10,2) | | Islamic profit margin |
| term_months | int | | Installment duration |
| status | text | | 'active', 'paid', 'defaulted' |
| approved_at | timestamptz | | |

---

## Database Rules

| Rule | Enforcement |
|------|-------------|
| Anti-ghost | is_deleted flag, NEVER physical delete |
| RLS | All tables have RLS: user sees own rows only |
| Soft delete | UPDATE SET is_deleted=true, deleted_at=now() |
| Audit trail | All mutations logged (created_at, updated_at) |
| Transaction ACID | Edge Functions wrap multi-table changes in transactions |
| Amount validation | Amount > 0 always |
| Integrity score range | CHECK 0-100 |

---

## Related
- `07_flutter_architecture.md` — Layer architecture
- `17_data_architecture_acid_constraints.md` — ACID rules
- `08_security_privacy.md` — RLS and data protection
