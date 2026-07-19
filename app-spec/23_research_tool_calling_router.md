# Research — Tool-Calling Router (Phase 0.5, DEC-050)

> **Provenance.** A Fable-model deep-research consult (2026-07-18), grounded in
> full reads of DEC-050/049/024/037-B/022/029/020/021, the live
> `gemini_service.dart` (5 separate prompts), the `_sendMessage` gate cascade in
> `chat_screen.dart`, the six service signatures, and `pubspec.yaml/.lock`; then
> verified against **current official docs** (Firebase AI Logic function-calling,
> last updated 2026-07-03; Gemini API function-calling, 2026-07-07; pub.dev
> queried live). Sources inline; unverified points marked.
>
> **Bottom line up front:** DEC-050's design survives contact with the current
> docs **intact** — forced single-hop function-calling with coarse tools aligns
> with Google's own "ANY mode is the most useful mode" and Anthropic's tool-
> consolidation guidance. The riskiest item is **not** the router design — it is
> the **July-2026 App Check enforcement colliding with a sideloaded personal
> APK**, which must be resolved first.

## 1. SDK verdict — migrate once, to `firebase_ai`, behind a thin interface

**Recommendation: `firebase_ai` (Firebase AI Logic), currently 3.12.1 — but
adopt it behind a ~50-line `RouterLlm` interface you own**, for testability and
as a hedge.

| Claim | Status | Source |
|---|---|---|
| `google_generative_ai` is deprecated; repo renamed `deprecated-generative-ai-dart`; "use the unified Firebase SDK" | **Verified** | github.com/google-gemini/deprecated-generative-ai-dart |
| Its last release is 0.4.7 (2025-04-17) — ~15 months frozen | **Verified** (pub.dev live) | pub.dev/packages/google_generative_ai |
| Downstream (`langchain_google`) migrated off it citing response-format rot "as the underlying API changed" | **Verified** | pub.dev/packages/langchain_google/changelog |
| Official migration path is Firebase AI Logic; dedicated migration guide exists | **Verified** | firebase.google.com/docs/ai-logic/migrate-from-google-ai-client-sdks |
| `firebase_ai` supports function calling: `Tool.functionDeclarations`, `FunctionDeclaration`, `ToolConfig`, `FunctionCallingConfig.auto()/.any(Set<String>)/.none()` — forced ("ANY") mode with subset restriction | **Verified** | firebase.google.com/docs/ai-logic/function-calling · pub.dev FunctionCallingConfig API |
| Parallel function calling supported; up to 128 declarations | **Verified** | same Firebase doc |
| **No Gemini API key in the app at all** — `FirebaseAI.googleAI()` proxies through Firebase; app identity via `firebase_options.dart` (`flutterfire configure`). `--dart-define` key becomes unnecessary for Gemini | **Verified** | firebase.google.com/docs/ai-logic/get-started?platform=flutter |
| **New since early July 2026: AI Logic setup auto-*enforces* Firebase App Check.** Dev needs the debug provider; prod needs real attestation (Play Integrity on Android) | **Verified — biggest migration risk** | same Get-started doc |
| Gemini 3-series thought signatures during function calling "automatically handled by the SDKs" | **Verified for the Gemini-API doc's claim**; not independently verified for `firebase_ai` | ai.google.dev/gemini-api/docs/function-calling |

### Alternatives (honest tradeoffs)

- **`googleai_dart` 9.0.0** (2026-07-05) — unofficial (langchain-dart ecosystem),
  pure Dart, actively maintained, keeps the existing `--dart-define` key, no
  Firebase. Tradeoff: single-maintainer bus factor on the most critical
  dependency. **Designated fallback if App Check proves incompatible with the
  sideloaded build.**
- **`google_cloud_ai_generativelanguage_v1beta` 0.5.3** — an **official** Google-
  generated Dart client (googleapis/google-cloud-dart), published 2026-07-17.
  Pre-1.0, low-level, auth ergonomics unexamined. **Watch it — likeliest future
  official de-Firebased path**; the interface hedge makes switching cheap.
