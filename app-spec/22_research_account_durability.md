# Research — Account Durability & Backups (Phase 0)

> **Provenance.** A Fable-model deep-research consult (2026-07-18), grounded in
> direct reads of the repo (`CLAUDE.md`, `START_HERE.md`, DEC-017, DEC-010,
> `auth_service.dart`, `signup_screen.dart`, `main.dart`, `pubspec.lock`,
> `supabase/migrations/`) and verified against **live Supabase documentation**
> fetched that day. Every load-bearing claim carries its source URL; anything
> that could **not** be verified against official docs is marked explicitly.
>
> This operationalizes `21_personal_build_plan.md` §"The single most urgent
> action" and Phase 0. When this and the code disagree, trust the code and a
> live check, per the project's rule 3.

## Headline

**The conversion code that ships today is the officially-correct mechanism.**
`AuthService.upgradeAnonymousToEmail()` already calls
`updateUser(UserAttributes(email:, password:, data:))` — and `updateUser()` is
*still* the documented 2026 path for converting an anonymous user to a permanent
one while preserving the **same auth UUID**. So Phase 0 durability is **not a
rewrite** — it is *execute + verify against the real DB + back up*. Two sharp
edges need handling: the email-confirmation posture, and a backup gap that
silently produces an unrestorable "backup".

## Grounding facts (repo, today)

- `supabase_flutter` **2.16.0** resolved (`gotrue` 2.26.0); pubspec `^2.3.0`.
- `AuthService.upgradeAnonymousToEmail()` does the conversion in one call, with a
  documented prerequisite: dashboard **Confirm email = OFF** (autoconfirm).
  `SignUpScreen` guards `!isAnonymous` and maps `email_exists` /
  `user_already_exists` to Arabic. `LoginScreen`'s doc-comment already knows that
  signing in *over* an anonymous session orphans its data.
- **Only one migration file** exists (`20260713000000_financial_profile.sql`)
  while INIT-03 defines 5+ tables → most of the remote schema is **not captured
  in migrations**. This is a hidden dependency for Phase 0.5 (see §Migration
  discipline).

## Recommended plan (concrete, ordered)

### Step 0 — one manual backup BEFORE touching auth

Never modify the founder's `auth.users` row without a restorable copy in hand.
Use the **session-pooler** connection string (IPv4-safe), from Dashboard →
Connect → Session pooler.

```bash
supabase db dump --db-url "$DB_URL" -f roles.sql  --role-only
supabase db dump --db-url "$DB_URL" -f schema.sql
supabase db dump --db-url "$DB_URL" -f data.sql   --data-only --use-copy
# CRITICAL: auth schema is EXCLUDED by default — without it a restore loses the
# founder's auth.users row that every user_id FK points at:
supabase db dump --db-url "$DB_URL" -f auth.sql   --data-only --use-copy -s auth
```

