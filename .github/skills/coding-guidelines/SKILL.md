---
name: coding-guidelines
description: Behavioural guidelines that combine KISS (keep it simple) and DRY (don't repeat yourself, with restraint) with concrete rules for reducing common LLM coding mistakes — overcomplication, premature abstraction, ungrounded assumptions, scope creep, and silent edits to unrelated code. Use when writing, reviewing, or refactoring code on behalf of the user — features, bug fixes, refactors, or scaffolding. Do NOT invoke for prose, docs, comms, or pure-research tasks where no code ships.
---

# Coding Guidelines

Five principles that bias toward shipping the smallest, clearest code that solves the actual problem. They cost a little speed for a lot of correctness — for genuinely trivial tasks, use judgement.

## 1. KISS — Keep It Simple

**Smallest code that meets the requirement. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code — inline it.
- No "flexibility", "configurability", or extension points the user didn't request.
- No error handling for cases that can't happen. Validate at system boundaries; trust internal callers and framework guarantees.
- No backwards-compat shims when nothing depends on the old shape — just change the code.
- If you wrote 200 lines and it could be 50, rewrite it before reporting done.

**Self-test:** would a senior engineer say *"couldn't you just do this instead?"* If yes, simplify before they have to ask.

## 2. DRY — But With Restraint

**Three identical lines beat a premature abstraction.**

The rule of three is a *floor*, not a ceiling. Apply DRY only when:

- You have **three or more** real, current usages — not two plus one imagined.
- The duplication is **conceptual**, not coincidental. Lines that look similar today but represent independent decisions will diverge tomorrow.
- The abstraction has **one obvious name and shape**. Hesitation between `process_X`, `handle_X`, and `transform_X` means it isn't ready.

When in doubt, leave the duplication. Re-converging similar code later is cheap; untangling a wrong abstraction is expensive.

## 3. Surface, Don't Assume

**State assumptions. Name confusion. Surface tradeoffs.**

Before implementing:

- List your load-bearing assumptions. If any are uncertain — file path, schema shape, library API, the user's actual goal — verify (`Read`, `Grep`, run the command) or ask, before writing more than a tiny amount of code.
- If two interpretations of the request both fit, present both with the tradeoff and let the user pick. Don't choose silently.
- If existing code contradicts itself, flag it. If the request will break a different feature, say so before shipping.
- No sycophancy. *"Great question!"* / *"You're absolutely right!"* is noise. If the user is wrong about something load-bearing, say so directly with the reason.

## 4. Surgical Changes

**Touch only what the task requires. Clean up only what your change made obsolete.**

When editing existing code:

- Don't tidy comments, rename variables, or reformat lines you weren't asked to touch.
- Don't refactor things that aren't broken on the way past.
- Match the surrounding style, even if you'd write it differently from scratch.
- If you spot unrelated dead code, mention it — don't delete it in this diff.

When your changes create orphans:

- Delete imports, variables, helpers, and config keys that **your** change made unreferenced.
- Don't leave commented-out blocks "in case we want them back" — that's what git is for.
- Don't leave `# TODO: clean this up later` markers. Clean it up now or accept the code as-is.

**The test:** every changed line should trace directly to the user's request.

## 5. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform fuzzy requests into verifiable goals before writing code:

- *"Add validation"* → *"Write tests for invalid inputs, then make them pass"*
- *"Fix the bug"* → *"Write a test that reproduces it, then make it pass"*
- *"Refactor X"* → *"Existing tests pass before and after; behaviour identical"*
- *"Make it faster"* → *"`bench/x.py` reports < 50ms p99"*

For multi-step tasks, state the plan as a checklist with explicit verification:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Then write the **naive-correct** version first. Don't reach for clever data structures or framework features unless they're the obvious fit. If performance matters, write the obvious version, measure, then optimise — keeping the naive version as a reference oracle.

Strong success criteria let you work independently. Weak criteria (*"make it work"*) require constant clarification, so push back and ask for sharper ones if the request gives you nothing to verify against.

## Output Discipline

- **Comments:** default to none. Write one only when *why* is non-obvious — a hidden constraint, a workaround for a specific bug, a surprising invariant. Don't narrate what the code does.
- **Docstrings:** one short line on non-public helpers. Rich docstrings only on public APIs.
- **Variable names:** boring is correct. `count` beats `numItemsProcessedSoFar`.
- **Reports:** brief. State what changed and what's verified. No process narration. The diff speaks for itself.

## TL;DR

> Smallest code that meets the success criteria. Verify assumptions instead of guessing. Surface tradeoffs instead of hiding them. Touch only what the task requires. Delete what you make obsolete.
