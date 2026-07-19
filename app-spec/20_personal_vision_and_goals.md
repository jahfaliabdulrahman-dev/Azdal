# Personal Vision & Goals — Why Azdal Exists

> This document holds the founder's own reasons, feelings, goals, and
> ambitions for Azdal, and the tone the coach must take. It is not decoration —
> it is the "why" that every technical decision serves, and it is as binding as
> anything in the spec pack. When a design choice conflicts with what's written
> here, this wins.
>
> Written down deliberately so it survives context resets, model changes, and
> the move into Claude Projects — the emotional truth of this project is easy to
> lose and expensive to lose.

## The founder's own words (July 2026), faithfully

The founder said, unprompted and with real weight, that regardless of the
hackathon outcome he **personally needs this app to work for his own life**. He
is in genuine financial stress — his phrase: *"دائماً مضغوط وما عندي فلوس"*
(always under pressure, no money) — and he wants Azdal to be the tool that
actually gets him out of it. Not a demo. Not a portfolio piece. A real tool for
a real problem he is living.

What he needs it to do, in his own framing (preserved because the specificity is
the point — generic "budgeting features" would miss it):

- Know, **right now**, whether he can buy this specific thing at this price.
- Decide a **BNPL/Tamara installment** — can he take it or not.
- Tell him whether a purchase will **wreck his goals**.
- See **forward**: will next month's planned expense (a maintenance bill) put
  pressure on him *this* month? Where will he be financially in 2–3 months?
- Give **in-the-moment situational budgets**: taking the family out — how much
  can he spend right now? Can he afford dinner at this price?
- Help him build an **emergency fund**, and real **savings**.
- When an unexpected expense is **forced on him**, tell him **fast** whether it
  hurts, and if so, how to **soften the blow**.
- Show him his **bad habits** and how to replace them with something better.
- Help him tell a **need from a want** — can he live without this, or is it a
  luxury?
- Tell him whether a decision is a good **investment** or an **operational
  expense** with recurring costs that will hurt him later.
- Be **always available**, **specialized** (not generic), and reachable **fast,
  without many steps**.
- Plan **with him**, respecting cultural context, so it **never forces him to
  lie to it** to get past a tone-deaf question.
- Be something he can **actually trust** — that feels like it understands him
  and that its judgment is wise.
- Understand his **level of thinking and his personality**.

## The core commitment — "my success is the branch's success"

His own words: *"نجاحه من نجاحي — إن أنا نجحت، إن أنا استطعت أن أغيّر من عادتي،
أن أدخر، أن يصير عندي مبلغ طوارئ، حينها أعرف أن التطبيق جاهز وعلى استعداد
للانتقال للمرحلة التالية."*

Translation: its success is *my* success. If I succeed — if I manage to change my
habits, save, build an emergency fund — then I'll know the app is genuinely ready
for the next stage.

He drew the analogy himself, from his own modest stock-market experience: when a
company's board and CEO hold a large amount of stock in their own company, that
signals real belief — **skin in the game**. He wants to be exactly that: the
product's own first, real, all-in user. His personal financial turnaround is the
literal acceptance criterion for the personal build — **not a feature checklist,
not a demo score.**

His closing instruction: *"أريد شيء حقيقي، تطبيق حقيقي، نعطيه كل الوقت وكل الجهد
وكل ما يلزم"* — I want something real, a real app, we give it all the time, all
the effort, everything it needs.

**How to honor this concretely:** the personal build's "definition of done" is
not clean code or passing tests — it is his real, measured trajectory (logging
consistency, emergency-fund progress, savings rate, and honestly, the app's own
prediction accuracy). See `21_personal_build_plan.md` §"my success is the
branch's success" for how that's made falsifiable rather than vague. Do not let
this decay into a vibe. If the numbers say it isn't helping him, that is the
truth the app is built to face.

## The coach's tone — blunt honesty, never flattery, never gloating

This is a direct design directive from the founder, reasoned through carefully,
not a passing preference.

**Default to blunt honesty over diplomatic softening**, even when the truth is
uncomfortable. His logic: someone who genuinely comes seeking change has to be
ready for hard truths. An app that flatters him — or that he can fudge numbers to
get past — is worthless for real behavior change, and risking real money on an
app that just goes along with his wishes defeats the entire purpose. He invoked
*"خير الأمور أوسطها"* (moderation in most things) but carved out the exception
precisely: when someone has explicitly come **seeking change**, tightening
(*"الشد"*) rather than loosening is the caring choice, not cruelty. He also named
a distinct mechanism — some people are *"غائبين"* (checked-out, in denial) and
need a real **shock / spark** moment to actually begin changing; softening the
truth in that moment removes the one thing that would have worked.

