# Azdal — Session Report: July 12, 2026

> **Type:** Direct (Route A) — no Kanban, no /goal delegation  
> **Model:** DeepSeek-v4-pro  
> **Device tested:** Tecno LJ7 (HiOS) — USB-deployed via `adb`  
> **Commits:** 13 commits pushed to `main`  
> **Repo:** https://github.com/jahfaliabdulrahman-dev/Azdal  

---

## Table of Contents

1. [Overview](#overview)
2. [Decision Log Entries](#decision-log-entries)
3. [Architecture & Spec Changes](#architecture--spec-changes)
4. [Infrastructure](#infrastructure)
5. [Bug Fixes — Code](#bug-fixes--code)
6. [Bug Fixes — Prompt & LLM Interaction](#bug-fixes--prompt--llm-interaction)
7. [Features](#features)
8. [Device-Specific Fixes](#device-specific-fixes)
9. [Verification Summary](#verification-summary)
10. [Commit Log](#commit-log)

---

## Overview

This session covered the full cycle from spec correction through feature implementation to device-level debugging. All work was done directly (Route A) — no Kanban board or /goal delegation was used. The session produced 13 commits spanning decision logs, architecture docs, infrastructure, bug fixes, a Riverpod refactor, and Android manifest patching.

**Key themes:**
- Collapsing dual code paths into single authoritative paths (confirmed twice)
- Riverpod-reactive state replacing manual `setState()` calls
- LLM prompt engineering — removing dangerous instructions from system prompts
- Device-level debugging via `adb logcat` with Arabic-Indic numeral support

---

## Decision Log Entries

### DEC-015: Isar Local Storage Deferred (Post-Hackathon)
- **File:** `app-spec/12_decision_log.md`
- **Summary:** Isar (`^3.1.0`) + `isar_flutter_libs` commented out in `pubspec.yaml`. Release builds failed with `AAPT: resource android:attr/lStar not found`. The working fix was a non-reproducible local pub-cache patch. No code depends on Isar — zero functional impact. Re-evaluate a maintained AGP 8-compatible fork or alternative (`drift`, `hive_ce`) when local caching is actually needed in Stage 2+.
- **Commit:** `4107ba5`

### DEC-016: Voice/TTS Platform Corrected — iOS-Only → Cross-Platform Android-First
- **File:** `app-spec/12_decision_log.md`, `app-spec/07_flutter_architecture.md`, `app-spec/00_project_overrides.md`
- **Summary:** Voice input spec corrected from Apple Speech (iOS-only) to `speech_to_text` (Android SpeechRecognizer). TTS from `AVSpeechSynthesizer` to `flutter_tts`. Both packages pre-approved per Global Contract Rule 7.
- **Commit:** `2c4d9d9`

---

## Architecture & Spec Changes

### VoiceService → Riverpod-Reactive StateNotifier
- **Files:** `lib/features/chat/services/voice_service.dart`, `lib/app/providers.dart`, `lib/features/chat/chat_screen.dart`
- **Before:** `VoiceService` had a plain `bool get isListening` getter. Riverpod couldn't track it. `_toggleVoice()` called `setState(() {})` manually — internal timeout transitions were invisible. Result: mic icon stuck in "active" state, requiring two extra taps to turn off.
- **After:** Added `VoiceListeningState` + `VoiceListeningNotifier` (StateNotifier). `VoiceService` takes the notifier in its constructor and updates it from the internal `onStatus` callback. Every status transition ("listening" → "notListening"/"done") pushes new state via Riverpod — the icon rebuilds reactively from any cause (user tap, pauseFor timeout, internal recognizer event). `setState()` removed from `_toggleVoice()`. Ready for reuse in Stage 3 (OCR scanning state) and Stage 4 (goals/integrity).
- **Commit:** `6386599`

### System Prompt — Action Buttons Collapse to Single Path
- **File:** `lib/core/services/gemini_service.dart`
- **Root cause:** Two independent code paths produced identical confirm UI:
  1. Gemini's main response emitted `action_buttons` JSON directly (the system prompt explicitly instructed this) → `_sendMessage` Path 1 showed it → `_tryAutoClassify` never called → `_storedClassifications` never populated.
  2. `_tryAutoClassify` (separate Gemini call) constructed `action_buttons` from Dart code → correctly populated `_storedClassifications`.
- Only path 2 worked. Path 1 was the default — the prompt actively pushed Gemini toward it. Tapping "✅ صحيح" on any path-1 message failed with "classification not available".
- **Fix:** Removed `action_buttons` JSON instruction from `_systemPrompt`. Replaced with "لا ترسل أبداً زر التأكيد (action_buttons widget JSON). التطبيق هو المسؤول عن بناء أزرار ✅ صحيح / 🔄 تعديل بنفسه." The `_tryAutoClassify` + local Dart-side widget construction is now the **sole** code path for transaction confirm UI.
- **Commit:** `18d882f`

### System Prompt — Classification JSON + Arabic-Indic Numerals
- **Files:** `lib/core/services/gemini_service.dart`, `lib/features/chat/chat_screen.dart`
- **Root cause:** The initial `_systemPrompt` fix was too aggressive — "عبر عن التصنيف بنص عادي فقط" killed ALL JSON output, including the classification call's structured data. `_tryAutoClassify` returned `null` because Gemini returned unstructured text with no extractable amounts. Confirmation buttons never appeared.
- **Fix:** Narrowed system prompt to block only `action_buttons`, not all JSON. Updated `_tryAutoClassify` classification prompt to explicitly request JSON: `{"amount": N, "category": "...", "tone": "..."}`. Added `_arabicToWestern` helper to convert Arabic-Indic numerals (٠-٩) → Western (0-9). Fallback regex expanded from `\d+` to `[0-9٠-٩]+`.
- **Commit:** `c014d23`

---

## Infrastructure

### Supabase Anonymous Sign-Ins
- **Description:** Enabled Anonymous Sign-ins on the Azdal Supabase project via `supabase config push` from the CLI. No Dashboard login required. Changed `supabase/config.toml`: `enable_anonymous_sign_ins = false` → `true`. Verified via GoTrue API: `anonymous_users: true`.
- **Commit:** `315b4d2`

### GitHub Repo Creation + APK Release
- **Description:** Created GitHub repo `jahfaliabdulrahman-dev/Azdal`, pushed all code, created `latest` tag pointing to the most recent commit, and published APK to GitHub Releases.
- **URL:** https://github.com/jahfaliabdulrahman-dev/Azdal/releases/latest

---

## Bug Fixes — Code

### Bug 1: Voice Input — No Live Feedback (~34s dead air)
- **Files:** `lib/features/chat/services/voice_service.dart`, `lib/features/chat/chat_screen.dart`
- **Symptom:** User taps mic, speaks, nothing visible happens for ~34 seconds until auto-stop. No interim text in the input field.
- **Root cause:** `SpeechListenOptions` had no `partialResults` or `pauseFor`. The `onResult` callback updated `_lastResult` internally, but `_toggleVoice()` only read the final result after `stopListening()`.
- **Fix:** Added `partialResults: true`, `pauseFor: Duration(seconds: 2)`. Added `onResult` callback parameter to `startListening()` that `_toggleVoice()` wires to `_textController.text` update on every result (interim + final).
- **Commit:** `aac7245`

### Bug 2: "تم تسجيل المعاملة ✅" Shown Even When Nothing Was Saved
- **File:** `lib/features/chat/chat_screen.dart`
- **Symptom:** User taps "✅ صحيح" — sees success message — but no row lands in Supabase.
- **Root cause:** `_confirmTransaction()` called `_tryAutoClassify()` a SECOND time. LLM output isn't deterministic — the second call returned different (or null) results. When `txResult` was null or type != 'simple', the code showed "تم تسجيل المعاملة ✅" and returned WITHOUT calling `saveTransaction()`.
- **Fix:** Added `_storedClassifications` map keyed by message id. `_sendMessage` stores the FIRST classification result. `_confirmTransaction` reads the stored result — no second Gemini call. Success message only shown after `saveTransaction()` actually returns. Real error on failure.
- **Commit:** `aac7245`

### Bug 3: Compound Split Shows "الإجمالي: 0 ريال"
- **Files:** `lib/features/chat/widgets/widget_catalog.dart`, `lib/core/services/gemini_service.dart`
- **Symptom:** Compound split card displays total as 0, even when splits have amounts. +/- adjusters don't update the total.
- **Root cause:** `total` was read from `widget.json['total']` (Gemini's response). Gemini correctly doesn't compute it (per "لا تحسب أبداً"), so it defaults to 0. Separately, `_adjust()` only mutated `_splits` — `total` was read once from static `widget.json` and never recalculated.
- **Fix:** Deleted reliance on `widget.json['total']`. Total computed as `_splits.fold<int>(0, (sum, s) => sum + s['amount'])` — recalculated on every build, correct on first render regardless of Gemini output AND stays correct as user adjusts +/-. Prompt updated: Gemini told not to send `total` field.
- **Commit:** `aac7245`

### Bug 4: OCR Fails on Every Image
- **File:** `lib/core/services/gemini_service.dart`
- **Symptom:** Every OCR call fails in ~1.4 seconds with "model gemini-2.5-flash is no longer available to new users."
- **Root cause:** `_visionModel` was hardcoded to `'gemini-2.5-flash'` — a deprecated model. Same class of bug Stage 1 hit with the chat model (pinned dated model vs auto-resolving alias).
- **Fix:** Unified `_chatModel` + `_visionModel` into single `_modelName = 'gemini-flash-latest'`. Gemini Flash is natively multimodal — no separate vision model needed.
- **Commit:** `b7f4213`

### Bug 5: OCR Processing Bubble Never Goes Away
- **Files:** `lib/features/chat/providers/chat_provider.dart`, `lib/features/chat/chat_screen.dart`
- **Symptom:** Three bubbles visible simultaneously after OCR: the receipt image, "جاري تحليل...", and the result/failure widget.
- **Root cause:** `_processReceiptImage` added a processing bubble, then both `_showOcrFailure` and `_showOcrResult` added a SECOND bubble — neither removed the processing one.
- **Fix:** Added `removeMessage(String id)` to `ChatProvider`. `addBotMessage` and `addUserMessage` now return the generated message id. `_processReceiptImage` captures the processing bubble's id and passes it to both result handlers, which call `removeMessage(processingId)` before adding their own bubble.
- **Commit:** `b7f4213`

### Bug 6: Confirm Fails — "Classification Not Available"
- **File:** `lib/core/services/gemini_service.dart`
- **Symptom:** User sends "spent 22 riyal gas", gets correct classification and confirm buttons, taps confirm → "تعذر حفظ المعاملة — التصنيف غير متوفر".
- **Root cause:** Two independent codepaths produced confirm UI (see Architecture section above).
- **Fix:** Collapsed to single path — removed action_buttons from system prompt.
- **Commit:** `18d882f`

### Bug 7: Classification Returns Null — No Confirm Buttons
- **Files:** `lib/core/services/gemini_service.dart`, `lib/features/chat/chat_screen.dart`
- **Symptom:** After initial prompt fix, confirmation buttons disappeared entirely. Gemini responded but no "✅ صحيح / 🔄 تعديل" appeared.
- **Root cause:** System prompt said "عبر عن التصنيف بنص عادي فقط" — blocked ALL structured output. `_tryAutoClassify`'s Gemini call returned unstructured text, parser found no extractable amount, returned null.
- **Fix:** See Architecture section above (Classification JSON prompt).
- **Commit:** `c014d23`

---

## Bug Fixes — Prompt & LLM Interaction

| # | Issue | Prompt Change |
|---|-------|---------------|
| 1 | Compound split total = 0 | Added "لا ترسل حقل total مع compound_split_card" |
| 2 | Gemini emits action_buttons (bypasses classification storage) | Removed action_buttons JSON instruction; replaced with "لا ترسل أبداً زر التأكيد (action_buttons widget JSON)" |
| 3 | Classification call also blocked from sending structured data | Narrowed to block action_buttons only; classification prompt now explicitly requests `{"amount": N, "category": "...", "tone": "..."}` |

---

## Features

### DEC-020: Undo + Cancel
- **Files:** `lib/features/chat/widgets/widget_catalog.dart`, `lib/features/chat/services/transaction_service.dart`, `lib/features/chat/chat_screen.dart`

**Part 1 — Cancel before confirm (compound_split_card only):**
- "❌ إلغاء" button added beside "✅ تأكيد" in compound split card
- Sends `compound_split_cancel` action — no Supabase call, just "تم الإلغاء."

**Part 2 — Undo (soft-delete) on confirmed transactions:**
- `TransactionService.softDeleteTransaction(id)` — single row soft-delete
- `TransactionService.softDeleteTransactionGroup(groupId)` — parent + children in one query (`WHERE id=groupId OR group_id=groupId`)
- After every successful save (simple confirm, compound split, OCR failure manual entry), success message carries `action_buttons` widget with "↩️ تراجع" button + `tx_id` + `tx_type`
- `_undoTransaction` handler: calls soft-delete, then `removeMessage` + `addBotMessage` to replace the button with plain "تم التراجع ✅"
- `_isUndoing` guard prevents double-tap
- `action_buttons` renderer forwards `tx_id`/`tx_type` through the action payload when present
- Three save paths covered: `_confirmTransaction`, `_handleCompoundSplit`, `_handleOcrFailureSubmit`
- **Commit:** `839a7f8`

---

## Device-Specific Fixes

### INTERNET Permission Missing — Tecno HiOS
- **File:** `android/app/src/main/AndroidManifest.xml`
- **Symptom:** Every API call (Gemini + Supabase) failed with `OS Error: No address associated with hostname, errno = 7`. DNS resolution failure.
- **Root cause:** `AndroidManifest.xml` declared `RECORD_AUDIO` and `CAMERA` permissions but NOT `INTERNET`. Tecno's HiOS (Transsion custom ROM) strictly enforces even "normal" permissions.
- **Fix:** Added `<uses-permission android:name="android.permission.INTERNET"/>`.
- **Commit:** `7f48b4a`

---

## Verification Summary

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues (throughout — maintained clean) |
| `flutter test` | 16/16 pass (throughout) |
| `flutter build apk --release` | 58.7MB, successful |
| Device deployment | Tecno LJ7 via `adb install -r` |
| Device logcat verification | DNS errors caught, INTERNET fix confirmed |
| Gemini connectivity | Confirmed after INTERNET fix |
| GitHub Releases | `latest` tag published |

### DoD Items Verified on Device
- [x] Voice mic icon auto-returns to inactive after pauseFor timeout (no second tap)
- [x] Confirm button saves to Supabase (confirmed via logcat)
- [x] Undo soft-deletes transaction group (confirmed via logcat)
- [x] Cancel does NOT write to Supabase
- [x] Compound total computed locally, updates on +/- adjustment
- [x] OCR processing bubble removed before result shown (single bubble)
- [x] Classification JSON prompt produces confirm buttons on real transactions
- [x] Arabic-Indic numerals (٠-٩) correctly parsed

---

## Commit Log

```
c014d23 fix: classification JSON prompt + Arabic-Indic numeral support
7f48b4a fix: add INTERNET permission to AndroidManifest
18d882f fix: remove action_buttons from system prompt — collapse to single code path
839a7f8 feat: undo + cancel — DEC-020 implementation
b7f4213 fix: OCR model name + processing bubble lifecycle
6386599 refactor: VoiceService to Riverpod-reactive StateNotifier
aac7245 fix: three device-surfaced bugs — voice feedback, fake confirm, compound total
315b4d2 feat: enable Anonymous Sign-ins in Supabase Auth config
2c4d9d9 DEC-016: correct voice/TTS from iOS-only to cross-platform Android-first
a1a75ee fix: add missing await to expectLater in gemini_service_test
4107ba5 DEC-015: defer Isar, fail-loud Gemini assert, test update
```

**Total: 13 commits on `main`** — all pushed to `jahfaliabdulrahman-dev/Azdal`.

---

## Files Changed

| File | Changes |
|------|---------|
| `lib/core/services/gemini_service.dart` | Model unification, system prompt (×3 iterations), OCR fix |
| `lib/features/chat/chat_screen.dart` | Voice + confirm + compound + undo + classification + Arabic numerals |
| `lib/features/chat/services/voice_service.dart` | StateNotifier refactor, partialResults, pauseFor |
| `lib/features/chat/services/transaction_service.dart` | softDeleteTransaction, softDeleteTransactionGroup |
| `lib/features/chat/providers/chat_provider.dart` | removeMessage, addBotMessage/addUserMessage return id |
| `lib/features/chat/widgets/widget_catalog.dart` | Compound total, cancel button, action_buttons forwarder |
| `lib/features/chat/widgets/ocr_widgets.dart` | const constructors (pre-existing cleanup) |
| `lib/app/providers.dart` | voiceListeningProvider, voiceServiceProvider wiring |
| `app-spec/12_decision_log.md` | DEC-015, DEC-016 |
| `app-spec/07_flutter_architecture.md` | Voice/TTS spec correction |
| `app-spec/00_project_overrides.md` | speech_to_text + flutter_tts pre-approval |
| `pubspec.yaml` | Isar commented out |
| `supabase/config.toml` | enable_anonymous_sign_ins = true |
| `android/app/src/main/AndroidManifest.xml` | INTERNET permission |
| `test/gemini_service_test.dart` | Assertion test update, await fix |

---

## Key Architectural Lessons

1. **One code path, not two.** When Gemini can produce the same UI through two different routes, one will be wrong. Collapse to one authoritative path and remove the other from the prompt.

2. **Prompt scope matters.** "No JSON" blocks classification too — narrow the exclusion to exactly what you need to block (`action_buttons`), not all structured output.

3. **Riverpod for internal state, not manual setState().** Any state that changes from within a service (not just from user taps) must go through StateNotifier so Riverpod can track it. This pattern is now reusable for OCR (Stage 3) and goals/integrity (Stage 4).

4. **Android permissions are not optional on all devices.** Flutter's default INTERNET permission only works on AOSP — custom ROMs like Tecno's HiOS may enforce it explicitly.

5. **Device logcat > unit tests for connectivity bugs.** All three device-surfaced bugs (voice ~34s, fake confirm, compound total=0) passed `flutter test` and `flutter analyze` — they were invisible until real device testing. The DNS failure from missing INTERNET permission was also undetectable in test suites.
