# Azdal — Full Handoff Report for Claude

**Date:** 2026-07-12
**To:** Claude (via Abdulrahman)
**From:** Sulaiman (Lead Architect Orchestrator, Hermes)
**Project:** Azdal (أزدل — درعك المالي) — First Arabic 3-tier financial rehabilitation platform
**Repo:** `/Users/abdurrahmanjahfali/Azdal` (local only, no remote configured)
**Branch:** `main` — clean, all work committed

---

## 1. Executive Summary

Stage 1 + Stage 2 are complete and device-verified on a TECNO LJ7 (Android). The app
now has a working chat interface with Gemini AI, voice input, transaction logging to
a live Supabase PostgreSQL instance, compound transaction splitting, and Cold Start
Intelligence. All machine-verifiable exit criteria pass. Two post-implementation bugs
were found during real-device testing and fixed.

**Git log (top → bottom, latest first):**

```
5c8d113 FIX: send button not responding — _InputBar was StatelessWidget
ca84969 FIX: prevent duplicate transaction on double-tap confirm
024e783 docs: Stage 2 handoff report for Claude (comprehensive)
3ec6f50 feat(stage2): full chat UI with Gemini AI, voice input, transactions, Cold Start
315b4d2 feat: enable Anonymous Sign-ins in Supabase Auth config
22a281d ops: swarm routing decision tree (small tasks → direct)
13fb37b DEC-017 + DEC-018: RLS guest-first resolution + voice UX mic button
2c4d9d9 DEC-016: correct voice/TTS from iOS-only to cross-platform Android-first
a1a75ee fix: add missing await to expectLater in gemini_service_test
4107ba5 DEC-015: defer Isar, fail-loud Gemini assert, test update
f4342ff FULL REWORK: compile-time credentials, Isar fix, Cairo bundle, DEC-014
e240ab6 INIT-02 + INIT-03: REWORK — Gemini real ping + Supabase live deploy
```

---

## 2. Architecture

### 2.1 Stack

| Layer | Technology | Version/Detail |
|-------|-----------|----------------|
| Framework | Flutter | 3.x (Dart), Android-only for MVP |
| State | Riverpod | `^2.5.0` — StateNotifier + Provider |
| Routing | go_router | `^14.0.0` — single `'/'` → ChatScreen |
| AI | Gemini Flash | `gemini-flash-latest` via `google_generative_ai ^0.4.0` |
| Backend | Supabase | PostgreSQL, Frankfurt (`kqhyjngtquutzdvjfbnf`) |
| Auth | Supabase Anonymous | `signInAnonymously()` — guest-first, no registration |
| Voice | speech_to_text | `^7.0.0` — Android native SpeechRecognizer |
| Network detect | connectivity_plus | `^6.0.0` — offline state for input bar |
| Fonts | Cairo | Local `.ttf` files in `assets/fonts/` (4 weights) |
| Theme | Material 3, Light | Navy `#001F5E` / Cyan `#32C2FF`, RTL-only |
| CI | GitHub Actions | Lint only (`flutter analyze`), no build/test yet |

### 2.2 Deferred / Disabled Packages

| Package | Reason | When to Revisit |
|---------|--------|-----------------|
| `isar` + `isar_flutter_libs` | AGP 8.8 release build crashes (namespace) | Post-hackathon — evaluate fork or `drift` |
| `image_picker` | Stage 3 (OCR receipt scanning) | Stage 3 |
| `receive_sharing_intent` | Stage 3 (system share sheet) | Stage 3 |
| `flutter_tts` | Voice output not needed yet | Stage 3+ |

---

## 3. Credential Loading — Critical Architecture

### The Problem

On Android, `Platform.environment['KEY']` returns empty strings because app
processes do NOT inherit the developer's shell environment. This was the root
cause of INIT-02/03 false-completes early in the session — the app compiled
and ran, but connections silently failed with empty credentials.

### The Fix

**Mechanism:** Compile-time injection via `--dart-define-from-file=.env` (Flutter
native, zero new dependencies).

**In code (lib/main.dart, lib/core/services/gemini_service.dart):**
```dart
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _apiKey      = String.fromEnvironment('GEMINI_API_KEY');

// Fail loud — never silently proceed with empty credentials
assert(_supabaseUrl.isNotEmpty,
  'SUPABASE_URL is empty.\n'
  'Build with: flutter build apk --dart-define-from-file=.env');
```

**Build command:**
```bash
flutter build apk --debug --dart-define-from-file=.env
# or:
bash scripts/build_debug.sh
```

