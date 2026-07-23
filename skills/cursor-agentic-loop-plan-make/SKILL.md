---
name: cursor-agentic-loop-plan-make
description: >-
  Create a structured implementation plan in docs/plans/yyyymmdd-<task>.md with
  interactive context gathering, approach selection, and plan review. Use when
  the user says cursor-agentic-loop-plan-make, plan-make,
  /cursor-agentic-loop-plan-make, write a plan, create implementation plan,
  or after brainstorm when they choose Write plan.
disable-model-invocation: true
---

# Plan Make

Create an implementation plan in `docs/plans/yyyymmdd-<slug>.md`.
Inspired by [cc-thingz planning:make](https://github.com/umputun/cc-thingz).

## Model

This is an agentic-loop **0–3** skill. Parent should be **Opus 4.8 Max/1M** or **GPT-5.6 Sol Max/1M**.  
If parent is a light/fast model, stop and ask the user to switch (see `~/.cursor/skills/cursor-agentic-loop/references/model-routing.md`).  
**Auto review** must use custom agent `agentic-plan-review` (Opus 4.8 high/1M; fallback GPT-5.6 Sol).

## Custom rules (optional)

If `.cursor/planning-rules.md` or `.claude/planning-rules.md` exists and is non-empty, apply as extra guidance (project-level wins). Do not paste rules into the plan file.

## Step 0: Parse intent and gather context

Before asking questions, do a **quick** scan (< ~30s of tool use):

1. Parse the request (feature / bugfix / refactor / migration / unclear).
2. Use Read/Glob/Grep directly — **do not** launch an explore subagent here.
3. Read at most ~5 files. Prefer `.cursor/manifest.json`, `AGENTS.md`, `CLAUDE.md`, `README.md`.
4. Synthesize 3–5 bullet context summary for the user.

## Step 1: Questions (one at a time)

Show context, then ask **one question per message** (multiple choice preferred):

1. Main goal
2. Scope (components/files)
3. Constraints
4. Testing approach: TDD vs code-first
5. Short plan title / slug

## Step 1.5: Approaches

Propose 2–3 implementation approaches with trade-offs; recommend one; wait for choice.

**Skip** if the approach is obvious, user already specified it, or it is a clear bug fix.

## Step 2: Write the plan file

1. Ensure `docs/plans/` exists (`mkdir -p docs/plans`).
2. Create `docs/plans/yyyymmdd-<slug>.md` using today's date.
3. Follow the structure in [references/plan-template.md](references/plan-template.md).

Hard requirements for tasks:

- Number tasks with concrete sequential integers (`Task 1`, `Task 2`, …)
- Each task: one logical unit, specific name, **Files:** block, ~5 checkboxes
- Tests are separate checklist items, not optional
- Last tasks: verify acceptance criteria + update docs / move plan to `completed/`

## Step 3: Plan review gate

After creating the file, tell the user the path, then ask:

| Option | Action |
|--------|--------|
| Auto review | Spawn Task with custom agent `agentic-plan-review` (or `model: claude-opus-4-8[effort=high,context=1m]`): completeness, over-engineering, missing tests, vague tasks. On NEEDS REVISION, fix the plan, then re-ask remaining options |
| Revise with me | Interactive revision in chat |
| Implement | Hand off to `cursor-agentic-loop-plan-exec` (read `~/.cursor/skills/cursor-agentic-loop-plan-exec/SKILL.md`) |
| Done | Stop |

Do **not** start coding in this skill.

## Principles

- One question at a time
- YAGNI; prefer duplication over premature abstraction when unclear
- Lead with a recommendation
- Plan file is the source of truth for later `cursor-agentic-loop-plan-exec`
