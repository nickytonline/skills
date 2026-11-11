---
name: context-checkpoint
version: 1.0.0
description: Use at a task boundary, when a coding session's context has grown large, or before starting a long autonomous loop, to write a lean handoff and reset or compact context.
user-invocable: true
argument-hint: "[task or next goal]"
---

# Context checkpoint

Every assistant step re-reads the whole context, so cost is roughly context size multiplied by number of steps. A step at 800K tokens costs about 8x a step at 100K. Checkpoint at natural boundaries, not when the window is nearly full.

## When to run

- A feature, fix, or plan is done or agreed.
- Context is dominated by tool output (screenshots, snapshots, logs, full file reads) that is no longer needed.
- Before kicking off a long autonomous loop (Stop hook, /loop, multi-level implementation).

## Steps

1. **Assess.** State in one or two lines what is done, what is in progress, and whether the remaining work needs the current context or only a summary of it.
2. **Promote durable facts.** Anything that will stay true (architecture, conventions, how to run, test, or deploy) belongs in AGENTS.md or a docs file, not the handoff. Propose the edit and ask before changing those files.
3. **Write the handoff** to `docs/handoff/YYYY-MM-DD-<slug>.md` (or the project's existing handoff location) using the template below. Keep it under about 150 lines. Link to files and line ranges instead of pasting code.
4. **Recommend the reset path:**
   - Default: `/clear`, then start the next session by reading the handoff file.
   - If the current context must stay: `/compact` with explicit keep and drop instructions, for example `/compact keep the policy model design and level 2 decisions, drop test output and screenshots`.

## Handoff template

```markdown
# Handoff: <task>

## Goal
One or two sentences.

## Current state
- What works now
- What is half done (file:line)

## Decisions made
- Decision and the reason, one line each

## Next steps
1. ...

## Open questions
- ...

## Key files
- path/to/file.ts: why it matters
```

## Before a long autonomous loop

- Define a concrete done condition and an iteration or step cap.
- Split large goals into checkpoints, and checkpoint between them.
- Delegate browser playtesting and other many-step, low-reasoning work to a subagent on Sonnet or Haiku. Only its summary should return to the main thread.
- Prefer one scripted Playwright run over many individual browser MCP calls.
- Pick the model now. Switching models mid-session rewrites the whole cache at the new model's price.
