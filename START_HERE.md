# 🗺️ START HERE — Reading Map for a New Claude Session

> You are picking up an existing, real project. Read this file top to bottom
> first. It tells you what Azdal is, what to read and in what order, and — most
> importantly — **what the next action is**. Do not start editing code or
> proposing work until you've read the five files in the path below.

## TL;DR (if you read nothing else, read this)

- **What it is:** Azdal (أزدل) — a Saudi-Arabic-dialect financial coach. You ask
  it "هل أقدر أشتري؟" (can I afford this?) in plain dialect; it gives a yes/wait/no
  verdict from your real income, commitments, spending, and goals. Tagline: **من
  مديون... إلى مستثمر** (from indebted to investor).
- **State:** Stage 4 done and device-verified; the AMAD hackathon shipped. CI is
  green, an APK builds automatically.
- **The next phase (this is the real work now):** a permanent, chat-only
  **personal build** for the founder's own financial life. His real turnaround —
  saving, an emergency fund, changed habits — is the definition of "done."
- **⏭️ THE IMMEDIATE NEXT ACTION:** two cheap gate checks before any code — (G1)
  App Check × sideloaded-APK in the Firebase console (decides the LLM SDK), and
  (G2) a live Supabase check (plan tier + confirm the throwaway data). Then Phase 0
  foundation: **remove guest sign-in, require email login from first launch**
  (DEC-051, which retired the old anonymous→permanent plan), backups, migration
  baseline, real tests. See the **"Unified build order"** section of
  `21_personal_build_plan.md`.
- **The one rule you must never break:** the LLM never does financial math. All
  arithmetic is pure Dart in the service layer. A number the model produced is a
  bug. (More guardrails at the bottom.)

## 📖 Read these five, in this exact order — then stop

| # | File | Why you read it | What you'll know after |
|---|------|-----------------|------------------------|
| 1 | **`CLAUDE.md`** | The anchor: identity, the 5 non-negotiable rules, where truth lives | How to work here without breaking things |
| 2 | **`app-spec/00_active_capabilities.md`** | The accurate, current status of every feature | What actually works today vs. what's mock or planned |
| 3 | **`app-spec/20_personal_vision_and_goals.md`** | The founder's real why, goals, and the coach's required tone | *Why* this exists and how to talk — to the coach's user AND to the founder |
| 4 | **`app-spec/21_personal_build_plan.md`** | The phased plan (Phase 0 → 0.5 → 1–3) | Exactly what to build, in what order, and why |
| 5 | **`app-spec/12_decision_log.md`** — read **DEC-049** and **DEC-050** first, skim the rest | The two forward-looking decisions + the full "why is it like this" archive | The personal-build direction and the tool-calling-router plan |

After those five you understand the project. For anything deeper, the map below
tells you where to go.

## 🧭 The map — how the documents relate

```mermaid
flowchart TD
    A["START_HERE.md<br/>(you are here)"] --> B["CLAUDE.md<br/>rules + orientation"]
    B --> C["00_active_capabilities.md<br/>what works NOW"]
    B --> D["20_personal_vision_and_goals.md<br/>the WHY + coach tone"]
    D --> E["21_personal_build_plan.md<br/>the phased PLAN"]
    E --> F["12_decision_log.md<br/>DEC-049 direction<br/>DEC-050 tool-calling router"]
    E -. "next action" .-> G["⏭️ Phase 0:<br/>account durability<br/>+ backups"]

    C -. "deeper specs" .-> H["app-spec/01–19<br/>PRD, architecture,<br/>data model, security…"]
    F -. "the source behind DEC-050" .-> I["docs/research/<br/>agent-harness-source.md"]
    D -. "business/market" .-> J["docs/business/,<br/>docs/research/"]

    style A fill:#001F5E,color:#fff
    style G fill:#2E7D32,color:#fff
    style B fill:#32C2FF,color:#001F5E
```

**How to use the rest of `app-spec/`:** files `01`–`19` are the deep spec pack
(PRD, Flutter architecture, data model, security, etc.). You don't read them
front-to-back — you open the one relevant to the task in hand. `00_*` files are
the always-relevant overview/status ones.

## ⏭️ Your next step, concretely

1. Confirm you've read files 1–5 above.
2. The first real work item is the **"Unified build order"** in
   `21_personal_build_plan.md`: gate checks (G1 App Check, G2 Supabase) → **Phase 0
   foundation** — remove guest sign-in and require email login from first launch
   (DEC-051, which supersedes the old anonymous→permanent conversion), a scheduled
   `pg_dump` backup (incl. `-s auth`), the migration baseline, and real tests. The
   four agentic-coach layers (memory, financial engines, world tools, proactivity)
   are DEC-051…054, designed in research docs 22–26.
3. Everything else in the plan (BNPL decisions, forecasting, the tool-calling
   router in Phase 0.5, emergency fund, etc.) comes *after* durability. Don't
   reorder it without a reason — the sequence is deliberate and explained in the
   plan.
4. Before touching anything load-bearing, check `12_decision_log.md` so you don't
   re-break something a DEC already solved.

## 🚧 Guardrails — do not break these (from CLAUDE.md, repeated so you can't miss them)

1. **The LLM never computes.** All financial math is pure Dart. (DEC-024)
2. **No hard delete.** Soft-delete only (`is_deleted`/`deleted_at`). (DEC-010)
3. **Verify on a real device against the real database.** "Tests pass" ≠ "it
   works." Every real bug here was found by driving the app, not static analysis.
   (LL-010/011)
4. **Guest-first, anonymous-first.** Real accounts are an in-place upgrade of the
   same identity. (DEC-017)
5. **Talk to the founder blunt and numbers-first, never flattering** — and the
   coach must be honest but **never gloat** after advice is ignored.
   (`20_personal_vision_and_goals.md`)