**Device proof (TECNO LJ7):**
```
adb shell run-as com.azdal.azdal cat /proc/$PID/environ → no SUPABASE/GEMINI vars
logcat: SUPABASE_URL length=40, SUPABASE_KEY length=46  → compiled in, not runtime
```

### Build Scripts

| Script | Purpose |
|--------|---------|
| `scripts/build_debug.sh` | `flutter build apk --debug --dart-define-from-file=.env` |
| `scripts/test_with_env.sh` | `flutter test --dart-define-from-file=.env` |

---

## 4. Source Tree — What Exists

```
lib/
├── main.dart                              ← Supabase init + anonymous sign-in + fail-loud
├── app/
│   ├── app_router.dart                    ← GoRouter: '/' → ChatScreen
│   ├── providers.dart                     ← geminiServiceProvider, chatProvider, txServiceProvider
│   └── theme.dart                         ← Light theme, Navy/Cyan, Cairo fontFamily
├── core/services/
│   └── gemini_service.dart                ← GeminiService: ping(), sendMessage(), system prompt
└── features/chat/
    ├── chat_screen.dart                   ← FULL IMPLEMENTATION (~990 lines)
    ├── models/chat_message.dart           ← ChatMessage (id, role, content, widget, timestamp)
    ├── providers/chat_provider.dart       ← StateNotifier<ChatState>
    ├── services/
    │   ├── transaction_service.dart       ← Supabase INSERT (single + compound split)
    │   └── voice_service.dart             ← speech_to_text wrapper (Arabic)
    └── widgets/
        ├── chat_widgets.dart              ← Bubbles, ErrorBubble, TypingIndicator, OfflineBanner
        └── widget_catalog.dart            ← 6-widget JSON→Flutter renderer

test/
├── widget_test.dart                       ← ChatScreen renders, input bar has mic+camera
├── gemini_service_test.dart               ← Instantiate, config, missing-key, live ping
└── chat_provider_test.dart                ← 10 tests: add messages, loading, errors, ID gen
```

---

## 5. Feature Inventory — What Stage 2 Delivered

### 5.1 Chat UI (CHAT-01)

- Scrollable `ListView.builder` of `ChatMessage` items
- User bubbles: `#E3E8F5` background, right-aligned (RTL), 16px radius
- Bot bubbles: `#001F5E` background, white text, left-aligned (RTL), 16px radius
- **Input bar** (4 elements, RTL layout):
  ```
  ↑ │  اكتب مصروف...    │ 🎤 📷
  ```
  - `↑` Send: Cyan circle, grays out when offline or text empty
  - Text field: rounded 24px, `TextInputAction.send`
  - `🎤` Mic: one-tap record/pulse/stop → `speech_to_text`
  - `📷` Camera: placeholder for Stage 3 OCR

### 5.2 ChatProvider — Riverpod (CHAT-02)

- `StateNotifier<ChatState>` holding `List<ChatMessage>`, `isLoading`, `error`
- Methods: `addUserMessage()`, `addBotMessage()`, `setError()`, `clearError()`
- ID generation via `_uuid()` (timestamp-based — acceptable for single-user MVP; Guardian M-1 recommends `uuid` package for production)

### 5.3 Gemini Integration (CHAT-03)

- System prompt (Saudi Arabic dialect, embedded in code):
  > "أنت أزدل — مساعد مالي ذكي سعودي. تتحدث باللهجة السعودية فقط. تصنف المعاملات (فئة/فئة فرعية/نبرة: أخضر/رمادي/أحمر). تولد واجهات من 6 أنواع... لا تحسب أبداً — الحسابات على Supabase."
- `sendMessage(userText, history)` — sends to Gemini, parses JSON widget if present, falls back to plain text
- Model: `gemini-flash-latest` (verified available via API list-models)
- **Guardian H-2:** User text is interpolated directly into classification prompt — prompt injection vector. Recommend wrapping in delimiters for production.

### 5.4 Voice Input (CHAT-04)

- `VoiceService` wrapping `speech_to_text`
- `startListening()` → mic icon pulses cyan → Arabic transcription → populates text field
- `stopListening()` → stops recognition, returns transcribed text
- User reviews transcription before sending (voice does NOT auto-send)
- Permission: `RECORD_AUDIO` (Android)
- **Device verified:** `Voice init — available=true` on TECNO LJ7

### 5.5 Transaction Entry — Supabase Write (CHAT-05)

