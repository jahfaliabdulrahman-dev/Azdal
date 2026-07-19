# Research — World-Facing Tools (real price / product / market lookup)

> **Provenance.** A Fable-model deep-design consult (2026-07-19), grounded in reads
> of `CLAUDE.md`, `20_personal_vision_and_goals.md`, `23_research_tool_calling_router.md`,
> `24_research_memory_and_proactivity.md`, `25_research_financial_intelligence_engines.md`,
> DEC-050/024, `gemini_service.dart`, `pubspec.yaml`; verified against official 2026
> docs (URLs inline; unverified marked). This is the 4th of the personal-build
> consults and the answer to the founder's core ask: an agent that reaches into the
> real world and "shows its receipts." Acceptance target = doc 20's 4 examples.

## Bottom line

1. **Feasible now on the SDK we're already migrating to.** `firebase_ai` ships
   `Tool.googleSearch()` (GA since v2.3.0, current 3.12.1; official Dart sample,
   doc updated 2026-07-03). Grounded search returns citable `groundingMetadata`
   (sources, per-sentence support spans, the required Search-Suggestions HTML).
   https://firebase.google.com/docs/ai-logic/grounding-google-search
2. **Two calls, not one.** Do NOT mix `Tool.googleSearch()` into the DEC-050 router
   call. Router stays forced-`ANY` function-calling only; a world tool's `run()`
   makes a **second, separate, stateless grounded call** with `Tool.googleSearch()`
   only. Mixing built-in + custom tools is Preview, Gemini-3-only, needs multi-turn
   history (breaks DEC-050 rule 5), no AUTO mode, and has open firebase_ai bugs.
   https://ai.google.dev/gemini-api/docs/tool-combination · https://github.com/firebase/flutterfire/issues/17687
3. **Honest limit:** grounded search gives *citable, current, approximately-precise*
   prices, not guaranteed live SKU prices. Good enough for the founder's examples
   **if the app is honest** — date-stamped "من بحث اليوم" + citation + his
   confirmation before any Dart math consumes the number.
