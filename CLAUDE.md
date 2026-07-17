# Azdal (أزدل) — Project Guide for Claude

> **New to this project? Read [`START_HERE.md`](START_HERE.md) first** — it's a
> short, ordered reading map that ends with the exact next action. This file is
> step 1 of that map.

> **Read this first.** It orients you to what Azdal is, the rules that are
> non-negotiable, where the truth lives, and where the project is headed. When
> this file and the code disagree, trust the code and say so.

## What Azdal is

A Saudi-Arabic-dialect financial coach. You talk to it the way you talk — text
or voice — and it helps you make better money decisions **before** you spend,
not after. Its signature is **"هل أقدر أشتري؟"** (can I afford this?): ask about
a purchase in plain dialect and it gives a clear verdict (yes / wait / no) built
from your real income, commitments, month's spending, and savings goals, with a
33% debt-to-income safety cap.

The tagline is the whole thesis: **من مديون... إلى مستثمر** — from indebted to
investor. Tier 1 (the Coach) is real and works today. Tiers 2 (Smart Lender) and
3 (Wealth Builder) are a documented vision, shown in the app as clearly-labelled
preview screens, not faked as real.

Built for the AMAD hackathon (July 16–18, 2026), which has now happened. The
project's next and permanent phase is a **personal build** — see "Where this is
headed" below; it matters more than the hackathon did.

## The rules that don't bend

These are learned the hard way and enforced across the codebase. Breaking them
breaks the product's trustworthiness, which is the entire brand.

1. **The LLM never computes.** All financial math is pure Dart in the service
   layer (`lib/features/chat/services/`, `lib/core/services/`). Gemini
   understands language and picks what to do; it never does arithmetic. A
   number the model produced is a bug. (DEC-024)
2. **No hard delete.** Everything uses `is_deleted`/`deleted_at` soft-delete —
   deleting data would let a user hide bad spending and game their own coach.
   (DEC-010)
3. **Verify on a real device, against the real database.** "It compiles / tests
   pass" is not "it works." Every real bug in this project's history was found
   by driving the actual app on an Android device and querying Supabase
   directly — not by static analysis. Do that before believing a fix.
   (LL-010, LL-011)
4. **Guest-first, anonymous-first.** Every user gets a real Supabase account
   with full cloud persistence from message one — no signup wall. Real accounts
   are an in-place upgrade of the same identity (same UUID, zero migration).
   (DEC-017)
5. **Bounded replies.** Any LLM-authored text follows the Bounded Reply Pattern:
   one fenced field, explicit purpose, tone/length bounds, few-shot examples, a
   deterministic Dart fallback. (DEC-022/029)

## Where the truth lives

- **`app-spec/`** is the source of truth. `docs/` is reference only.
- **`app-spec/00_active_capabilities.md`** — the accurate, current status of
  every feature. Start here to know what actually works.
- **`app-spec/12_decision_log.md`** — every architecture and product decision
  with full rationale (DEC-001 → DEC-050+). When you wonder "why is it like
  this?", the answer is here.
- **`app-spec/00_lessons_learned.md`** — mistakes made and what they taught.
- **`app-spec/20_personal_vision_and_goals.md`** — the founder's real reasons,
  goals, and the coach's required tone. Read this before doing personal-build
  work; it's the "why" everything else serves.
- **`app-spec/21_personal_build_plan.md`** — the phased plan for the personal
  build, consulted with the Fable model and grounded in the actual code.

## Current state (as of 2026-07-17)

Stage 4 complete and device-verified: chat, natural-language + voice + receipt-OCR
expense logging, commitments, goals, the "can I buy?" engine, remaining-budget
queries, and an integrity score. Plus an investor-facing shell (splash,
onboarding, tabs, a mock bank-linking flow, an investment-journey vision screen)
and real email/password signup layered on the anonymous-first base. CI is green
and builds a downloadable APK automatically. See the decision log for the full
trail; the most recent entries (DEC-044 onward) cover this stretch.

## Where this is headed — the personal build

Regardless of the hackathon outcome, the founder needs Azdal to work for **his
own life** — he's said so directly and with weight. The next phase is a
permanently-developed, **chat-only** personal build (no demo shell), where his
own financial turnaround — changing habits, saving, building an emergency fund —
is the literal definition of the branch being "ready for the next stage." This
is skin in the game: he is the product's first real, all-in user.

Two documents govern this, and they are as binding as the app-spec:

- **`app-spec/20_personal_vision_and_goals.md`** — the emotional truth, the
  goals, and the **coach tone philosophy**: blunt honesty over flattery, willing
  to deliver a hard truth, but **never gloating** after advice is ignored.
- **`app-spec/21_personal_build_plan.md`** — the phased plan. The immediate,
  hackathon-independent priority is **account durability** (convert his account
  from anonymous to permanent + backups) — it protects data that already exists.
  The first big architectural move is **Phase 0.5: a tool-calling router** (see
  DEC-050) that replaces the brittle regex intent-gates with Gemini native
  function-calling — the right foundation before adding many new coaching
  capabilities.

## How to work here

- Match the surrounding code's style; read `12_decision_log.md` before changing
  anything load-bearing, so you don't re-break something a DEC already solved.
- Keep `app-spec/` current as you work — new decisions get a DEC entry.
- Talk to the founder the way the coach should talk to its user: direct, honest,
  numbers-first, no flattery. He asked for that explicitly. See
  `20_personal_vision_and_goals.md`.
- The Fable model has been the design/architecture consultant throughout; its
  consultations are captured in the plan docs and decision log.
