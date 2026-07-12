---
name: book-club
type: mode-shift
description: >
  Multi-persona reader reception feedback: fan out several reader-sim-style
  personas spread across taste and comfort-zone axes, then synthesize their
  reactions into a simulated discussion. Use when the author wants to know
  how different audiences will receive a piece, as distinct from craft
  critique. Dispatches book-club-reader subagents; the calling agent acts as
  moderator.
model-invocable: true
---

# Book Club

Simulates how a spread of differently-tasted readers would receive a draft,
then stages a discussion between them. This is reception signal, not craft
diagnosis — pair with `/prose-critique` or `/editorial-review` when the
author also wants analytical fixes.

The four reader instances never talk to each other. Each reads independently
and reports back; you, the calling agent, read all four reports and author
the discussion yourself. This keeps cost down (four cheap reads plus one
synthesis, not a live many-turn conversation) and keeps each persona's
report uncontaminated by the others before synthesis.

## 1. Choose four personas, specific to this draft

Don't reuse a fixed genre roster — infer the taste axes that actually matter
for *this* piece (genre, tone, content intensity, pacing, subject matter,
whatever is load-bearing here) and place four personas along them:

1. **Target** — the inferred ideal audience for this piece.
2. **Opposite** — a reader for whom this piece is squarely outside their
   comfort zone.
3. **Middle-ground A** — shares real taste overlap with the target, but
   diverges from them on one axis.
4. **Middle-ground B** — the inverse of A: opposes A on the axis where A
   diverges from target, while still sharing other target-adjacent taste.
   A and B should genuinely clash with each other on that axis, not just be
   two flavors of "target-lite."

State all four persona definitions explicitly before dispatching, per
`/reader-sim`'s persona-declaration convention — name each one's genre
familiarity, taste, tolerance for ambiguity, and knowledge boundary.

## 2. Dispatch

Fan out four parallel `book-club-reader` calls, one per persona. Attach the
draft to each and give each its own persona description — nothing else
needs to differ between the calls. Wait for all four reports before moving
on; do not start synthesis on partial results.

## 3. Stage the discussion yourself

Using the four static reports as source material, author a discussion in
this fixed order: **target → middle-ground A → opposite → middle-ground
B**, repeated three times (twelve beats total). No further subagent calls —
this step is you writing, not more dispatch.

Each beat should engage with what came before, not restate that persona's
original report verbatim: agree, push back, complicate, or notice something
a prior speaker missed. Let the personas clash where their reports actually
diverge — don't manufacture false consensus.

Apply `/editorial-review`'s `resources/reader-sim-signal.md` throughout:

- **Preserve each persona.** Keep their distinct voice, taste, and tolerance
  consistent turn to turn — a persona shouldn't suddenly reason like a
  different one.
- **Flag convergence as high-confidence.** When two or more personas land on
  the same passage for different reasons, that's a strong signal — surface
  it explicitly in the discussion.
- **Treat divergence as worth investigating, not averaging.** When personas
  disagree, let the discussion explore *why* rather than resolving it by
  majority vote — a piece can legitimately split its audience.

## 4. Close with a synthesis

End with a short consolidated summary, separate from the transcript:
strengths, weaknesses, and where personas genuinely agreed vs. split —
specific, actionable notes for the author, not just a recap of the
discussion.

## 5. Export the report (default — do this every run)

Write the full output — persona definitions, the twelve-beat discussion, and
the closing synthesis — to a file, following the same `work/critique-reports/`
convention every other critic in this roster already uses (see
`writing-artifacts`): one subfolder per piece, one uppercase file per report
type inside it.

```text
work/critique-reports/<piece-slug>/BOOK-CLUB.md
```

Derive `<piece-slug>` from the draft's filename or title (e.g.
`octavius-and-nolan-ravenfield.md` → `octavius-and-nolan-ravenfield/`). If a
critique-reports folder for this piece already exists, write alongside the
other reports there rather than creating a new one. This happens by default
regardless of which project or workspace layout you're running in — locate
`work/` at the active project's root the same way any other critic report
would, and create `critique-reports/<piece-slug>/` if it doesn't exist yet.
Tell the author where you saved it.