4. **Anti-hallucination is structural:** no `groundingMetadata` ⇒ no price shown,
   ever — the code path that renders an ungrounded model sentence as a price does
   not exist (extends DEC-024's information-hiding).
5. **Binding ToS constraint:** you MAY store grounded text in the user's own chat
   history (≤2 years); you MAY NOT build a database/index from grounded results.
   So **never cache grounded prices into a reusable price table** — prices enter the
   ledger only after the founder confirms them (provenance → user-confirmed).
   https://ai.google.dev/gemini-api/terms#grounding-with-google-search
6. **Cost ~zero for one user:** Gemini 3 family = 5,000 free grounded prompts/month,
   then $14/1k queries. https://ai.google.dev/gemini-api/docs/google-search#pricing

## 1. Grounding with Google Search — verification

**Verified:** available as `Tool.googleSearch()` in `firebase_ai` (GA) and as
`google_search` on the Gemini Developer API; supported on `gemini-2.5-flash`,
`gemini-3.5-flash`, `gemini-3.1-flash-lite`; returns `groundingMetadata`
(`webSearchQueries`, `searchEntryPoint.renderedContent` = required Search
Suggestions widget HTML, `groundingChunks` with `web.uri` redirect + source
domain, `groundingSupports` mapping text segments → chunks). **A response WITHOUT
`groundingMetadata` is not grounded** (model answered from parameters even with the
tool on) — the key hazard §3 closes. Display obligations (ToS): render Search
Suggestions + sources, don't modify/intersperse grounded results, ≤5 suggestions,
no click-tracking. Storage (ToS): Google keeps grounding prompts 30 days; you may
store grounded text in end-user chat history ≤2 years and resubmit it in a
follow-up; you may NOT cache/index/train-on results or collect Links.
Sources: Firebase grounding doc (above) · https://ai.google.dev/gemini-api/docs/google-search ·
https://firebase.blog/posts/2025/07/grounding-google-search-ai-logic/ · ToS (above).

**Can it surface current real KSA retail prices?** Honestly: *sometimes precisely,
usually approximately, always citably.* Noon/Amazon.sa/Jarir/eXtra pages are
heavily indexed, so "سعر Apple Watch SE في نون" typically grounds to a real
listing; but snippet prices can be stale, and grocery unit prices (Tamimi milk
sizes — example 3) are poorly indexed. **Design consequence: every grounded price =
"found today at approximately X, source Y" — an evidence card, not an oracle —
requiring one-tap confirmation before any Dart engine consumes it.** This is the
only honest UX and doubles as the anti-hallucination gate.

**Latency:** grounded call adds ~2–6 s over the ~1 s router call **[UNVERIFIED —
measure on device, LL-010]**. Fine for an explicit "دوّر لي سعر" with a progress
state; banned in the background nudge path (doc 24 already bans LLM there).
**Durability flag:** the generateContent grounding docs are now labelled "(Legacy)"
with the new **Interactions API** promoted as GA/recommended; `firebase_ai` rides
generateContent — not urgent (it's Google's supported mobile path) but reinforces
doc 23's `RouterLlm`-interface hedge. **Arabic quality for Saudi retail queries is
[UNVERIFIED — must be tested].**

## 2. If grounding isn't precise enough — alternatives, honestly

- **SerpApi Google Shopping API — `gl=sa` (Saudi Arabia) officially supported
  (verified)**, returns structured title/price/merchant/link. Starter $25/mo =
  1,000 searches; free dev tier (~100/mo **[UNVERIFIED]**) enough to validate KSA
  coverage. Key must NOT ship in the APK → needs a tiny **math-free** proxy (a
  Supabase Edge Function is fine — DEC-024 bans Edge Functions for *financial math*,
  not for a fetch proxy). **The structured upgrade path — deferred until a real gap
  is measured.** https://serpapi.com/google-shopping-countries · https://serpapi.com/pricing
- Other SERP vendors — interchangeable; decide only if SerpApi's tier matters.
- **Amazon PA-API 5.0 — REJECTED** (deprecated 2026-05-15, closed to new customers).
- **Noon/Jarir/eXtra/Tamimi retailer APIs — none public** (Noon has only an
  affiliate program). Price-comparison sites (Pricena/Kanbkam) — no public APIs.
- **Direct scraping — REJECTED outright:** violates retailer ToS, KSA
  Anti-Cyber-Crime exposure, active bot-blocking, brittle — brand poison for a
  trust product.

**Recommended path (honest):** ship grounded search + citations; log every lookup
in `tool_calls` with a founder thumbs-up/down on "was this price real & useful?";
after ~4 weeks, if precision-misses are material, validate SerpApi free-tier (20
KSA queries, `gl=sa`, Arabic+English) and only then add it as a second provider
behind a `WorldPriceProvider` interface, server-proxied. Costs nothing now, adds no
APK secrets, converts the upgrade from speculation to data.

## 3. Anti-hallucination enforcement (5 Dart layers)

1. **Grounded-or-silent (core):** if `groundingMetadata == null || chunks.isEmpty`
   → the model text is **discarded unread**, deterministic Arabic fallback renders
   ("ما لقيت سعر موثوق له الحين — أجرب صياغة ثانية؟"). No metadata ⇒ text never
   reaches UI — the world-side analogue of "no FunctionResponse round-trip."
2. **Whole-or-nothing + numeral cross-check:** ToS forbids *modifying* grounded
   results → validate then accept/reject whole. Dart extracts every price numeral
   (Arabic-Indic normalized, reuse DEC-036 normalizer), checks each falls in a
   `groundingSupports` segment mapping to ≥1 chunk; any unsupported price ⇒ discard
   whole → retry once tighter → else notFound.
3. **Provenance gate before any math:** a grounded price is **evidence, not data**,
   until confirmed. Card shows grounded text verbatim + sources + Search
   Suggestions widget + date + a one-tap "السعر صحيح" chip (existing DEC-020/021
   staged-confirm). Only on confirm does Dart write a `price_observations` row
   (`source:'user_confirmed_from_search'`, `url`, `seen_at`) and hand the number to
   `SubstitutionService`/`UnitEconomicsService`/`PurchaseDecisionService` — the
   "fetched cited price" slot doc 25 §2 reserved. Keeps ToS clean (stored number is
   the founder's adopted input; no auto-built price index). **[UNVERIFIED legal
   interpretation — reasonable-effort posture, not counsel.]**
4. **Router/coach never price anything:** structural for the router; for BRP replies
   add a prompt rule + few-shots ("never state a price/spec/market fact; propose
   searching") + a cheap Dart guard (ريال/SAR + digits not in the user message or
   Dart context → replace with fallback, flag the trace).
5. **Auditability:** extend `tool_calls` — `outcome_kind` gains
   `'world_render'|'world_not_found'`; store `web_search_queries`, `grounded bool`,
   `chunk_domains text[]`, `price_candidates jsonb`, `confirmed bool`. "Why did it
   say 550?" = one query (LL-011 extended to the world side).

## 4. Router integration (two-call architecture)

```
user: "لقيت نفس الساعة بـ800 في جرير — فيه أرخص؟"
 └─ CALL 1 (router, unchanged DEC-050): forced ANY, custom tools only, no built-ins
      → find_cheaper_alternative(item:"ساعة…", known_price_sar:800, known_retailer:"جرير")
 └─ tool.run() in Dart:
      CALL 2 (world): separate stateless generateContent,
        model: gemini-3.5-flash (pin explicitly), tools:[Tool.googleSearch()] ONLY,
        systemInstruction: bounded world-prompt, contents:[Dart-composed Arabic query]
        ← his ledger/income/budget NEVER enters this call (privacy + DEC-024)
      → Dart validates (§3) → WorldOutcome
 └─ render; NOTHING returns to Call 1 (no round-trip; invariant intact)
```

Three coarse tools (one-file `RouterTool` each, `tier: none`): `search_price(item,
retailer_hint?, user_quoted_price_sar?)`, `find_cheaper_alternative(item, mode:
same_item_cheaper|substitute_habit, user_quoted_price_sar?)`, `get_market_info(topic)`.
New `WorldOutcome extends ToolOutcome { groundedTextAr, sources, searchSuggestionsHtml,
candidates, fetchedAt }`. The only write is the price-confirm chip → `price_observations`.

**Who speaks:** world side — the card headline **is the grounded model text,
verbatim** (the one principled exception to "Dart speaks out," safe because §3
guarantees it's source-backed and the ToS requires verbatim display; needs
`webview_flutter` for the Suggestions HTML). Money side — any budget-impact line is
Dart-computed from *confirmed* numbers, rendered as a separate section under the
world card. Two voices, visually + architecturally distinct, no bleed.

**Composition with 24/25:** world tools fill doc 25's reserved "fetched cited price"
slot (V1 "ask him for prices" stays the fallback when lookup fails); doc 24 nudges
stay zero-LLM in background, but an opened nudge card may offer "أدوّر لك سعر آلة
قهوة؟" routing through `find_cheaper_alternative` (the predicted seam). The ToS
no-database rule means nudges cite only *confirmed* `price_observations` (with
dates), never silently remembered grounded prices.

## 5. Market / investment information (example 2)

`get_market_info` = same grounded call, info-only, consistent with doc 25 §4:
**DO** grounded cited answers ("وش يعني صندوق مؤشرات؟", KSA savings programs) with
sources + date. **DON'T** — the world-call system prompt carries doc 25's refusal
rule + "which stock? → framework not instrument" few-shot; the card gets a **fixed
Dart-authored footer** "معلومة عامة من مصادر منشورة — مو توصية استثمارية" (hardcoded,
un-softenable); the output carries no `candidates`, so **there is no code path from
market info into any financial engine** (`evaluatePayoffVsInvest` stays categorical).
Prompt-level "don't recommend" is softer than the price guarantee (can't regex
Arabic advice); mitigations = fixed footer + golden-matrix refusal rows + founder
review; revisit before any multi-user future.

## 6. Mapping to the 4 examples
1. **Coffee → machine:** V1 = he supplies prices (doc 25). V2 =
   `find_cheaper_alternative(substitute_habit)` grounds a real machine price + cite
   → confirm → Dart computes break-even. **Fully buildable.**
2. **Market/investment awareness:** `get_market_info`, grounded + cited, info-side
   only; persuasion = Dart computing *his* numbers + general education, never
   instrument picks. **The line holds.**
3. **Small vs family milk:** world tools are a **weak spot** (grocery unit prices
   poorly indexed) — primary path stays doc 25's OCR/volunteered + `UnitEconomicsService`
   on demand; `search_price` is a bonus when it hits.
4. **Payoff vs invest:** world tools contribute **nothing numeric** — 100%
   deterministic Dart (doc 25 §3); at most a separate `get_market_info` education
   card alongside.

## 7. Cost / latency / dependencies
- Cost: founder-scale far inside 5,000/month free; 1k paid ≈ $14; SerpApi (if ever)
  $25/mo. Effectively free.
- Latency: +2–6 s grounded call **[measure on device]**; explicit action w/ progress
  state, never inline on money verdicts.
- New deps: `webview_flutter` (Suggestions HTML, ToS-required); inherits doc 23's
  stack → **also inherits the App Check × sideloaded-APK risk (doc 23 pitfall 1) —
  resolve first.**

## 8. Durability & build order
**Strong:** GA feature (not preview) on Google's recommended mobile SDK; zero
scraping/secrets; §3 enforcement is unit-testable with recorded `groundingMetadata`
fixtures; graceful honest degradation (fail → "ما لقيت" → doc-25 ask-the-user);
provider swap contained behind `WorldPriceProvider`.
**Watch:** generateContent "(Legacy)" vs Interactions API (thin interface is the
hedge); grounding pricing/quota churn (re-verify at build); `Tool.urlContext()`
exists but Public Preview w/ intermittent 500s — **defer**; ToS compliance is a
design input (no price DB, verbatim display, suggestions widget) — encode in the DEC
so a future refactor doesn't add a "price cache."
**Build order:** strictly after Phase 0 + Phase 0.5 (these are router tools). Within
the workstream: **W0** device spike (10 real KSA price queries through a grounded
call; measure hit-rate, accuracy vs live sites, Arabic quality — one afternoon
retires the biggest unknown) → **W1** `search_price` + `WorldOutcome` card + §3
enforcement + `price_observations` → **W2** `find_cheaper_alternative` +
composition into 25's engines → **W3** `get_market_info` → **W4 (conditional)**
SerpApi behind the provider interface, only if telemetry shows a real gap.

## 9. Open questions / unverified
1. **W0 spike results** — grounding hit-rate + price accuracy for KSA retail in
   Arabic: the decisive empirical unknown (LL-010 applies to world tools too).
2. Firebase AI Logic free-tier grounding quota + `gemini-3.5-flash` availability —
   console check, bundle with the doc-23 App Check check.
3. Price-confirmation tap friction vs auto-flow-with-undo for high-confidence single
   -source finds (recommend: keep the tap — it's the trust ceremony + ToS posture).
4. `webview_flutter` RTL rendering of `renderedContent` **[UNVERIFIED]**.
5. ToS gray zone (user-confirmed price → `price_observations`) — reasonable posture,
   revisit before multi-user.
6. Watch: Interactions API adoption; SerpApi validation at the W4 gate; Amazon
   "Creators API" SA eligibility (low priority).

## Related
- `20_personal_vision_and_goals.md` (examples + trust reconciliation),
  `23_research_tool_calling_router.md` (the router these plug into; App Check risk),
  `24_research_memory_and_proactivity.md` (nudge-card seam),
  `25_research_financial_intelligence_engines.md` (the engines these feed prices to;
  the advice line), DEC-050/024
