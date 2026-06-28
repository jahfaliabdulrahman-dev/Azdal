# Gemini's Technical Proposal — Red Team Critique

> **Date:** 2026-05-19
> **Critique by:** Sulaiman (Hermes)
> **Verdict:** 60% correct, 40% wrong/dangerous — do NOT implement as-is

---

## Summary

Gemini produced a comprehensive technical proposal including code, DDL schema, Python pipeline, and OCR engine. But it **built a different system** than what we agreed on. Key divergences:

- Used its own category dictionary (6 categories instead of our 13)
- Reintroduced `user_profiles` table (we removed it)
- Added CASCADE DELETE (catastrophic for financial data)
- Used an oversimplified "Can I buy?" formula
- Inflated API costs by ~44x

---

## What Was WRONG

### 1. Category Dictionary — Fatal Divergence

| Gemini Used | Our Approved Dictionary |
|-------------|------------------------|
| المطاعم | سكن, مواصلات, طعام, قهوة, تسوق, صحة, تعليم, فواتير, ترفيه, اشتراكات, سفر, صدقة/زكاة, أخرى |
| السوبرماركت | |
| الفواتير | |
| الترفيه | |
| النقل | |
| أخرى | |

Gemini collapsed 13 specific Saudi categories into 6 vague ones. This breaks:
- DB CHECK constraint
- Transaction classification
- Monthly analytics
- Prompt engineering

**Never use Gemini's category list. Our 13-category dictionary is locked.**

### 2. `user_profiles` Table — Reversal of Architecture Decision

We EXPLICITLY decided:
- No profiles table
- `session_id` directly in transactions
- Guest-first, no registration
- Income/commitments in SharedPreferences

Gemini ignored this and added:
```sql
CREATE TABLE public.user_profiles (
    profile_id UUID PRIMARY KEY,
    monthly_income NUMERIC(12, 2),
    ...
);
```

This adds unnecessary complexity to MVP. We don't need it.

### 3. CASCADE DELETE — Catastrophic

```sql
CONSTRAINT fk_user_profile FOREIGN KEY (profile_id) 
    REFERENCES public.user_profiles (profile_id) ON DELETE CASCADE
```

This means: delete a profile → ALL transactions are permanently destroyed. No confirmation. No soft delete. No recovery possible.

This directly contradicts our Anti-Ghost protocol (soft delete only). **This is the most dangerous line in Gemini's entire proposal.**

### 4. "Can I Buy?" Formula — Oversimplified

**Gemini's formula:**
```
Dpre = Income - Commitments - MonthSpend
Dpost = Dpre - Price
Decision: Dpost >= 0 ? YES : NO
```

**Missing from Gemini's formula:**
- `days_to_salary` — critical for predicting remaining spend
- Safety buffer (250 SAR minimum)
- Daily spend rate projection
- Goal impact (active savings goals)
- Recurring commitment awareness

**Our formula (correct):**
```
daily_spend_rate = month_spend / days_elapsed
predicted_spend = daily_spend_rate * days_to_salary
expected_remaining = disposable - predicted_spend
remaining_after = expected_remaining - item_price
safety_buffer = max(250, income * 0.05)

remaining_after >= safety_buffer → YES ✅
expected_remaining >= safety_buffer → WAIT ⚠️
expected_remaining < safety_buffer → NO ❌
```

### 5. API Cost Projections — Grossly Inflated

| Gemini's Claim | Reality |
|---------------|---------|
| 50,000 users = $75,000/month | 50,000 users = ~$1,700/month |
| 281,000 SAR monthly | ~6,400 SAR monthly |

**Why Gemini is wrong:**
- Assumed every call uses most expensive model at max tokens
- Ignored Flash routing (80% of queries)
- Ignored DeepSeek V3 fallback (5x cheaper)
- Ignored semantic caching

### 6. Python Code Bugs

**Bug 1: Unicode character in code**
```python
.not_陰(pl.lit('أخرى'))  # ← Chinese character leaked in
```
Should be: `.otherwise(pl.lit('أخرى'))`

**Bug 2: Arbitrary Cold Start defaults**
```python
monthly_income = 10000.00  # Where does this come from?
fixed_commitments = 3000.00
```
No Saudi statistical source. These are made-up numbers.

**Bug 3: Polars overkill**
Using Polars LazyFrames for 6 records is like using a tank to kill a fly. MVP processes one transaction at a time.

### 7. PDPL/SMS Concerns — Correct But Out of Scope

Gemini raised valid concerns about READ_SMS permissions and PDPL data sovereignty. But:
- SMS parsing is NOT in MVP scope (future vision only)
- Data minimization is already in architecture
- These concerns belong in the Pitch Q&A, not the MVP build

---

## What Was RIGHT

| Gemini's Point | Our Assessment |
|---------------|----------------|
| GenUI Beta risk | ✅ Agreed. We already have Plan B (native Flutter widgets). |
| Pre-caching UI schemas for demo | ✅ Good idea. Cache 3 static schemas as fallback. |
| LLM never calculates — Python/SQL only | ✅ Core architecture principle. Always enforced. |
| Mathematical verification of OCR totals | ✅ Excellent. Sum line items, compare to extracted total. Flag mismatch. |
| Cold Start Intelligence in code | ✅ Correct principle. Progressive estimation. |
| Soft delete importance | ✅ Correct principle — but he violated it with CASCADE. |

---

## What to KEEP from Gemini

1. **Pre-caching idea:** Cache 3 static GenUI schemas for instant demo fallback
2. **OCR mathematical verification:** `sum(items) == extracted_total` check
3. **Cold Start fallback in simulator code:** Good pattern, use with correct Saudi defaults

## What to DISCARD from Gemini

1. ❌ Category dictionary (use our 13 categories)
2. ❌ `user_profiles` table (we don't need it)
3. ❌ CASCADE DELETE (use soft delete ONLY)
4. ❌ Simplified "Can I buy?" formula (use ours with days_to_salary + safety buffer)
5. ❌ API cost projections (grossly inflated)
6. ❌ Python code with bugs (rewrite, don't copy-paste)
7. ❌ Polars/EDA pipeline (overkill for MVP)

---

## Verdict

Gemini's proposal is a **different system** than what we designed over 3 sessions of analysis. It's well-written technically, but diverges from our locked architecture in dangerous ways.

**Never implement Gemini's output without filtering through our agreed architecture.**

The locked architecture stands:
- transactions + commitments + goals tables
- session_id only, no profiles
- 13 fixed categories
- Soft delete only
- Our "Can I buy?" formula with safety buffer
- Guest-first, SharedPreferences for income