- `TransactionService.saveTransaction({amount, category, subcategory, description, type, tone})`
- `user_id` from `supabase.auth.currentUser!.id` (anonymous UUID) → RLS policies satisfied
- Gemini classifies text → shows `action_buttons` widget: `[✅ صحيح] [🔄 تعديل]`
- On confirm → Gemini re-classifies → `INSERT INTO transactions` → success message
- **Device verified:** Transaction appeared in Supabase after manual chat input on TECNO LJ7
- **Bug found + fixed:** Double-tapping confirm created duplicate rows (see §7.1)

### 5.6 Compound Transaction Splitting (CHAT-06)

- When Gemini detects multiple items: returns `compound_split_card` JSON
- Renders split card with `+/-` adjusters per category
- On confirm: batch INSERT with shared `group_id` (UUID of first row)
- **Guardian M-2:** N+1 insert pattern (sequential `for` loop) — recommend batch insert via `insert(list)` for production

### 5.7 Cold Start Intelligence (CHAT-07)

- On first launch (no transactions in Supabase): bot sends 3-question `quick_input_form`
  1. "الدخل الشهري التقريبي" (monthly income, SAR)
  2. "الالتزامات الشهرية" (monthly commitments, SAR)
  3. "كم تصرف تقريباً بالأسبوع؟" (weekly spend, SAR)
- On submit → Gemini generates instant insight (e.g., "تصرف 73% من دخلك قبل منتصف الشهر")
- Responses saved to Supabase as transactions
- Check on startup: `SELECT count(*) FROM transactions WHERE is_deleted=false` → skip Cold Start if > 0
- **Guardian M-4:** Data loss risk if crash between bot message and DB write — recommend save-first-then-confirm pattern

---

## 6. 6-Widget Catalog

All widgets are rendered inline inside bot bubbles. Gemini sends JSON → Flutter renders
from a fixed catalog via `switch(widgetType)`. No `eval()`, no runtime code injection.

| # | Widget | JSON Key | Purpose |
|---|--------|----------|---------|
| 1 | `summary_card` | `summary_card` | Label/value rows with tone colors (green/gray/red) |
| 2 | `bar_chart` | `bar_chart` | Horizontal bar chart for category comparison |
| 3 | `action_buttons` | `action_buttons` | Pill buttons — confirm/edit user actions |
| 4 | `quick_input_form` | `quick_input_form` | Inline form with 1-2 fields (Cold Start, goals) |
| 5 | `goal_progress_card` | `goal_progress_card` | Progress bar + percentage + months remaining |
| 6 | `compound_split_card` | `compound_split_card` | Multi-item split with +/- adjusters per category |

---

## 7. Bugs Found & Fixed During Device Testing

### 7.1 Double-Tap Duplicate Transaction (ca84969)

**Symptom:** Tapping "✅ صحيح" twice created two identical rows in `transactions`.

**Root cause:** `_handleWidgetAction` → `_confirmTransaction` had no re-entry guard.

**Fix:** Added `bool _isConfirming` flag:
```dart
// In _handleWidgetAction:
if (_isConfirming) break;  // Guard: prevent double-tap

// In _confirmTransaction:
if (_isConfirming) return;
_isConfirming = true;
try { /* ... existing logic ... */ }
finally { _isConfirming = false; }
```
Guards at BOTH handler level AND method level (belt & suspenders).

### 7.2 Send Button Not Responding (5c8d113)

**Symptom:** The `↑` send button stayed gray/disabled even after typing. Only the
keyboard's submit key (`TextInputAction.send`) worked.

**Root cause:** `_InputBar` was a `StatelessWidget`. `hasText` was computed once at
build time:
```dart
hasText: controller.text.trim().isNotEmpty  // ← always false on first build
```
The widget never rebuilt when the user typed because it wasn't listening to the
`TextEditingController`.

**Fix:** Converted `_InputBar` to `StatefulWidget` (`_InputBarState`):
```dart
void initState() {
  _hasText = widget.controller.text.trim().isNotEmpty;
  widget.controller.addListener(_onTextChanged);
}

void _onTextChanged() {
  final hasText = widget.controller.text.trim().isNotEmpty;
  if (hasText != _hasText) setState(() => _hasText = hasText);
}

void dispose() {
  widget.controller.removeListener(_onTextChanged);
  super.dispose();
}
```

---

## 8. Supabase — Live State

### 8.1 Project

