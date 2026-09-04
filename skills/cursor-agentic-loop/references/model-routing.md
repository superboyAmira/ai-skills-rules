# Model routing (cursor-agentic-loop)

## Can Cursor switch models by itself?

| Layer | Can agent switch? | How |
|-------|-------------------|-----|
| **Parent chat** | **No** | User picks in the model picker. |
| **Task / custom subagents** | **Yes** | Task `model` or `model:` in `~/.cursor/agents/*.md`. |
| **Context size / speed** | **Partial** | Params like `context=300k` / `context=1m`, plus per-model Fast variants. Max Mode exists only on legacy request-based plans. Subagent list follows models **enabled + visible** in the picker. |

## Required routing

| Steps | Role | Model | Mechanism |
|-------|------|-------|-----------|
| **−1** | Markup bootstrap (missing manifest etc.) | `cursor-grok-4.6-xhigh` | Task / Grok parent for this step only |
| **0–2** | Parent (index, brainstorm, plan-make dialogue) | **Claude Opus 5** (1M context) **или** **GPT-5.6 Sol** (1M context) **или** **Claude Fable 5.1** Max 1M | User picker. Prefer Opus. |
| **3** | Plan auto-review | `claude-opus-5[effort=medium,context=300k]` → fallback `gpt-5.6-sol[effort=medium,context=300k]` → fallback `claude-fable-5.1[effort=medium,context=300k]` | `cursor-agentic-loop-plan-review` |
| **4** | Task implementers + fixer | `cursor-grok-4.6-xhigh` | Task / inherit if parent is Grok |
| **5–6, 8** | 5 reviewers + smells + critical + fixer | `cursor-grok-4.6-xhigh` | `cursor-agentic-loop-{quality,implementation,testing,documentation,simplification,fixer}` |
| **7** | External review | `gemini-3.8-flash-high` (или `gemini-3.8-flash[effort=high]`) | `cursor-agentic-loop-external-review` |
| **9–10** | Docs/PR + handoff | Grok 4.6 OK | `cursor-agentic-loop-docs-pr` |

## Slugs

```text
BOOTSTRAP          = cursor-grok-4.6-xhigh
PLANNING_PARENT    = claude-opus-5          # 1M context; else gpt-5.6-sol 1M; else claude-fable-5.1 Max 1M
PLAN_REVIEW_AGENT  = claude-opus-5[effort=medium,context=300k]
FALLBACK_PLAN_REV  = gpt-5.6-sol[effort=medium,context=300k]
FALLBACK2_PLAN_REV = claude-fable-5.1[effort=medium,context=300k]
EXEC_REVIEW        = cursor-grok-4.6-xhigh
EXTERNAL_REVIEW    = gemini-3.8-flash-high  # or gemini-3.8-flash[effort=high]
```

Step 7 External Review uses **Gemini 3.8 Flash High** as an independent frontier perspective from a different family.
If a pinned model is blocked, announce fallback and continue with the closest same-tier Agent model.

## Initial picker check & Parent gate

### Обязательная проверка модели в пикере (Initial Picker Gate)
При старте работы (Step 0 или перед началом любого этапа) агент **обязан** проверить модель в родительском пикере.

**Разрешенные целевые модели по умолчанию:**
1. **Cursor Grok 4.6 High** (для быстрого шага −1 и фаз исполнения 4–10)
2. **Claude Opus 5 (1M context)** (рекомендуется для planning 0–2)
3. **GPT-5.6 Sol (1M context)** (planning 0–2)
4. **Claude Fable 5.1 Max 1M** (planning 0–2)

**Строгое правило обязательного уточнения:**
Если в изначальном пикере выбрана **любая другая модель**, кроме четырех вышеперечисленных (например, Claude Sonnet, Gemini Flash/Pro, GPT-5.6 Luna/Terra, Composer, Haiku и др.):
- **ОБЯЗАТЕЛЬНО остановить выполнение и явно уточнить у пользователя:**
  > *"В текущем пикере выбрана модель `[название модели]`. Точно ли вы хотите использовать именно её, а не одну из рекомендованных (Grok 4.6 High, Opus 5 1M, GPT-5.6 Sol 1M, Fable 5.1 Max 1M)?"*
- Не продолжать работу без подтверждения пользователя.

### Parent gate для планирования (steps 0–2)
Если для этапов 0–2 (глубокий brainstorm / plan-make) в пикере выбран Grok 4.6 (или любая быстрая/лёгкая модель), и пользователь не подтвердил осознанный выбор:
1. **Stop** перед глубоким проектированием / составлением плана (Step −1 bootstrap допустимо выполнить на Grok).
2. Предложить пользователю переключиться на **Opus 5 (1M context)**, **GPT-5.6 Sol (1M context)** или **Fable 5.1 Max 1M**.
3. Не продолжать молча на Grok 4.6 для 0–2.

Исключения: `skip model gate`, `from-plan`, `review-only`.

## Steps 0–2: no fast subagent fan-out

| Allowed | Forbidden |
|---------|-----------|
| Parent Opus / Sol / Fable tools | Task on Grok 4.6 for research during brainstorm/plan-make |
| Optional Task on Opus / Sol / Fable only | Parallel “map the repo” on Grok during 0–2 |
| `cursor-agentic-loop-plan-review` at step 3 | Inheriting Grok because parent is Grok |

Step **−1** is the exception: markup bootstrap **must** use Grok 4.6.
