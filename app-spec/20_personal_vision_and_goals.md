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

## Related

- `21_personal_build_plan.md` — the phased plan that operationalizes all of this
- `12_decision_log.md` — DEC-049 (personal build direction), DEC-050 (the
  tool-calling router that makes the expanded coach maintainable)
- `00_product_discovery.md` — the original product vision and market thesis
- `docs/research/financial-knowledge-layer.md` — the behavioral-science
  foundation (Fogg, Eyal, Kahneman) the coaching is meant to rest on
