# Azdal — DevOps, Release & Observability

> **Status:** Template — populated during Stage 5  
> **Last Updated:** 2026-06-29

---

## Build Flavors

| Flavor | Environment | API Base | Database | Features |
|--------|-----------|----------|----------|----------|
| dev | Development | localhost / staging | dev | Debug, all features |
| staging | Pre-release | staging API | staging | All features, no analytics |
| production | App Store / Play Store | api.azdal.app | production | All features, analytics on |

---

## CI/CD Pipeline (GitHub Actions)

```yaml
# Planned stages:
1. Lint & Format (dart format, dart analyze)
2. Unit Tests (flutter test)
3. Widget Tests (flutter test --tags=widget)
4. Build (flutter build appbundle / flutter build ipa)
5. Deploy Staging (fastlane beta)
6. Deploy Production (fastlane release — manual trigger)
```

---

## Environment Variables

| Variable | Environment | Storage |
|----------|-----------|---------|
| GEMINI_API_KEY | All | GitHub Secrets |
| SUPABASE_URL | All | Flutter config (safe public) |
| SUPABASE_ANON_KEY | All | Flutter config (safe public) |
| SUPABASE_SERVICE_KEY | Backend only | Edge Function env |

---

## Observability (Post-Hackathon)

| Tool | Purpose |
|------|---------|
| Firebase Crashlytics | Crash reporting |
| Firebase Analytics | User behavior (opt-in) |
| Supabase Logs | API errors, query performance |
| Custom metrics | "Can I buy?" success rate, Integrity Score avg |

---

## Release Gate Checklist

- [ ] All tests pass (unit + widget + integration)
- [ ] Hostile audit passed (zero-trust-red-team)
- [ ] QA validation report submitted
- [ ] No stubs in critical paths
- [ ] Decision log reviewed — no open decisions
- [ ] Traceability Matrix updated
- [ ] pubspec.yaml deps locked
- [ ] Build signed (release keys)
- [ ] App Store metadata prepared
- [ ] Lead Architect approval

---

## Rollback Plan

| Scenario | Action |
|----------|--------|
| Critical bug post-release | fastlane rollback to previous build |
| API failure | Feature flags to disable AI-dependent features, show cached data |
| Data corruption | Restore from Supabase point-in-time recovery |

---

## Related
- `07_flutter_architecture.md` — Infrastructure layer
- `09_testing_acceptance.md` — Test gates
- `18_zero_trust_red_team_audit.md` — Security audit gate