- **URL:** `https://kqhyjngtquutzdvjfbnf.supabase.co`
- **Region:** Frankfurt
- **Anonymous Sign-ins:** ENABLED (via `npx supabase config push`)
- **RLS:** Enabled on all 5 tables, 14 policies active

### 8.2 Tables (all deployed, currently holding test data from device session)

| Table | RLS Policies | Current Data |
|-------|:-----------:|--------------|
| `transactions` | SELECT, INSERT, UPDATE | Contains test transactions from TECNO LJ7 session |
| `commitments` | SELECT, INSERT, UPDATE | Empty (Stage 4) |
| `goals` | SELECT, INSERT, UPDATE | Empty (Stage 4) |
| `integrity_scores` | SELECT, INSERT, UPDATE | Empty (Stage 4) |
| `purchase_decisions` | SELECT, INSERT only | Empty (Stage 3) |

### 8.3 Quick Verification

```bash
# Verify tables & data
curl "https://kqhyjngtquutzdvjfbnf.supabase.co/rest/v1/transactions?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"

# Check RLS policies
DATABASE_URL="postgresql://postgres:...@db.kqhyjngtquutzdvjfbnf.supabase.co:5432/postgres"
psql "$DATABASE_URL" -c "SELECT tablename, policyname, cmd FROM pg_policies WHERE schemaname='public' ORDER BY tablename, cmd;"
```

---

## 9. SCSI Guardian Audit — Full Findings (commit 3ec6f50)

**Verdict: APPROVE — 0 CRITICAL | 2 HIGH | 4 MEDIUM | 3 LOW**

### 🔴 HIGH (fix before production)

| ID | Issue | File/Line | Fix |
|----|-------|-----------|-----|
| H-1 | 34 `print()` statements execute in release builds — leak user data to Android logcat | Multiple files | Gate behind `!bool.fromEnvironment('dart.vm.product')` or `assert(() { print(...); return true; }())` |
| H-2 | Gemini prompt injection via unsanitized user text | `chat_screen.dart` classify prompt | Wrap user input in delimiters, use `systemInstruction` vs `user` content separation |

### 🟡 MEDIUM (fix next iteration)

| ID | Issue | File/Line | Fix |
|----|-------|-----------|-----|
| M-1 | UUID collision risk in `ChatProvider._uuid()` | `chat_provider.dart:114-119` | Use `uuid` package or `Object.hash()` |
| M-2 | N+1 insert in `saveCompoundSplits` | `transaction_service.dart:110-130` | Batch `insert(list)` instead of sequential `for` loop |
| M-3 | Offline queue stub — no retry on failed writes | `chat_screen.dart` `_updateOnlineStatus` | Implement in-memory queue + retry on reconnect |
| M-4 | Cold Start data loss: UI update before DB write | `chat_screen.dart:219-237` | Save to Supabase FIRST, then show confirmation |

### 🟢 LOW (cosmetic)

| ID | Issue |
|----|-------|
| L-1 | `EdgeInsets.only(left:/right:)` in RTL app — prefer `EdgeInsetsDirectional` |
| L-2 | `_scrollController` created but never used for auto-scroll to bottom |
| L-3 | Camera button stub (`// NOT IMPLEMENTED — Stage 3` — acknowledged) |

### ✅ Security Positives

- Credentials: `String.fromEnvironment` only — zero `Platform.environment` in active code
- Supabase: `user_id` from `auth.currentUser!.id` on every insert
- Soft-delete: `eq('is_deleted', false)` in `hasExistingTransactions` query
- No `eval()` / `exec()` / `dart:mirrors` — widget catalog uses `switch` on predefined types
- Proper disposal: `StreamSubscription`, `TextEditingController`, `FocusNode`, `AnimationController`
- Guest-first auth: Anonymous sign-in with session persistence

---

## 10. Design Decisions (DEC Log)

| DEC | Title | Date |
|-----|-------|------|
| DEC-013 | Visual identity: shield+chart logo, light mode | 2026-07-12 |
| DEC-014 | Gemini API key shipped client-side (accepted MVP risk) | 2026-07-12 |
| DEC-015 | Isar local storage deferred (AGP 8.8 incompatibility) | 2026-07-12 |
| DEC-016 | Voice/TTS: iOS-only → cross-platform Android-first (speech_to_text) | 2026-07-12 |
| DEC-017 | Guest-first RLS: Supabase Anonymous Sign-In (zero DDL changes) | 2026-07-12 |
| DEC-018 | Voice UX: dedicated mic button 🎤 in input bar (4-element layout) | 2026-07-12 |

