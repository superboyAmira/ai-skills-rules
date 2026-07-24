---
name: cursor-agentic-loop
description: >-
  Full agentic work loop for Cursor: step -1 markup bootstrap → index →
  brainstorm → plan-make → plan review → plan-exec → multi-phase review →
  docs-pr → human handoff. Plan review uses Opus 4.8 medium / GPT-5.6 300k
  medium. Use when the user says cursor-agentic-loop, /cursor-agentic-loop,
  run the loop, agentic cycle, or wants the full workflow.
disable-model-invocation: true
---

# Cursor Agentic Loop

End-to-end workflow for Cursor. Inspired by [umputun/cc-thingz](https://github.com/umputun/cc-thingz).

```text
-1 Markup bootstrap (if needed, Grok Fast)
→ 0 Index → 1 Brainstorm → 2 Plan Make → 3 Plan Review → 4 Plan Exec
→ 5 Agent Review → 6 Code Smells → 7 External Review → 8 Critical Review
→ 9 Docs & PR → 10 Human Review
```

## Required reading

1. [references/model-routing.md](references/model-routing.md)
2. [references/stage-report.md](references/stage-report.md) — **after every step**
3. [references/session-docs.md](references/session-docs.md) — brainstorm/planning → structured docs
4. [references/step-minus-one.md](references/step-minus-one.md) — missing manifest / markup

**Summary — models:**
- **−1**: Grok 4.5 High Fast (create `.cursor/manifest.json` etc.)
- **0–2** parent: Opus 4.8 Max/1M or GPT-5.6 Sol Max/1M
- **3** plan review: Opus 4.8 **medium** / GPT-5.6 Sol **300k medium**
- **4–6, 8–10**: Grok 4.5 High Fast
- **7**: GPT-5.3 Codex Medium (`cursor-agentic-loop-external-review`)

## How to run

You are the **orchestrator**. Read each skill and follow it. After every step, emit a Stage report.

| Step | Name | Skill / action | Model |
|------|------|----------------|-------|
| −1 | Markup bootstrap | [step-minus-one.md](references/step-minus-one.md) if no manifest/markup | Grok 4.5 High Fast |
| 0 | Index | Below | Parent: Opus / GPT-5.6 Sol |
| 1 | Brainstorm | `~/.cursor/skills/cursor-agentic-loop-brainstorm/SKILL.md` | Parent Opus/Sol → write `docs/agentic/...` |
| 2 | Plan Make | `~/.cursor/skills/cursor-agentic-loop-plan-make/SKILL.md` | Parent Opus/Sol → plan + session docs |
| 3 | Plan Review | Task → `cursor-agentic-loop-plan-review` | Opus 4.8 `[effort=medium,context=300k]` (fallback GPT-5.6 Sol medium 300k) |
| 4 | Plan Exec | `~/.cursor/skills/cursor-agentic-loop-plan-exec/SKILL.md` | Grok 4.5 High Fast |
| 5–8 | Reviews | `~/.cursor/skills/cursor-agentic-loop-review/SKILL.md` | Grok + Codex external |
| 9 | Docs & PR | `~/.cursor/skills/cursor-agentic-loop-docs-pr/SKILL.md` | Grok; promote needs-documenting |
| 10 | Human Review | Stop; hand off | — |

**Entry shortcuts:**

- `full` — −1→10 (enforce gates)
- `from-plan` — skip −1…3; start at 4
- `review-only` — 5→8
- `pr-only` — 9→10

Announce step number/name on every advance. Print Stage report before the next step.

## Step −1 — Markup bootstrap

Follow [step-minus-one.md](references/step-minus-one.md).  
If `.cursor/manifest.json` (or equivalent project markup) is missing → create with **Grok 4.5 High Fast**, Stage report, then continue.

## Step 0 — Index + model gate

1. Parent model gate (Opus / GPT-5.6 Sol) unless shortcut skips planning.
2. Read `.cursor/manifest.json` → `AGENTS.md` → `CLAUDE.md` → `README.md`.
3. Note language, test command, key packages, relevant business docs.
4. `git status -sb` + `git log --oneline -5`.
5. 5–10 line index summary → Stage report → step 1 (or skip brainstorm).

## Documentation mandate

Brainstorm + planning dialogue **must** be written to structured files under `docs/agentic/yyyymmdd-<slug>/` (see session-docs.md). Chat-only outcomes are incomplete. Maintain `needs-documenting.md` for extra docs debt; step 9 clears or files tickets.

## Gates (must ask)

- After brainstorm: Write plan / Start small / Stop (session docs already written)
- After plan-make: Auto review / Revise / Implement / Stop
- Before plan-exec: plan path + commit-per-task (default: no commits)
- After reviews: Docs & PR / Stop
- Before push/PR: explicit confirmation

## Autonomy rules

- Subagents implement/fix; orchestrator coordinates
- Prefer `~/.cursor/agents/cursor-agentic-loop-*.md`
- No force-push, no merge, no silent red tests
- Commits/push only with user consent

## Related

- Skills: `cursor-agentic-loop-*` under `~/.cursor/skills/`
- Agents: `~/.cursor/agents/cursor-agentic-loop-*.md`
