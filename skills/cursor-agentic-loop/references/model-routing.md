# Model routing (agentic-loop)

## Can Cursor switch models by itself?

| Layer | Can agent switch? | How |
|-------|-------------------|-----|
| **Parent chat** (main Composer/Agent session) | **No** | User picks model in the model picker. Agent cannot change it mid-chat. |
| **Task / custom subagents** | **Yes** | Pass `model` on Task, or pin `model:` in `~/.cursor/agents/*.md` frontmatter. |
| **Max / 1M context** | **Partial** | Enable Max Mode (legacy plans) + model params like `context=1m`. Subagent list follows models **enabled + visible** in your picker. |

Practical rule: for steps **0–3**, start (or switch) the chat yourself to a fat model. For steps **4–10**, keep parent on Grok Fast and pin subagent models.

## Required routing

| Steps | Role | Model | Mechanism |
|-------|------|-------|-----------|
| **0–3** | Parent (index, brainstorm, plan-make, plan review dialogue) | **Claude Opus 4.8** Max/1M **or** **GPT-5.6 Sol** Max/1M | User selects in picker before/at start. Prefer Opus. |
| **3** | Plan auto-review subagent | `claude-opus-4-8[effort=high,context=1m]` → fallback `gpt-5.6-sol[effort=high,context=1m]` | Custom agent `agentic-plan-review` |
| **4** | Task implementers + fixer during exec | `cursor-grok-4.5-high-fast` | Task `model` / inherit if parent is already Grok |
| **5–6, 8** | 5 parallel reviewers + smells + critical + fixer | `cursor-grok-4.5-high-fast` | `agentic-quality`, `agentic-implementation`, `agentic-testing`, `agentic-documentation`, `agentic-simplification`, `agentic-fixer` |
| **7** | External review | `gpt-5.3-codex[effort=medium]` | `agentic-external-review` |
| **9–10** | Docs/PR + handoff | Parent Grok Fast is fine | `cursor-agentic-loop-docs-pr` skill |

## Slugs (preferred)

```text
PLANNING_PARENT   = claude-opus-4-8   # Max Mode + 1M if available; else gpt-5.6-sol Max 1M
PLAN_REVIEW_AGENT = claude-opus-4-8[effort=high,context=1m]
FALLBACK_HEAVY    = gpt-5.6-sol[effort=high,context=1m]
EXEC_REVIEW       = cursor-grok-4.5-high-fast
EXTERNAL_REVIEW   = gpt-5.3-codex[effort=medium]
```

If a pinned model is blocked (plan / admin / not in picker), announce fallback and continue with the next best available Agent-capable model from the same tier intent (heavy vs fast vs external).

## Parent gate (steps 0–3)

At the start of `cursor-agentic-loop` / `cursor-agentic-loop-brainstorm` / `cursor-agentic-loop-plan-make`, if the parent model is clearly a fast/light model (e.g. Grok Fast, Composer Fast, Haiku, Luna) and the user asked for the full planning path:

1. **Stop** before deep design/plan writing.
2. Tell the user to switch the picker to **Opus 4.8 (Max / 1M)** or **GPT-5.6 Sol (Max / 1M)** and continue in this chat (or a new one).
3. Do not silently proceed on a light model for 0–3.

Exception: user explicitly says `skip model gate` or `from-plan` / `review-only`.

## Steps 0–3: no fast subagent fan-out

Common Cursor habit: spawn 3× Explore/generalPurpose on Grok Fast to “map” the repo during brainstorm. **Forbidden** for this loop.

| Allowed on 0–3 | Forbidden on 0–3 |
|----------------|------------------|
| Parent Opus / GPT-5.6 Sol tools (Read/Grep/…) | Task on `cursor-grok-4.5-high-fast` for research |
| Optional Task on Opus / Sol only | Parallel “map Kafka / trace paths / assess backfill” on Grok |
| `agentic-plan-review` (Opus) at step 3 | Inheriting Grok because parent is Grok |

**Why:** design decisions need long-context reasoning in one thread. Fast subagents return shallow maps, fragment context, and skip the one-question-at-a-time brainstorm gate — you get a fake “brainstorm” that is really a speed scout.
