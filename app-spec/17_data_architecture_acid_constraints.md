# Azdal — Data Architecture & ACID Constraints

> **Status:** Draft — rules captured from Financial Knowledge Layer and product requirements  
> **Source:** Synthesized from `docs/research/financial-knowledge-layer.md` and architecture decisions

---

## 1. ACID Principle Application

### Atomicity

| Operation | Scope | Implementation |
|-----------|-------|----------------|
| "Can I buy?" calculation | Read-only (multiple tables) | Single Edge Function transaction |
| Transaction entry + Integrity Score update | Multi-table write | Supabase transaction block |
| Compound transaction split | Transactions + group relationship | All-or-nothing insert |
| Goal creation | Single table | Standard insert |
| Commitment creation + immediate "Can I buy?" impact | Multi-table | Bundled in Edge Function |

### Consistency

| Constraint | Enforcement |
|-----------|-------------|
| Transaction amount > 0 | Check constraint on DB column |
| Integrity Score 0-100 | Check constraint |
| Goal target > current | Application logic + DB constraint |
| Commitment remaining ≥ 0 | Application logic |
| No orphaned group_id references | FK with CASCADE SET NULL |
| No orphaned commitment_id references | FK with CASCADE SET NULL |

### Isolation

| Scenario | Level | Rationale |
|----------|-------|-----------|
| User entering transaction while "Can I buy?" runs | READ COMMITTED | Prevents stale data in purchase decision |
| Two simultaneous transaction entries | SERIALIZABLE | Prevents double-counting |
| Integrity Score recalculation | READ COMMITTED | Snapshot at calculation time |

### Durability

| Strategy | Implementation |
|----------|---------------|
| Write-ahead logging | PostgreSQL WAL (built-in) |
| Point-in-time recovery | Supabase PITR (enabled at Pro) |
| Backup frequency | Daily automated (Supabase managed) |

---

## 2. Financial Calculation Rules

**Source:** Financial Knowledge Layer — `hard_rules` section

### Rule: 50/30/20 Budget

```
Needs: 50% of income (housing, utilities, groceries)
Wants: 30% (restaurants, entertainment, shopping)
Savings/Debt: 20% (emergency fund, debt repayment)
```

Enforced in AI recommendations, NOT as hard block — user autonomy preserved.

### Rule: Emergency Fund

```
3-6 months of essential expenses
First milestone: 1,000 SAR (Phase 3 — Liberation)
Full milestone: 3 months (Phase 4 — Growth)
```

### Rule: Debt-to-Income (DTI)

```
Maximum DTI: 33% of monthly income
Applied to "Can I buy?" engine
If DTI > 33% → verdict: NO (with explanation)
```

### Rule: Debt Avalanche Priority

```
1. High-interest consumption debt (credit cards, BNPL)
2. Moderate-interest loans  
3. Low-interest debt (mortgage, education)
Use remaining → emergency fund → investment
```

---

## 3. Anti-Ghost Protocol (No Hard Delete)

| Table | Implementation |
|-------|---------------|
| transactions | `is_deleted BOOLEAN DEFAULT false`, `deleted_at TIMESTAMPTZ` |
| commitments | Same |
| goals | Same |
| purchase_decisions | Audit table — never deleted |

**Rules:**
- Physical deletion only through approved retention workflows
- Requires Lead Architect approval
- Must be audit logged

---

## 4. Idempotency Rules

| Operation | Idempotency Key | Strategy |
|-----------|----------------|----------|
| Transaction creation | (user_id, amount, created_at, md5(description)) | Deduplicate by natural key within 60s window |
| Integrity Score update | user_id | Last-write-wins with version check |
| "Can I buy?" query | (user_id, query_hash) | Cache result for 5 minutes |

---

## 5. Data Retention Policy

| Data Type | Retention | After |
|-----------|----------|-------|
| Active user transactions | Forever (soft delete) | User deactivates → soft delete all, retain 1 year |
| Receipt images | 1 year | Auto-purge after 1 year |
| Chat history | While active | Delete 30 days after deactivation |
| Behavioral Score | Anonymized, retained | Even after user deactivation (B2B scoring history) |
| Audit logs | 7 years | Regulatory requirement (PDPL) |

---

## 6. Transaction Boundaries (DEC-034 Pattern)

**Rule 7:** Repositories own transaction boundaries — no nested writeTxn.

```dart
// WRONG — nested transactions
await isar.writeTxn(() async {
  await transactionRepo.save(txn);  // This also calls writeTxn internally
});

// RIGHT — single transaction boundary
await transactionRepo.saveWithIntegrityUpdate(txn, score);
```

---

## 7. Related
- `05_data_model_erd.md` — Complete database schema
- `08_security_privacy.md` — Row Level Security
- `07_flutter_architecture.md` — Hybrid verification architecture
- `docs/research/financial-knowledge-layer.md` — Full financial rules engine
