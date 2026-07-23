---
name: cursor-agentic-loop-brainstorm
description: >-
  Collaborative design dialogue before implementation — idea to approaches to
  design to plan. Use when the user says cursor-agentic-loop-brainstorm, brainstorm, let's brainstorm, help me
  design, explore options for, think through, deep analysis, or wants thorough
  analysis of a feature/architecture before coding.
disable-model-invocation: true
---

# Brainstorm

Turn ideas into designs through collaborative dialogue **before** implementation.
Inspired by [cc-thingz brainstorm](https://github.com/umputun/cc-thingz).

## Model

Agentic-loop **step 1**. Parent should be **Opus 4.8 Max/1M** or **GPT-5.6 Sol Max/1M**.  
If the parent is clearly light/fast (Grok Fast, Composer Fast, etc.), stop and ask the user to switch before deep design — see `~/.cursor/skills/cursor-agentic-loop/references/model-routing.md`.

### Hard ban: no Grok / fast research subagents

Brainstorm is a **parent-only dialogue**, not a fan-out job.

- **Do NOT** launch Task / Explore / generalPurpose subagents on `cursor-grok-4.5-high-fast` (or any fast/light model) to “map the codebase” during brainstorm.
- Gather context with **Read / Glob / Grep / Shell in this parent session** (fat model does the reasoning).
- If parallel research is truly needed, only spawn Tasks with **Opus 4.8** or **GPT-5.6 Sol** (`claude-opus-4-8[effort=high]` / `gpt-5.6-sol[effort=high]`), and still synthesize + ask the user **yourself** in the parent.
- Never treat subagent map reports as the brainstorm outcome — approaches and design still come from the parent after user answers.

## Custom rules (optional)

If `.cursor/brainstorm-rules.md` or `.claude/brainstorm-rules.md` exists and is non-empty, treat it as additional instructions (project-level wins). Do not embed rules verbatim into the design output.

## Process

### Phase 1: Understand

1. Gather context first: relevant files, docs, recent commits (`git log --oneline -10`).
2. Prefer project index if present: `.cursor/manifest.json`, `AGENTS.md`, `CLAUDE.md`, `README.md`.
3. Ask questions **one at a time** (multiple choice preferred).
4. Focus on: purpose, constraints, success criteria, integration points.

### Phase 2: Explore approaches

Once the problem is understood:

1. Propose **2–3 approaches** with trade-offs.
2. Lead with a recommendation and why.
3. Present conversationally — not a formal doc yet.
4. Wait for the user to pick a direction.

Skip only if the path is obvious or the user already specified the approach.

### Phase 3: Present design

1. Break the design into sections of ~200–300 words.
2. After each section, ask if it looks right before continuing.
3. Cover: architecture, components, data flow, error handling, testing.
4. Be ready to backtrack.

### Phase 4: Next steps

After design is validated, ask:

| Option | Action |
|--------|--------|
| Write plan | Read and follow `~/.cursor/skills/cursor-agentic-loop-plan-make/SKILL.md` with brainstorm context |
| Start now | Implement directly only if scope is small |
| Done | Stop; user keeps the design |

## Principles

- One question per message
- Multiple choice when possible
- YAGNI ruthlessly
- Always explore alternatives before settling (unless obvious)
- Lead with a recommendation; let the user decide
- Prefer duplication over premature abstraction when coupling is the cost — ask if unclear

## Output

Do **not** write code in this skill. Design only. Plans go through `cursor-agentic-loop-plan-make`.
