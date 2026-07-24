---
name: cursor-agentic-loop-review
description: >-
  Multi-phase post-implementation review: 5 parallel agents (Quality,
  Implementation, Testing, Documentation, Simplification) → Fixer loop (max 5),
  then smells, external Codex 5.3 Medium, critical-only. Use when the user says
  cursor-agentic-loop-review, review, agentic review, code smells, external review, critical review, or when
  cursor-agentic-loop-plan-exec / cursor-agentic-loop reaches review phases.
disable-model-invocation: true
---

# Review (agentic multi-phase)

Post-implementation multidimensional review. Inspired by cc-thingz + Agent Review slide.

**Models:** reviewers/fixer = `cursor-grok-4.5-high-fast`; external = `gpt-5.3-codex[effort=medium]`.  
Prefer custom agents `cursor-agentic-loop-*` in `~/.cursor/agents/` (models pinned in frontmatter).

After each review phase, emit a Stage report (`~/.cursor/skills/cursor-agentic-loop/references/stage-report.md`).

## When invoked

- After `cursor-agentic-loop-plan-exec` finishes tasks
- Standalone: review current branch/diff against a plan (or HEAD vs default branch)

## Setup

1. Resolve default branch (`main` / `master` / `trunk`).
2. Diff: `git diff <default>...HEAD` (else staged/unstaged).
3. Pass plan path to reviewers when known.
4. Append phase notes to `/tmp/progress-<stem>.txt` if present.

## Phase 1 — Agent Review & Test (5 parallel → Fixer loop)

**Цель:** многомерное ревью написанного кода **5 агентами параллельно**.

Report: `--- Review phase 1: Agent Review (5 parallel) ---`

### Parallel reviewers (always all five, same message)

Launch from the **main session** in **one** tool-call batch:

| Agent | Focus |
|-------|--------|
| `cursor-agentic-loop-quality` | Best practices |
| `cursor-agentic-loop-implementation` | Соответствие плану |
| `cursor-agentic-loop-testing` | Покрытие, краевые случаи |
| `cursor-agentic-loop-documentation` | Комментарии, докстринги |
| `cursor-agentic-loop-simplification` | Избыточность |

If custom agents are unavailable, spawn 5× Task `generalPurpose` with `model: cursor-grok-4.5-high-fast` and prompts from [references/reviewers.md](references/reviewers.md).

### Then Fixer

1. Collect **full** outputs (do not filter or dismiss).
2. If **all five** report `NO ISSUES FOUND` / zero issues → phase clean → go to phase 2.
3. Else spawn `cursor-agentic-loop-fixer` (or Task + [references/fixer.md](references/fixer.md)) with **verbatim** findings.
4. Show FIXES to the user.

### Loop: review → fixer → review

Repeat the **5 parallel reviewers → fixer** cycle until:

- no problems found, **or**
- **max 5 iterations** reached (`review_iterations = 5`)

On iterations 2–5, still run all five reviewers (full multidimensional pass), then fixer if needed.  
If max iterations hit with remaining issues, report and continue to phase 2 (do not silently drop findings — list leftovers).

## Phase 2 — Code smells

Report: `--- Review phase 2: code smells ---`

1. One Task/agent with smells prompt (`model: cursor-grok-4.5-high-fast`).
2. If findings → `cursor-agentic-loop-fixer`.
3. Single pass, then continue.

## Phase 3 — External review (Codex)

Report: `--- Review phase 3: external review (gpt-5.3-codex medium) ---`

Use custom agent `cursor-agentic-loop-external-review` (`model: gpt-5.3-codex[effort=medium]`).

Adversarial loop (max 5):

1. External review of diff vs plan; severities `CRITICAL` / `MAJOR` / `MINOR`.
2. `NO ISSUES FOUND` → done.
3. Else → fixer → if no remaining CRITICAL/MAJOR after fixes, stop (minors fixed once).
4. If blocking remain → loop.

Fallback if Codex unavailable: next different-family Agent model (e.g. `gpt-5.6-sol` or `gemini-3.1-pro`); announce fallback.

## Phase 4 — Critical only

Report: `--- Review phase 4: critical/major only ---`

One pass: `cursor-agentic-loop-quality` + `cursor-agentic-loop-implementation` (critical/major only) → fixer if needed. Model: Grok Fast.

## Hard rules

- Fan-out from the **orchestrator** (this session), never from nested subagents
- Never dismiss findings as pre-existing — fixer decides
- Pass findings verbatim to fixer
- No push; commits only if user explicitly asked
- Default `review_iterations = 5` for phase 1