- **Direct REST** (`generativelanguage.googleapis.com/v1beta`, `x-goog-api-key`)
  — full control, keeps compile-time key, ~200 lines. Tradeoff: you own schema
  JSON, error taxonomy, API drift forever. Worse sustainability than `firebase_ai`
  unless Firebase is vetoed.
- **Stay on deprecated 0.4.7** — works today, but frozen pre-Gemini-3 with
  documented format rot; building the router on it = migrating twice. Rejected.

**Why `firebase_ai` despite the Firebase-in-a-Supabase-app smell:** coupling is
confined to the AI call path (Supabase stays the only backend); the API surface is
a near-identical descendant (`GenerativeModel`/`Content`/`FunctionDeclaration`
lineage — the five prompts port almost mechanically); and it deletes the API-key-
in-APK exposure instead of patching it.

## 2. Recommended router architecture

### Tool registry (open/closed — adding intent N+1 touches zero dispatcher lines)

```dart
/// One routable intent. lib/features/router/tools/*.dart — one file each.
abstract interface class RouterTool<A> {
  String get name;                              // 'evaluate_purchase'
  FunctionDeclaration get declaration;          // typed Schema, Arabic descriptions
  WriteTier get tier;                           // none | autoSaveWithUndo | confirmCard  (DEC-020/021 in Dart)
  A parseArgs(Map<String, Object?> raw);        // validate+normalize (Arabic-Indic digits!). Throws ToolArgsError.
  Future<ToolOutcome> run(A args, ToolContext ctx);  // calls the EXISTING pure-Dart service
}

sealed class ToolOutcome { const ToolOutcome(); }
final class RenderOutcome  extends ToolOutcome { final ChatWidgetSpec widget; }      // read-tools → Dart widget
final class StagedProposal extends ToolOutcome { final ProposalKind kind; final Map<String,Object?> draft; }  // write-tools: NOTHING written
final class ClarifyOutcome extends ToolOutcome { final String question; }            // hardcoded Dart string, BRP-exempt

final class ToolRegistry {
  final Map<String, RouterTool<Object?>> _byName;
  List<Tool> get declarations => [Tool.functionDeclarations([..._byName.values.map((t) => t.declaration)])];
  RouterTool<Object?>? operator [](String name) => _byName[name];  // miss = hallucinated name → clarify
}
```

Two special registered tools make "no tool" and "unclear" **typed choices instead
of silent fallthroughs** — the structural fix for the DEC-037-B failure mode
(where a miss was indistinguishable from "feature doesn't apply"):

- `general_chat` — catch-all; triggers the existing BRP-bounded coach call
  (unchanged).
- `ask_clarification(missing: [...])` — the model saying "buy intent, amount
  missing".

### Dispatch flow (one round, structurally incapable of looping)

```
user text
 └─ Dart builds RouterState (compact, Dart-authored; NO raw transcript, NO financial values)
      e.g. {"pending": {"tool":"evaluate_purchase","item":"ساعة","missing":["amount"]}}
 └─ ONE generateContent call:
      systemInstruction: short routing prompt (dialect few-shots; NO arithmetic ever requested)
      contents: [state block + current message]         ← history-free by construction
      tools: registry.declarations
      toolConfig: FunctionCallingConfig.any(registry.names)   // forced: ALWAYS a typed decision
 └─ for each functionCall (deterministic order, cap ≤3, sequential — money ordering matters):
      tool = registry[call.name] ?? → ClarifyOutcome + flagged trace row        // hallucinated name
      args = tool.parseArgs(call.args)  — invalid → ClarifyOutcome              // hallucinated args
      outcome = tool.run(args, ctx)     — runs the existing pure-Dart service
 └─ Dart renders widgets from typed outcomes. NO FunctionResponse is EVER sent back
    on number-bearing paths — the round-trip does not exist in the code path.
```

**How each DEC-050 discipline rule is enforced structurally (not by convention):**

1. **Model never computes** — `evaluate_purchase(item, amount)` → existing
   `PurchaseDecisionService.evaluate(...)`, which fetches its own five inputs
   internally. The model's universe is (user text, state block, tool
   names/schemas). Because rule 3 skips the response round-trip, the model never
   sees even the verdict. **There is no code path over which a financial number
   reaches the model.**
