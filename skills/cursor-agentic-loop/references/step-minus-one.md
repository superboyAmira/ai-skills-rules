# Step −1 — Project markup bootstrap

If the project has **no** navigation/markup index, create it **before** Step 0.

## When to run

Run Step −1 when **none** of these exist (or only empty stubs):

- `.cursor/manifest.json`
- `AGENTS.md`
- `CLAUDE.md`
- `.cursor/rules/*.mdc` project navigation rule that points at docs

If `.cursor/manifest.json` exists and is usable → **skip** Step −1.

## Model

**Cursor Grok 4.5 High Fast** only:

- Task `model: cursor-grok-4.5-high-fast`, or custom agent if present
- Do **not** use Opus/Sol for bootstrap indexing

## What to create

Minimum:

1. `.cursor/manifest.json` — index of important docs/code areas (`version`, `generated`, `module`, `documents[]` with `id`, `path`, `title`, `summary`, `tags`, `related`)
2. Optional if helpful: short `AGENTS.md` with test/lint commands and “where to look”
3. Optional: `.cursor/rules/project-context-manifest.mdc` with `alwaysApply: true` telling the agent to read the manifest first

Scan: README, `docs/`, `cmd/`, `internal/`, `deploy/`, existing business docs. Keep summaries factual; do not invent APIs.

## Gate

After writing files, show paths + Stage report for Step −1, then continue to Step 0 on the **planning parent model** (Opus / GPT-5.6 Sol).