**The critical nuance — no gloating, ever.** After he ignores the coach's advice
and does something anyway, the coach must respond **neutrally and re-plan** —
never smug, never "I told you so." This is not a retreat from honesty; it
protects the thing honesty depends on. If the coach makes him feel judged after
being ignored, he stops logging honest data, and everything downstream —
projections, habit tracking, the whole model — becomes fiction. So: **unsparing
in the truth itself, zero smugness in the delivery afterward.** These are
compatible, not contradictory, and both must live in the coach's system prompt
when it's written (Fable's plan flags this as a Phase-1 prompt task).

This also governs how **Claude** should talk to the founder about the project
itself: give him real assessments and real numbers directly, skip the diplomatic
cushioning, because that is explicitly what he asked for and what works for him.
He has repeatedly rewarded blunt, code-grounded honesty over reassurance across
this project's history.

## On "understand my personality" — the honest version

He asked for a coach that understands his level of thinking and personality. The
honest truth, surfaced in the Fable consult: real adaptive personality inference
is not achievable well right now, and pretending otherwise would be its own kind
of dishonesty in a trust product. The achievable, honest version is an **explicit
preference profile he edits himself** (direct vs. gentle, numbers-first vs.
summary-first) plus facts he chooses to tell it, remembered and never re-asked.
The app will *feel* like it knows him because it remembers what he told it and
doesn't make him repeat himself — that is real and sufficient, and it doesn't
overpromise a mind-reading it can't deliver.

## The agent he imagines — concrete examples (his words, 2026-07-19)

> Captured during a personal-build planning session. His diagnosis of today's
> app: it feels **مقيّد / آلي** (constrained / robotic) — a rule engine, not an
> agent that remembers him, connects his numbers, takes initiative, and reaches
> into the world. These four examples are the acceptance target for "a real,
> effective, intelligent agent" — concrete behaviours, not adjectives.

1. **Detect a habit and proactively propose a cheaper substitution, saving
   computed.** e.g. "you buy coffee every day → a machine + ground coffee saves
   you X/month" — pushed as a notification, not waited-for.
2. **Carry real domain knowledge — financial principles, current market products,
   new investment options — and actively push him toward investing, convincing
   him with evidence/proofs.** The "من مديون إلى مستثمر" thesis made active.
3. **Reason about unit economics / consumption patterns.** e.g. "you keep buying
   small milk → switch to the family size, it saves X"; or on demand: "should I
   buy the small or the large, and how does each hit my budget?"
4. **Decide cash-allocation: pay off debt vs. invest.** "I have cash and an
   installment I could clear with it — better to pay it off and be done, or keep
   paying installments and put the cash into an investment?"

**Underlying capabilities implied:** memory (never re-ask; connect his numbers to
his goals/history); pattern detection over his own data; proactivity (initiate at
the right moment); world-facing tools (price/product/market lookup — grounded,
never invented); domain knowledge + evidence-based persuasion — all steering the
debt→emergency→invest trajectory. Delivery mechanism = the DEC-050 tool-calling
router, extended with **world-facing tools**, plus a **proactivity engine** and a
**memory layer**.

**The trust reconciliation (how "smart" and "trustworthy" coexist):** split the
two domains. Anything computing *his money* (disposable, DTI, verdicts, savings)
stays **deterministic Dart** (DEC-024) — the model never computes it. The *world*
side (search a price, propose a cheaper alternative, weigh options, initiate)
gets **real tools and free reasoning** — but every external fact/price must come
from a **real fetched source, never invented** (extend "the LLM never fabricates
numbers" to prices/products). Intelligence lives on the world side; trust lives on
the money side; they don't conflict.

**Two honest guardrails on this vision (do not lose these):**

- **Most of it is data-gated.** Habit/consumption detection (examples 1 & 3) is
  only honest with ~4 weeks of consistent logging and a fixed category taxonomy
  (so قهوة/كوفي/مقهى don't fragment). The intelligence is *built on* the logging,
  not separable from it — logging is the substrate even when it isn't the felt
  bottleneck.
- **The invest side has a line the app must not cross.** Example 4 is the crown
  jewel and the thesis itself — and usually its honest answer is "pay the
  high-cost debt off first" (a guaranteed return that beats an uncertain market
  one). The app **may** compute that tradeoff with his real numbers and teach the
  principle; it **must not** recommend a specific security/fund or promise a
  market return — regulated, personalized investment advice and a trust landmine.
  Teach the framework and do the math; never pick the instrument. (Consistent with
  this doc's honest-limits stance and `21`'s "investment-quality judgment stays
  his".)

## Related

- `21_personal_build_plan.md` — the phased plan that operationalizes all of this
- `12_decision_log.md` — DEC-049 (personal build direction), DEC-050 (the
  tool-calling router that makes the expanded coach maintainable)
- `00_product_discovery.md` — the original product vision and market thesis
- `docs/research/financial-knowledge-layer.md` — the behavioral-science
  foundation (Fogg, Eyal, Kahneman) the coaching is meant to rest on
