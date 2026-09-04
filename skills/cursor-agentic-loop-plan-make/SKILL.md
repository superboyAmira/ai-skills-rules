---
name: cursor-agentic-loop-plan-make
description: >-
  Create a structured implementation plan in docs/plans/yyyymmdd-<task>.md,
  persist planning dialogue under docs/agentic/, then plan-review with Opus 5
  medium / GPT-5.6 300k medium / Fable 5.1 300k medium. Use when the user says
  cursor-agentic-loop-plan-make, plan-make, /cursor-agentic-loop-plan-make,
  write a plan, or after brainstorm Write plan.
disable-model-invocation: true
---

# Plan Make

Create `docs/plans/yyyymmdd-<slug>.md` + session planning docs.
Inspired by [cc-thingz planning:make](https://github.com/umputun/cc-thingz).

## Model

Steps **0–2** parent: **Opus 5 (1M context)** или **GPT-5.6 Sol (1M context)** или **Fable 5.1 Max 1M**.  
**Auto review (step 3):** custom agent `cursor-agentic-loop-plan-review` →  
`claude-opus-5[effort=medium,context=300k]` (fallback `gpt-5.6-sol[effort=medium,context=300k]` → fallback `claude-fable-5.1[effort=medium,context=300k]`).

## Documentation (mandatory)

Follow `~/.cursor/skills/cursor-agentic-loop/references/session-docs.md`.

- Write `docs/agentic/yyyymmdd-<slug>/planning.md` with full planning Q&A.
- Keep `needs-documenting.md` updated.
- Link the session folder from the plan Overview.
- Entire planning dialogue must not remain chat-only.

## Custom rules (optional)

`.cursor/planning-rules.md` or `.claude/planning-rules.md` (project wins).

## Step 0: Parse intent and gather context

Quick scan (< ~30s tool use):

1. Parse intent (feature / bug / refactor / migration / unclear).
2. Read/Glob/Grep only — no explore subagent.
3. ≤ ~5 files; prefer manifest / AGENTS / CLAUDE / README / brainstorm.md.
4. 3–5 bullet context summary.

## Step 1: Questions (one at a time)

1. Main goal  
2. Scope  
3. Constraints  
4. Testing: TDD vs code-first  
5. Short title / slug  

Record answers in `planning.md`.

## Step 1.5: Approaches

2–3 options with trade-offs unless obvious / already chosen in brainstorm. Record choice.

## Step 2: Write the plan file

1. `mkdir -p docs/plans docs/agentic/yyyymmdd-<slug>`
2. Create `docs/plans/yyyymmdd-<slug>.md` via [references/plan-template.md](references/plan-template.md).
3. Flush `planning.md` + update `needs-documenting.md`.
4. In plan Overview, link `docs/agentic/yyyymmdd-<slug>/`.

Hard requirements: numbered tasks, Files blocks, tests as separate checkboxes, acceptance + docs tasks at end.

## Step 3: Plan review gate

| Option | Action |
|--------|--------|
| Auto review | Task → `cursor-agentic-loop-plan-review` (`claude-opus-5[effort=medium,context=300k]`; fallback Sol medium 300k -> Fable 5.1 medium 300k). On NEEDS REVISION, fix plan + docs, re-ask |
| Revise with me | Interactive revision |
| Implement | → `cursor-agentic-loop-plan-exec` |
| Done | Stop |

No coding in this skill. Stage report after plan-make and after plan-review.

## Principles

- One question at a time; YAGNI; lead with recommendation
- Plan file = source of truth for `cursor-agentic-loop-plan-exec`
