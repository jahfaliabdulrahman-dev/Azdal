# Source — "Agent Harness" (the concept behind DEC-050)

> A primary source the founder brought to the project in July 2026, which
> triggered the tool-calling-router decision. Preserved here so the reasoning in
> **DEC-050** has its source of record. The analysis of how it applies to Azdal
> is in the decision log, not here.

## What it is

An Arabic YouTube video, title: **"لا يخدعونك! 😱 الحقيقة وراء وكلاء الذكاء
الاصطناعي (بناء وكيل ذكاء اصطناعي مشروع كامل)"**
(URL: https://www.youtube.com/watch?v=NkR7w-Qo8oc).

Read honestly: it is fundamentally a **promotional demo for an AI coding tool
("Verdent" / فيردنت)**, which it uses to build a sample "harsh job-interview
agent." The *concept* it teaches is legitimate and aligns with mainstream agent
engineering; the specific tool is incidental to Azdal.

## The concept, in the video's own framing

- A real agent isn't chat. You give it a task; it plans, uses tools, reads files,
  makes mistakes, **self-corrects**, and returns a final result.
- The **agent harness** is the "nervous system" — the code you write *around* the
  model to manage its execution loop. The model is a very smart brain "in a jar";
  the harness is everything that gives it hands and a process.
- You don't need LangChain or 50 libraries — you need to master this one concept.
- Their example is a **state machine** wiring tools together (not an open loop):
  setup (upload CV + job description) → the harness web-searches for current
  questions in that specialty → asks one question at a time → instead of letting
  the model reply, it calls a `logic_evaluator` tool (a faster/cheaper model) to
  score the answer → a final coding question runs the user's code in a safe
  `code_execution` sandbox tool and reacts to the real result.
- Prompt-engineering nods to Andrej Karpathy: treat the AI as a super-smart
  junior engineer who lacks your context; separate instructions with XML tags;
  make it plan before it writes code.

## Why it mattered for Azdal

The founder had an "aha — maybe this is the solution for Azdal." It is, for
exactly one component: replacing Azdal's brittle regex intent-gates with
model-driven, tool-calling dispatch. Crucially, the video's own example is a
**controlled state-machine-with-tools**, not a naive autonomous ReAct loop — the
right shape for a finance app that must never hallucinate a number.

**The full evaluation — what it fixes, what it doesn't, the discipline rules that
keep "the model never computes" intact, and why it's a single-hop dispatcher
rather than an autonomous agent — is DEC-050.** Do not re-derive it; read that
entry.

## The one thing NOT to copy from it

The video's agent "self-corrects" — reads an error, retries autonomously. That's
right for a *code-writing* agent. It is wrong for Azdal's *financial writes*: the
model must never autonomously retry a write to the ledger. Azdal's rule stands —
write-tools stage a proposal; Dart plus the user's tap commit. (DEC-050, rule 2.)
