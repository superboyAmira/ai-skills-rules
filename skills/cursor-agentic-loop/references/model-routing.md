# Model routing (cursor-agentic-loop)

## Can Cursor switch models by itself?

| Layer | Can agent switch? | How |
|-------|-------------------|-----|
| **Parent chat** | **No** | User picks in the model picker. |
| **Task / custom subagents** | **Yes** | Task `model` or `model:` in `~/.cursor/agents/*.md`. |
| **Max / context size** | **Partial** | Max Mode + params like `context=300k` / `context=1m`. Subagent list follows models **enabled + visible** in the picker. |

## Required routing

| Steps | Role | Model | Mechanism |
|-------|------|-------|-----------|
| **−1** | Markup bootstrap (missing manifest etc.) | `cursor-grok-4.6-high-fast (or higher if possible)` | Task / Grok parent for this step only |
| **0–2** | Parent (index, brainstorm, plan-make dialogue) | **Claude Opus 5** Max/1M **or** **GPT-5.6 Sol** Max/1M | User picker. Prefer Opus. |
| **3** | Plan auto-review | `claude-opus-5[effort=medium,context=300k]` → fallback `gpt-5.6-sol[effort=medium,context=300k]` | `cursor-agentic-loop-plan-review` |
| **4** | Task implementers + fixer | `cursor-grok-4.6-high-fast (or higher if possible)` | Task / inherit if parent is Grok |
| **5–6, 8** | 5 reviewers + smells + critical + fixer | `cursor-grok-4.6-high-fast (or higher if possible)` | `cursor-agentic-loop-{quality,implementation,testing,documentation,simplification,fixer}` |
| **7** | External review | `gpt-5.3-codex[effort=medium]` | `cursor-agentic-loop-external-review` |
| **9–10** | Docs/PR + handoff | Grok Fast OK | `cursor-agentic-loop-docs-pr` |

## Slugs

```text
BOOTSTRAP         = cursor-grok-4.6-high-fast (or higher if possible)
PLANNING_PARENT   = claude-opus-5          # Max/1M; else gpt-5.6-sol Max/1M
PLAN_REVIEW_AGENT = claude-opus-5[effort=medium,context=300k]
FALLBACK_PLAN_REV = gpt-5.6-sol[effort=medium,context=300k]
EXEC_REVIEW       = cursor-grok-4.6-high-fast (or higher if possible)
EXTERNAL_REVIEW   = gpt-5.3-codex[effort=medium]
```

If a pinned model is blocked, announce fallback and continue with the closest same-tier Agent model.

## Parent gate (steps 0–2)

If parent is clearly light/fast (Grok Fast, Composer Fast, Haiku, Luna) and the user asked for full planning:

1. **Stop** before deep design/plan writing (Step −1 bootstrap may still run on Grok).
2. Ask user to switch to **Opus 5 (Max / 1M)** or **GPT-5.6 Sol (Max / 1M)**.
3. Do not silently proceed on a light model for 0–2.

Exception: `skip model gate`, `from-plan`, `review-only`.

## Steps 0–2: no fast subagent fan-out

| Allowed | Forbidden |
|---------|-----------|
| Parent Opus / Sol tools | Task on Grok Fast for research during brainstorm/plan-make |
| Optional Task on Opus / Sol only | Parallel “map the repo” on Grok during 0–2 |
| `cursor-agentic-loop-plan-review` at step 3 | Inheriting Grok because parent is Grok |

Step **−1** is the exception: markup bootstrap **must** use Grok Fast.