Full decision log: `app-spec/12_decision_log.md`

---

## 11. Test Status

```
flutter analyze: No issues found
flutter test:    16/16 passed
  - gemini_service_test.dart:  4 tests (instantiate, config, missing-key, live ping)
  - chat_provider_test.dart:  10 tests (add messages, loading states, errors, ID gen)
  - widget_test.dart:          2 tests (ChatScreen renders, input bar has mic+camera)
flutter build apk --debug --dart-define-from-file=.env:   ✓
flutter build apk --release --dart-define-from-file=.env: ✓ (57.9 MB)
```

**Note:** `flutter test` without `--dart-define-from-file=.env` skips the live Gemini
ping test (by design — shows "GEMINI_API_KEY was not compiled in" message).
Use `bash scripts/test_with_env.sh` for full credential test.

---

## 12. Environment

### 12.1 Required Files

**`.env`** (at project root — NEVER committed, in `.gitignore`):
```
GEMINI_API_KEY=AIzaSy...
SUPABASE_URL=https://kqhyjngtquutzdvjfbnf.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
DATABASE_URL=postgresql://postgres:...@db.kqhyjngtquutzdvjfbnf.supabase.co:5432/postgres
```

**`.env.example`** (committed — safe template with placeholder values):
```
GEMINI_API_KEY=your_gemini_api_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 12.2 Build & Test

```bash
# Debug build (for device)
bash scripts/build_debug.sh

# Release build
flutter build apk --release --dart-define-from-file=.env

# Tests with credentials
bash scripts/test_with_env.sh

# Lint (no credentials needed)
flutter analyze
```

### 12.3 One-Time Setup (already done)

1. Supabase project created at `kqhyjngtquutzdvjfbnf` (Frankfurt)
2. Schema DDL executed (5 tables, 14 RLS policies, 10 indexes)
3. Anonymous Sign-ins enabled via CLI (`npx supabase config push`)
4. Cairo `.ttf` files downloaded to `assets/fonts/`
5. `.gitignore` allows `.env.example` via `!.env.example` negation

---

## 13. What's NOT Done — Remaining Stages

### Stage 3 — OCR + "Can I Buy?"
- Camera/gallery integration (`image_picker`)
- Gemini Vision OCR receipt scanning
- System share sheet (`receive_sharing_intent`)
- Purchase decision engine ("Can I buy?" flow)
- Verdict widget (YES/WAIT/NO)

### Stage 4 — Goals + Integrity
- Savings goals CRUD + `goal_progress_card`
- Gap detection + Integrity Score calculator
- Tier 2 gateway simulation
- Silent Triage logic (Green/Gray/Red)
- Evening check-in scheduling

### Stage 5 — Testing, Audit, Polish
- Full widget test suite (all 6 catalog types)
- Integration tests (8 critical flows)
- RTL layout verification
- Offline behavior testing
- Hostile audit (prompt injection, data integrity)
- Demo runbook + rehearsal

### Post-Hackathon
- Backend proxy for Gemini API key (currently client-side — DEC-014 accepted risk)
- Real authentication: `linkIdentity()` from anonymous → email/phone
- Isar local cache re-enablement (AGP 8.8 fix or alternative)
- Fastlane release pipeline
- Production signing keys
- Commitment tracking feature (PRD §Tier 1 lists it but no task exists — gap identified by Product Steward)

---

## 14. Key File Paths

```
Project root:       /Users/abdurrahmanjahfali/Azdal
Spec pack:          app-spec/
  PRD:              app-spec/01_prd.md
  Flows:            app-spec/03_user_flows_navigation.md
  Design:           app-spec/04_ui_design_system.md
  ERD:              app-spec/05_data_model_erd.md
  Architecture:     app-spec/07_flutter_architecture.md
  Security:         app-spec/08_security_privacy.md
  Decision log:     app-spec/12_decision_log.md
  Backlog:          app-spec/16_implementation_backlog.md
  Supabase SQL:     app-spec/INIT-03_supabase_schema.md
Source:             lib/
Tests:              test/
Env template:       .env.example
Build scripts:      scripts/build_debug.sh, scripts/test_with_env.sh
CI:                 .github/workflows/lint.yml
Supabase config:    supabase/config.toml
Handoff (this):     CLAUDE_HANDOFF_STAGE2.md
```

---

*End of report. Stage 1 + 2 complete, device-verified, all bugs fixed. Ready for Stage 3.*