Verified: `supabase db dump` runs pg_dump in a container that **excludes Supabase
managed schemas (auth, storage, extensions)** by default; `-s/--schema` includes
them explicitly. (https://supabase.com/docs/reference/cli/supabase-db-dump) Also
record the founder's UUID in plaintext somewhere safe — it's the join key for
everything.

### Step 1 — convert the account (code exists; this is an ops decision + a device run)

**Mechanism (verified):** for email/password the official conversion path for an
anonymous user is `updateUser()`; `linkIdentity()` is the OAuth path. Both operate
on the *currently signed-in* user — the UUID never changes; conversion = the same
`auth.users` row gains an email identity and `is_anonymous` flips to false.
(https://supabase.com/docs/guides/auth/auth-anonymous#convert-an-anonymous-user-to-a-permanent-user)

**Confirmation posture (the sharp edge).** Official docs describe the
confirmation-ON flow: `updateUser({email})` → verify via emailed link **or 6-digit
OTP** → *then* `updateUser({password})` ("to add a password … the email or phone
needs to be verified first"). The repo's single-call `email+password+data`
variant is valid **only because** Confirm-email-OFF makes the email immediately
verified. That equivalence is **not stated verbatim in official docs** — it is
proven in-project on device (DEC-044). Flagged.

**Least-risk path for a one-time, single-user event:**
1. Dashboard → Auth → Email → **Confirm email OFF** (temporarily). Also disable
   **Secure email change** if on (it emails both current+new; the anonymous user
   has no current email). (https://supabase.com/docs/reference/dart/auth-updateuser)
2. On the founder's **real device**, run the existing (device-verified) SignUp
   screen with his real email + a strong password.
3. Verify against the **real database**:
   ```sql
   select id, email, is_anonymous, encrypted_password is not null as has_pw,
          email_confirmed_at
   from auth.users where id = '<founder-uuid>';
   select provider from auth.identities where user_id = '<founder-uuid>';
   -- expect: same UUID, is_anonymous=false, has_pw=true, provider='email'
   select count(*) from public.transactions where user_id = '<founder-uuid>';
   -- expect: unchanged count (nothing migrated, nothing orphaned)
   ```
4. **Prove recoverability, not just conversion:** on the device, sign out, then
   `signInWithPassword` with the new credentials; confirm the same UUID and full
   history render. This is the actual durability guarantee — do not skip it.
5. Re-enable **Confirm email ON** afterwards — the app is a public APK;
   autoconfirm lets anyone register an email they don't own.

Do **not** use `linkIdentity()` here — it's OAuth-only
(`linkIdentity(OAuthProvider.google)` / `linkIdentityWithIdToken()`) and needs the
manual-linking beta toggle. Keep it for adding Google sign-in later; paths compose
(`updateUser({password})` can add a password to an OAuth account too).
(https://supabase.com/docs/guides/auth/auth-identity-linking)

**Conflict (email already registered):** `updateUser` fails `email_exists`-class;
official pattern is catch → `signInWithPassword` to the existing account →
reassign rows (`update … set user_id = …`, an UPDATE, so DEC-010-safe). Non-
scenario for the founder's fresh email; `arabicAuthError()` already maps it.
(https://supabase.com/docs/guides/auth/auth-anonymous#resolving-identity-conflicts)

### Step 2 — automated backups (the cheap, sustainable path)

**Plan-tier facts (verified, https://supabase.com/docs/guides/platform/backups):**

| Option | Availability | Cost | Retention |
|---|---|---|---|
| Daily automatic backups | Pro / Team / Enterprise | included | 7 / 14 / 30 days |
| PITR (WAL, ~2-min RPO) | Pro+ add-on, needs ≥ Small compute; replaces daily | **~$100/mo** (7d) → $400 (28d) | 7–28 days |
| Free plan | **no automatic backups** — docs say export via CLI `db dump` and keep off-site | $0 | n/a |

**Recommendation: scheduled `supabase db dump` via GitHub Actions cron, age-
encrypted, to a private repo — the always-on baseline regardless of plan.** PITR
is overkill (~$100/mo + compute add-on) for an app whose write rate is a handful
of chat-logged transactions/day; a nightly dump's 24h RPO ≈ one day of logs,
trivially re-enterable. If on Pro, the built-in 7-day daily backups become a free
second layer; the GH-Actions dump is the layer the founder *owns* (survives
project deletion — docs warn deleting a project destroys its hosted backups).

Workflow — official template
(https://supabase.com/docs/guides/deployment/ci/backups) with **three load-bearing
corrections**:

1. **Connection string must be the shared-pooler *session mode* URL**
   (`aws-<region>.pooler.supabase.com:5432`), NOT the template's
   `db.<ref>.supabase.co:5432` — the direct endpoint is **IPv6-only** without the
   IPv4 add-on, and GitHub runners are IPv4-only.
   (https://supabase.com/docs/guides/database/connecting-to-postgres)
2. **Add the `-s auth` dump** — else the backup can't restore the `auth.users` row
   all FKs reference.
3. **Encrypt before commit** (`age` public key; secret key stays offline) — this
   is real personal financial data. $0 (private repo + Actions free tier).

```yaml
name: azdal-db-backup
on:
  workflow_dispatch:
  schedule: [{ cron: '0 1 * * *' }]   # 01:00 UTC = 04:00 KSA
jobs:
  backup:
    runs-on: ubuntu-latest
    permissions: { contents: write }
    env: { DB_URL: "${{ secrets.SUPABASE_DB_URL }}" }   # session-pooler string
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with: { version: latest }
      - run: supabase db dump --db-url "$DB_URL" -f backups/roles.sql  --role-only
      - run: supabase db dump --db-url "$DB_URL" -f backups/schema.sql
      - run: supabase db dump --db-url "$DB_URL" -f backups/data.sql   --data-only --use-copy
      - run: supabase db dump --db-url "$DB_URL" -f backups/auth.sql   --data-only --use-copy -s auth
      - name: Encrypt (age)
        run: |
          for f in backups/*.sql; do
            age -r "${{ secrets.AGE_PUBLIC_KEY }}" -o "$f.age" "$f" && rm "$f"
          done
      - uses: stefanzweifel/git-auto-commit-action@v5
        with: { commit_message: "Azdal DB backup" }
```

**Restore drill (non-negotiable — rule 3 applied to backups):** a backup never
restored is a hypothesis. Once, soon: `supabase start` locally (or a scratch
project) → `psql` the roles/schema/auth/data files **in that order** → row-count
spot-check vs production. Honor the db-dump restore caveat:
`ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon,
authenticated;` before restoring schema into a fresh project. Note: hosted daily
backups don't store custom-role passwords, and Storage objects (receipt images)
are **not** in DB backups — metadata only.

### Migration discipline going forward (verified: https://supabase.com/docs/guides/deployment/database-migrations)

One migration file vs ~6 tables of remote schema = local/remote already drifted —
exactly the state that turns a future `db push` into sync errors.

1. **Baseline now:** `supabase link` → `supabase db pull` snapshots the remote
   schema into a migration; commit it. This is a **prerequisite** the Phase 0.5
   router's schema changes silently depend on.
2. **Golden rule (verbatim): never change the remote DB directly.** Every change:
   `supabase migration new` → additive SQL → `supabase db reset` locally → `db
   push`.
3. "Additive, reversible" maps onto DEC-010: migrations never `DROP` user-data
   columns — deprecate and stop reading.
4. Drift recovery: `migration list` → `db pull` → `migration repair --status
   applied|reverted <ts>` (fixes the history table only, runs no SQL).
5. The nightly `schema.sql` doubles as drift detection.

## Alternatives considered (honest tradeoffs)

| Alternative | Verdict | Why |
|---|---|---|
| **Two-step confirmed flow** (Confirm-email ON; `updateUser(email)` → OTP `verifyOTP(type: emailChange)` → `updateUser(password)`) | Right *eventual* answer for public users; overkill for Phase 0 | It's the documented flow and never weakens project-wide security, but needs new UI + email templates, and built-in SMTP allows only **2 emails/hour project-wide** on `/auth/v1/user`. Do it in Phase 1 with custom SMTP; don't block Phase 0. (https://supabase.com/docs/guides/auth/rate-limits) |
| `linkIdentity()` (Google OAuth) | Defer | Needs manual-linking beta + provider config + native `linkIdentityWithIdToken`. Good Phase-1+ addition on the same UUID. |
| `signUp()` while anonymous | **Rejected** | Creates a **new** UUID and replaces the session — orphans the anonymous data. Exactly the failure DEC-017 exists to avoid. The code correctly does not do this. |
| PITR add-on | Rejected for now | ~$100/mo + Small-compute prerequisite, *replaces* daily backups; protects an intra-day-disaster loss mode Azdal doesn't have. Revisit only if Tier-2 stakes change. |
| Pro daily backups only (no GH Actions) | Insufficient alone | 7-day retention, and hosted backups die with the project. Fine as a *second* layer, never the only one. |
| Raw `pg_dump` (no CLI) | Works, not preferred | CLI pins a compatible pg_dump and handles managed-schema exclusion; raw risks version mismatch. |

## Verified vs. unverified

**Verified against current docs:** `updateUser` conversion path & UUID
preservation; verified-before-password ordering; `linkIdentity`/`linkIdentityWithIdToken`
OAuth-only + manual-linking toggle; anonymous sign-in 30/hr/IP and email
endpoints 2/hr on built-in SMTP; backup tiers/prices/retention + project-deletion
warning; `db dump` flags + restore privilege caveat; GH Actions template;
direct-connection IPv6-only vs pooler IPv4; full migration CLI workflow. (URLs
inline above.)

**Could NOT verify (explicit):**
1. That single-call `updateUser(email+password)` with Confirm-email-OFF completes
   atomically with the email treated as verified — strongly implied, **proven
   in-project on device (DEC-044)**, no official sentence states it.
2. Exact timing of the `is_anonymous` flip in the **JWT claim** (likely stays
   `true` until next token refresh). Harmless today (no RLS reads it); verify
   before writing one that does.
3. Whether the manual-linking toggle gates the `updateUser` email path or only
   `linkIdentity` (shipped flow worked → likely only `linkIdentity`). Enabling it
   is harmless.
4. Current Pro price (~$25/mo, from memory) and GH Actions free-tier limits.
5. Clean restorability of the `-s auth` data dump into a fresh project — the
   restore drill answers this.

## Pitfalls & avoidance

1. **Login-over-anonymous orphans data** — convert on the device holding the
   anonymous session; the session *is* the account until conversion.
2. **The docs' anonymous-cleanup SQL is a hard delete** (`delete from auth.users
   where is_anonymous …`) — would cascade-delete real rows, violating DEC-010.
   Never run verbatim.
3. **Backup without `-s auth` is a false backup** — the single most likely silent
   failure in the whole phase.
4. **Template's direct-connection URL fails from GH Actions (IPv6)** — use the
   session-pooler string; it embeds the DB password, keep it only in GH secrets.
5. **Confirm-email-OFF left on permanently** = anyone can claim any email on the
   public APK. Toggle off → convert → toggle back on.
6. **2 emails/hour project-wide** on built-in SMTP — any confirmation-ON flow
   needs custom SMTP first.
7. **Anonymous sign-in abuse** (30/hr/IP, rows forever) — consider CAPTCHA/Turnstile
   eventually; low urgency for a personal build.
8. **RLS `is_anonymous` gotcha (future)** — stale JWT claim can lock out a just-
   converted user mid-session; remember before adding such a policy.
9. **Schema-drift resurrection** — baseline (`db pull`) before any future `db
   push`.
10. **Hosted backups die with the project/account** — the self-owned encrypted
    dump repo is the hedge; drill "restore to a new project" once.

## Fit to Azdal's constraints

- **No hard delete (DEC-010):** untouched — conversion is an UPDATE; backups are
  read-only; the only delete in sight is the docs' cleanup recipe, flagged
  forbidden.
- **Same-UUID in-place upgrade (DEC-017):** `updateUser` is exactly DEC-017's
  promised mechanism, and still the official one in 2026.
- **Device-verified against the real DB (rule 3):** acceptance = SQL checks on
  prod + a sign-out/sign-in round-trip on the device + a restore drill.
- **Sustainability:** the recommended stack is $0/mo (GH private repo + Actions +
  age), degrades gracefully (add Pro for a second layer; PITR only if stakes
  change).

## Open questions (need the founder or a live check)

1. **Which Supabase plan?** Decides whether daily hosted backups exist. (Supabase
   MCP `get_project` can answer live.)
2. **Dashboard state:** Confirm-email already OFF? manual linking enabled?
   anonymous rate limit default?
3. **Is the founder's anonymous session still alive on his device?** If the app
   was cleared post-hackathon, the account may already be unreachable — check
   `auth.users` for his `is_anonymous=true` row and `last_sign_in_at` **before**
   planning anything. *(This is the sharpest de-risking check.)*
4. Where does the encrypted backup repo live (same vs separate GitHub account for
   blast-radius isolation)? Where is the `age` secret key stored offline?
5. Pro upgrade now (~$25/mo) as a second layer, or GH-Actions-only for now?
6. Confirm the real account email and that phone-in-metadata (real SMS OTP still
   deferred) is acceptable.

## Related
- `21_personal_build_plan.md` (Phase 0), DEC-017, DEC-010, DEC-044
- `23_research_tool_calling_router.md` (the Phase 0.5 companion consult)
