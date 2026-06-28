# Azdal — Security & Privacy

> **Status:** Locked  
> **Source:** Synthesized from `docs/archive/gemini-critique.md`, `docs/archive/technical-architecture-original.md` PDPL section

---

## 1. PDPL Compliance (Saudi Personal Data Protection Law)

| Principle | Implementation |
|-----------|---------------|
| **Consent** | Explicit opt-in for cloud sync. Guest-first = on-device default. |
| **Purpose limitation** | Data used ONLY for financial coaching. B2B behavioral scores = anonymized. |
| **Data minimization** | Collect only what's needed. No national IDs. No bank account numbers. |
| **Accuracy** | User can correct any transaction. Edits logged, not overwritten. |
| **Storage limitation** | Data retained while user is active. Right to delete = soft delete only (anti-ghost). |
| **Security** | Encryption at rest (Supabase) + in transit (TLS). RLS on all tables. |
| **Accountability** | Full audit trail. All mutations logged with timestamps. |

---

## 2. Data Classification

| Data Type | Sensitivity | Storage | Sharing |
|-----------|------------|---------|---------|
| Chat messages | Medium | Supabase (if opted in) | Never shared |
| Transaction amounts | Medium | Supabase | Anonymized for B2B scoring |
| Receipt line items | Medium | Supabase Storage | Never shared |
| Voice recordings | High | On-device only (transcribed, then discarded) | Never |
| Bank transaction data | High | Open Banking API (future) | Never raw |
| Behavioral Score | Medium (anonymized) | Supabase | Hashed user + score only |
| PII (name, ID) | CRITICAL | Never stored | Never |

---

## 3. Row Level Security (RLS)

All tables enforce RLS:

```sql
-- transactions RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

-- integrity_scores RLS  
CREATE POLICY "Users see own score"
  ON integrity_scores FOR SELECT
  USING (auth.uid() = user_id);

-- Behavioral scores (B2B) — anonymized
CREATE POLICY "Partners query by hash"
  ON behavioral_credit_scores FOR SELECT
  USING (true); -- hash only, no PII
```

---

## 4. API Security

| Layer | Protection |
|-------|-----------|
| Transport | TLS 1.3 only |
| Authentication | Supabase Auth JWT |
| Authorization | RLS policies |
| Rate limiting | 100 requests/minute/user |
| Input validation | Server-side schema validation |
| SQL injection | Parameterized queries (Supabase) |
| XSS | JSON escaping in widget rendering |

---

## 5. Gemini API Data Handling

| Rule | Implementation |
|------|---------------|
| Data sent to Gemini | Transaction descriptions, categories, chat messages — NOT bank data |
| Prompt engineering | System prompt injected server-side, never exposed to client |
| API key management | Environment variables, rotated quarterly |
| Cost control | Per-user daily token budget |
| Fallback | DeepSeek V3.2 if Gemini returns errors |
| Logging | Prompts logged without PII for debugging |

---

## 6. Anti-Gaming Protections

| Attack Vector | Defense |
|--------------|---------|
| Fake transactions to boost score | Hybrid verification: Open Banking ground truth |
| Delete transactions to hide bad spending | Deletion tracked → Integrity penalty |
| Multiple accounts | Device fingerprinting (future) |
| Prompt injection via chat | Strict system prompt isolation, no user prompt overrides system |

---

## 7. Hackathon Exceptions

For the hackathon MVP:
- All bank data is **mocked** (no real integration)
- Optional cloud sync — on-device storage is default
- No real PII collected — demo data only
- B2B API is a **vision slide**, not implemented

No PDPL constraints apply during the hackathon, but the architecture is designed for full production compliance.

---

## 8. Incident Response

| Event | Action |
|-------|--------|
| API key leak | Immediate rotation via Supabase secrets |
| Data breach | Notify affected users within 72 hours (PDPL) |
| Unauthorized access | Revoke tokens, audit logs, block IP |
| LLM hallucination (financial) | Flagged by rules engine, human review |

---

## Related
- `05_data_model_erd.md` — RLS policies per table
- `07_flutter_architecture.md` — Security layer architecture
- `17_data_architecture_acid_constraints.md` — ACID compliance
- `docs/business/market-research.md` — SAMA PDPL references
