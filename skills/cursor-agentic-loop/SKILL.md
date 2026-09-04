---
name: cursor-agentic-loop
description: >-
  Full agentic work loop for Cursor: step -1 markup bootstrap → index →
  brainstorm → plan-make → plan review → plan-exec → multi-phase review →
  docs-pr → human handoff. Plan review uses Opus 5 medium / GPT-5.6 300k
  medium / Fable 5.1 300k medium. Use when the user says cursor-agentic-loop, /cursor-agentic-loop,
  run the loop, agentic cycle, or wants the full workflow.
disable-model-invocation: true
---

# Cursor Agentic Loop

End-to-end workflow for Cursor. Inspired by [umputun/cc-thingz](https://github.com/umputun/cc-thingz).

```text
-1 Markup bootstrap (if needed, Grok 4.6)
→ 0 Index → 1 Brainstorm → 2 Plan Make → 3 Plan Review → 4 Plan Exec
→ 5 Agent Review → 6 Code Smells → 7 External Review → 8 Critical Review
→ 9 Docs & PR → 10 Human Review
```

## Required reading

1. [references/model-routing.md](references/model-routing.md)
2. [references/stage-report.md](references/stage-report.md) — **after every step**
3. [references/telemetry-hooks.md](references/telemetry-hooks.md) — real tokens/wall/subagents from Cursor hooks
4. [references/session-docs.md](references/session-docs.md) — brainstorm/planning → structured docs
5. [references/step-minus-one.md](references/step-minus-one.md) — missing manifest / markup

**Summary — models:**
- **−1**: Grok 4.6 (create `.llm/manifest.json` etc.)
- **0–2** parent: Opus 5 (1M context) или GPT-5.6 Sol (1M context) или Fable 5.1 Max 1M
- **3** plan review: Opus 5 **medium** / GPT-5.6 Sol **300k medium** / Fable 5.1 **300k medium**
- **4–6, 8–10**: Grok 4.6
- **7**: Gemini 3.8 Flash High (`cursor-agentic-loop-external-review`)

## How to run

You are the **orchestrator**. Read each skill and follow it. After every step, emit a Stage report.

| Step | Name | Skill / action | Model |
|------|------|----------------|-------|
| −1 | Markup bootstrap | [step-minus-one.md](references/step-minus-one.md) if no `.llm/manifest.json` | Grok 4.6 |
| 0 | Index | Below | Parent: Opus / GPT-5.6 Sol / Fable 5.1 |
| 1 | Brainstorm | `~/.cursor/skills/cursor-agentic-loop-brainstorm/SKILL.md` | Parent Opus/Sol/Fable → write `docs/agentic/...` |
| 2 | Plan Make | `~/.cursor/skills/cursor-agentic-loop-plan-make/SKILL.md` | Parent Opus/Sol/Fable → plan + session docs |
| 3 | Plan Review | Task → `cursor-agentic-loop-plan-review` | Opus 5 `[effort=medium,context=300k]` (fallback GPT-5.6 Sol medium 300k -> Fable 5.1 medium 300k) |
| 4 | Plan Exec | `~/.cursor/skills/cursor-agentic-loop-plan-exec/SKILL.md` | Grok 4.6 |
| 5–8 | Reviews | `~/.cursor/skills/cursor-agentic-loop-review/SKILL.md` | Grok + Gemini external |
| 9 | Docs & PR | `~/.cursor/skills/cursor-agentic-loop-docs-pr/SKILL.md` | Grok; promote needs-documenting |
| 10 | Human Review | Stop; hand off | — |

**Entry shortcuts:**

- `full` — −1→10 (enforce gates)
- `from-plan` — skip −1…3; start at 4
- `review-only` — 5→8
- `pr-only` — 9→10

Announce step number/name on every advance. **After every step** (and when pausing mid-step for user gates), print a **Stage report** in chat and append it to `docs/agentic/<session>/telemetry.md` — see [references/stage-report.md](references/stage-report.md). Skipping telemetry is a process failure.

Example:

```markdown
### Stage report — Step 1 · Brainstorm
- status: in progress
- model_parent: GPT-5.6 Sol
- models_subagents: []
- agents_used: []
- tools: Read/Write/Shell
- files_touched: 3 (docs/agentic/20260903-iron-reputation-calendar/*)
- tokens: n/a (not exposed)
- context: n/a
- wall_time: n/a
- cost_notes: markdown-only session docs in Plan mode
- artifacts: docs/agentic/20260903-iron-reputation-calendar/{README,brainstorm,needs-documenting}.md
- next: continue Q&A → design → plan-make
```

**Get real numbers from Cursor hooks instead of `n/a`** — see [references/telemetry-hooks.md](references/telemetry-hooks.md). The collector is installed user-wide at `~/.cursor/hooks/`; at Step 0 check it is there and firing (`telemetry-report.py status`), otherwise offer `~/cursor-agentic-loop/install.sh`.

```bash
python3 ~/.cursor/hooks/telemetry-report.py mark "Step N · Name"    # step start
python3 ~/.cursor/hooks/telemetry-report.py report --step N --name "Name"   # step end
```

After the last completed step, print **Loop cost summary** (wall + tokens + subagent counts) per `references/stage-report.md` (`telemetry-report.py summary`). Persist to `docs/agentic/<session>/telemetry.md`.

## Manifest + gitignore (mandatory)

Project agent state lives in **`.llm/`**, and `.llm/manifest.json` is the only part of it that is committed:

| Path | Committed | What |
|------|-----------|------|
| `.llm/manifest.json` | yes | navigation index |
| `.llm/telemetry/` | no | hook ledger (`events.jsonl`) |
| `.cursor/` | no | local Cursor config/hooks/rules |

The project `.gitignore` must contain `.cursor/` and `.llm/telemetry/` — never `.llm/` as a whole.

`.llm/manifest.json` may list **only git-trackable paths** (`git check-ignore` must be empty for each `documents[].path`).

- Do **not** index ignored session scratch (`docs/agentic/…` if ignored).
- If a **business / runbook** doc created in the loop is ignored: **un-ignore** it (prefer `/docs/*` + `!/docs/business/**`, not `/docs/`), then add it to the manifest. Details: [references/step-minus-one.md](references/step-minus-one.md).

## Step −1 — Markup bootstrap

Follow [step-minus-one.md](references/step-minus-one.md).  
If `.llm/manifest.json` (or equivalent project markup) is missing → create `.llm/` and the manifest with **Grok 4.6**, add the gitignore entries, Stage report, then continue. A legacy `.cursor/manifest.json` → move to `.llm/manifest.json`.

## Step 0 — Index + model gate

1. **Initial picker check (обязательное уточнение):**
   Проверить модель в текущем родительском пикере. Если в пикере **не** Grok 4.6 High, **не** Opus 5 (1M), **не** GPT-5.6 Sol (1M) и **не** Fable 5.1 Max 1M:
   - **Обязательно остановить выполнение и явно уточнить у пользователя:**  
     *«В текущем пикере выбрана модель `[Текущая модель]`. Точно ли вы хотите использовать её, а не одну из рекомендованных (Grok 4.6 High, Opus 5 1M, GPT-5.6 Sol 1M, Fable 5.1 Max 1M)?»*
   - Не продолжать без подтверждения.
2. **Parent model gate для планирования (steps 0–2):** если планируется полный цикл (brainstorm / plan-make), модель родителя должна быть Opus 5 (1M context), GPT-5.6 Sol (1M context) или Fable 5.1 Max 1M. На лёгких/быстрых моделях (включая Grok) предложить переключиться (кроме явных shortcuts вроде `skip model gate`, `from-plan`, `review-only`).
3. Read `.llm/manifest.json` → `AGENTS.md` → `CLAUDE.md` → `README.md`.
4. Note language, test command, key packages, relevant business docs.
5. `git status -sb` + `git log --oneline -5`.
6. 5–10 line index summary → Stage report → step 1 (or skip brainstorm).

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