2. **Write-tools never write** — the type system enforces it: write-tools return
   `StagedProposal`; only the existing `_handleWidgetAction` confirm/undo
   machinery (DEC-020/021) calls Supabase. Tier is a Dart field, never prompt
   text.
3. **Model routes in, Dart speaks out** — rendering consumes `ToolOutcome` only;
   warm phrasing reuses existing BRP-bounded prompts with deterministic
   fallbacks; no narration round-trip.
4. **One-round cap** — the router returns `List<ToolOutcome>`; no loop, no send-
   back. "Hard-cap 2" = clarify → user answers → second routed message (with
   `pending` state); a second failure emits a hardcoded clarify with zero LLM
   calls. Deterministic bail.
5. **History policy** — entry point `route(String userText, RouterState state)`;
   the transcript is not a parameter — it can't leak without a signature change
   code review catches.

**Forced `ANY` mode + `general_chat` catch-all** (not `AUTO`): `AUTO`
reintroduces the ambiguity you're killing (a text reply that might be a routing
miss or legit chat). `ANY` yields a machine-checkable decision for *every*
message — which is also what makes the golden intent matrix fully assertable. The
Firebase doc calls ANY "the most useful mode." Official best practices this
follows: strong typing, clear descriptions, **10–20 active tools max** (~10 here),
and "**validate function calls before executing**" — the `parseArgs` layer is the
recommended posture. **Multi-intent** ("جوال بـ2000 ودراجة بـ800") → parallel
calls → two verdicts, closing DEC-039a for free (add to the matrix, don't assume).

## 3. Is "coarse, verdict-shaped tools" an established pattern?

Mostly yes — the coarseness is canonical; the information-hiding twist is ours.
- Keeping deterministic computation out of the model is canonical; DEC-003
  predates the industry writeups. Flutter's official tool-calls best-practices doc
  (which demos `firebase_ai`): the LLM "does better with a smaller set of targeted
  tools that don't overlap." (docs.flutter.dev/ai/best-practices/tool-calls)
- Anthropic's *Writing effective tools for agents* is the strongest reference:
  consolidate into fewer, targeted, self-contained tools returning high-signal
  results, not raw data — precisely the argument against `get_income` +
  `get_commitments`. (anthropic.com/engineering/writing-tools-for-agents)
- The stronger form — **designing tool boundaries so the model cannot receive the
  numeric components at all** (single-hop, no result round-trip, so arithmetic is
  *impossible* not merely discouraged) — has **no canonical named writeup**. It's
  a sound application of information-hiding / least-privilege (OWASP LLM
  "Excessive Agency" mitigation). Established principle, novel-strength
  enforcement; keep DEC-050's wording as the source of record.

## 4. Extensibility & testing

**Adding intent N+1** (e.g. `forecast_month`): one new file implementing
`RouterTool`, one line in the registry, one new pure-Dart service method, N new
matrix rows. Dispatcher/prompt/rendering untouched. Deleting the four
`_looksLike*` regexes, `classifyBuyIntent`, `classifySetupIntent`, and most of
`_classifySystemPrompt`'s routing role is the point — net code shrinks.

**Golden intent matrix** (Phase 0 builds it against the *current* router — DEC-050
sequencing):
- Committed JSONL: `{message, expected_tool, expected_args, note}` — seeded from
  every phrasing in the DEC history (hamza saga, "هل أقدر أشتري طابعة بـ1000", bare
  "50 بيض", multi-intent, greetings, integrity/budget queries).
- **Offline tier** (unit tests, CI): a `FakeRouterLlm` implementing the interface
  replays recorded routings; asserts unknown-name→clarify, bad-args→clarify,
  staged-proposal-never-writes (mock Supabase → assert zero writes before
  confirm), cap enforcement, state-block content. This is why the SDK **must never
  be constructed inside unit-tested logic** — hence the `RouterLlm` interface
  (`firebase_ai` needs `Firebase.initializeApp`).
- **Live tier** (a `dart run` eval script, not CI): hits real Gemini with the full
  matrix, reports chosen-tool/args accuracy diff. Run against the **old regex
  router first to freeze a baseline** (DEC-049 Phase 0). LL-010 still applies:
  matrix green ≠ device-verified.

## 5. Tool-call tracing

One Supabase table `tool_calls`: `id, user_id, message_text, ts, model,
latency_ms, tool_name, args jsonb, outcome_kind
('render'|'staged'|'clarify'|'invalid_args'|'unknown_tool'|'error'),
result_summary jsonb, write_ids uuid[] (filled at confirm time), error text`. One
row per function call, `is_deleted` soft-delete. Name columns after OpenTelemetry
GenAI semantic conventions (`gen_ai.tool.name`, `gen_ai.request.model`,
`execute_tool`) — still Development-stability, so naming guidance not a spec.
Storing the raw message is correct for a single-user build (it's the founder's own
data) and turns verify-by-Supabase into `select * from tool_calls order by ts desc
limit 5`.

## 6. Pitfalls

1. **App Check enforcement (the sharp new one).** Since early July 2026 AI Logic
   setup auto-enforces App Check. Play Integrity assumes Play-store installs; the
   personal build is a **sideloaded CI APK**. The debug provider works but means
   registering debug tokens per device. If enforcement can't be relaxed per
   project, `firebase_ai` gets genuinely painful → fallback `googleai_dart`.
   **Live-check in the Firebase console before committing to the SDK.**
2. **Arithmetic leaks via the back door:** (a) sending `FunctionResponse` back
   "just for a nicer sentence" — the moment a verdict JSON re-enters the model,
   DEC-024 is dead; (b) financial figures in the state block "for context"; (c) a
   future `get_dti_ratio` returning components — the DEC-039b DTI query must be a
   verdict-shaped `get_commitment_ratio` returning a Dart-rendered widget.
3. **Unintended writes:** a tool author calling `service.addCommitment` inside
   `run()` instead of returning `StagedProposal`. Mitigate structurally: write-
   services take a capability object only the confirm handler holds, or lint-gate
   `supabase.from(...).insert` to the approvals layer.
4. **ANY-mode schema rejection:** docs note very large/deeply-nested schemas may be
   rejected in `any` mode. Keep declarations flat (primitives + one-level
   objects) — coarse tools make this easy.
5. **Forced mode + greetings:** without `general_chat`, ANY will shoehorn "هلا"
   into some tool. The catch-all is load-bearing.
6. **Hallucinated args:** model inventing `amount` when none was given. `required`
   fields + `parseArgs` + few-shots ("no amount → omit/clarify") are the guard.
   Arabic-Indic digit normalization lives in `parseArgs` (DEC-036 bug #4's
   lesson).
7. **ChatSession leakage:** never use the SDK's `Chat` abstraction for the router —
   it accumulates history internally, violating rule 5 and (Gemini 3) entangling
   thought-signature round-tripping. Stateless `generateContent` only.
8. **Model alias:** `gemini-flash-latest` works on the Gemini Developer API today;
   availability under Firebase AI Logic's model list is **unverified** — check,
   else pin an explicit model.

## 7. Open questions / founder decisions

1. **App Check vs sideloaded APK** (pitfall 1) — live console check; this alone
   decides `firebase_ai` vs `googleai_dart`. Do it **before** any router code.
2. **Does the founder accept Firebase in the stack at all?** Identity is Supabase-
   first; `firebase_ai` drags in `firebase_core`/`firebase_auth`/`firebase_app_check`.
   Contained, but his call.
3. **Free-tier quotas** for the Gemini Developer API via AI Logic under one forced
   routing call per message — verify for a daily-driver personal app.
4. **`general_chat` reply authored in the routing call?** Would collapse chat from
   2 LLM calls to 1 but mixes routing + BRP coaching text. Recommend: ship with the
   separate coach call (today's behavior), measure, then decide.
5. **Watch `google_cloud_ai_generativelanguage_v1beta`** — if it matures past 1.0
   with sane auth, it's the official path off Firebase; the `RouterLlm` interface
   makes that a contained swap.

## Related
- DEC-050 (the decision this operationalizes), DEC-024, DEC-037-B, DEC-022/029,
  DEC-020/021, DEC-049
- `21_personal_build_plan.md` §Phase 0.5
- `docs/research/agent-harness-source.md` (the source behind DEC-050)
- `22_research_account_durability.md` (the Phase 0 companion consult)
