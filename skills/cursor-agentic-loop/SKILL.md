---
name: cursor-agentic-loop
description: >-
  Full agentic work loop for Cursor inspired by cc-thingz: index → brainstorm →
  plan-make → plan review → plan-exec → multi-phase review → docs-pr → human
  handoff. Forces fat models on 0–3 (Opus 4.8 / GPT-5.6 Sol Max) and Grok +
  Codex on review. Use when the user says cursor-agentic-loop, /cursor-agentic-loop, run the
  loop, agentic cycle, or wants the full 0→10 workflow.
disable-model-invocation: true
---

# Agentic Loop

End-to-end workflow for Cursor. Inspired by [umputun/cc-thingz](https://github.com/umputun/cc-thingz).

```text
0 Index → 1 Brainstorm → 2 Plan Make → 3 Plan Review → 4 Plan Exec
→ 5 Agent Review → 6 Code Smells → 7 External Review → 8 Critical Review
→ 9 Docs & PR → 10 Human Review
```

## Model policy (read first)

Read [references/model-routing.md](references/model-routing.md).

**Summary:**
- Parent chat model **cannot** be changed by the agent — user must pick it.
- Steps **0–3**: require **Opus 4.8 Max/1M** or **GPT-5.6 Sol Max/1M** (run parent gate).
- Steps **4–6, 8–10**: **Grok 4.5 High Fast** for orchestrator/review/fixer Tasks.
- Step **7**: **GPT-5.3 Codex Medium** via `agentic-external-review`.

## How to run

You are the **orchestrator**. For each step, **read the referenced skill** and follow it. Do not skip gates without user consent.

| Step | Name | Skill / action | Model |
|------|------|----------------|-------|
| 0 | Index | Below | Parent: Opus / GPT-5.6 Sol |
| 1 | Brainstorm | `~/.cursor/skills/cursor-agentic-loop-brainstorm/SKILL.md` | Parent: Opus / GPT-5.6 Sol |
| 2 | Plan Make | `~/.cursor/skills/cursor-agentic-loop-plan-make/SKILL.md` | Parent: Opus / GPT-5.6 Sol |
| 3 | Plan Review | Auto-review via Task → custom agent `agentic-plan-review` | Opus 4.8 `[effort=high,context=1m]` (fallback GPT-5.6 Sol) |
| 4 | Plan Exec | `~/.cursor/skills/cursor-agentic-loop-plan-exec/SKILL.md` (tasks only) | Grok 4.5 High Fast |
| 5–8 | Reviews | `~/.cursor/skills/cursor-agentic-loop-review/SKILL.md` | Grok + Codex external |
| 9 | Docs & PR | `~/.cursor/skills/cursor-agentic-loop-docs-pr/SKILL.md` | Grok Fine |
| 10 | Human Review | Stop; hand off | — |

**Entry shortcuts** (ask if unclear):

- `full` — 0→10 (enforce model gate)
- `from-plan` — skip 0–3; start at 4 (Grok OK)
- `review-only` — 5→8
- `pr-only` — 9→10

Announce the current step number/name whenever you advance.

## Step 0 — Index + model gate

1. Run the parent model gate from model-routing.md (unless shortcut skips 0–3).
2. Build a short working index:
   - `.cursor/manifest.json` → `AGENTS.md` → `CLAUDE.md` → `README.md`
   - language, test command, key packages
   - `git status -sb` + `git log --oneline -5`
3. Show a 5–10 line summary; continue to step 1 (or ask to skip brainstorm).

## Gates (must ask)

- After brainstorm design: Write plan / Start small / Stop
- After plan-make: Auto review / Revise / Implement / Stop
- Before plan-exec: confirm plan path + commit-per-task (default: no commits)
- After reviews: Docs & PR / Stop for manual tweaks
- Before push/PR: explicit confirmation

## Autonomy rules

- Subagents implement and fix; orchestrator coordinates
- Prefer custom agents under `~/.cursor/agents/agentic-*.md` (pinned models)
- No force-push, no merge, no skipping failing tests silently
- Commits/push only per user rules / explicit consent

## Progress UX

Maintain TodoWrite aligned to active steps (0–10). One-line status on each transition.

## Related

- Skills: cursor-agentic-loop-brainstorm, cursor-agentic-loop-plan-make, cursor-agentic-loop-plan-exec, cursor-agentic-loop-review, cursor-agentic-loop-docs-pr
- Agents: `~/.cursor/agents/agentic-*.md`
