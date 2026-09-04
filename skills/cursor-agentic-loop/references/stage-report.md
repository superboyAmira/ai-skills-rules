# Stage telemetry (after every step)

After **each** completed step (−1…10), print a **Stage report** block in chat **before** moving on. Do not skip. Also append the same block to `docs/agentic/<session>/telemetry.md`.

Print even when the step is still in progress (status: `in progress`) if you pause for user Q&A; print again with `done` when the step finishes.

## Required format

Use this shape (field names fixed; fill real values or `n/a`):

```markdown
### Stage report — Step N · <Name>
- status: done | in progress | skipped | blocked
- model_parent: <id or unknown>
- models_subagents: [<id>, ...]
- agents_used: [<cursor-agentic-loop-*>, ...]
- tools: Read/Grep/Task/Write/Shell/... (counts if known)
- files_touched: N (list key paths, max 10)
- tokens: <input/output/total if Cursor exposes them; else `n/a (not exposed)`>
- context: <window setting e.g. 300k/1M; estimated used % if known; else `n/a`>
- wall_time: <ISO local start→end or `Xm Ys`; mandatory when known>
- cost_notes: <pool hints / mode notes; else brief fact>
- artifacts: <paths written this step>
- next: Step N+1 · <Name> | <concrete next action>
```

### Example

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

## Where the numbers come from

Do **not** guess. Real tokens, durations, subagent stats and context usage come from Cursor
hooks — see [telemetry-hooks.md](telemetry-hooks.md) for the full field map and install steps.

The collector is installed user-wide at `~/.cursor/hooks/`. Run from the project directory:

```bash
python3 ~/.cursor/hooks/telemetry-report.py mark "Step 6 · Code smells"   # at step start
python3 ~/.cursor/hooks/telemetry-report.py report --step 6 --name "Code smells"   # at step end
python3 ~/.cursor/hooks/telemetry-report.py summary                       # before Docs & PR
```

Paste the generated block, replace every `<fill: …>` placeholder, then append it to
`telemetry.md`. Never leave a placeholder in a shipped report.

If the collector is **not** installed: offer to run `~/cursor-agentic-loop/install.sh` once,
and until then report `tokens: n/a (hooks not installed)` rather than inventing numbers.

Key semantics when reading raw hook data yourself:

- `input_tokens` already includes `cache_read_tokens` + `cache_write_tokens`; uncached input is `max(0, input − read − write)`.
- `stop` and `afterAgentResponse` repeat the same totals per `generation_id` — count `stop` only.
- Reasoning tokens and subagent tokens are not exposed; report subagent cost as duration + tool calls.

## Rules

- Prefer real numbers from the hook ledger; then Cursor usage UI / response metadata.
- If tokens/context are not exposed to the agent, say so explicitly — still fill every other field.
- Include failed/retried subagents in the report.
- Keep the block compact; no essay.
- **wall_time is mandatory when the clock is known:** ISO local or `Xm Ys`. Include user-gate wait; note idle/abort separately. If unknown: `n/a` (do not invent).
- **tokens:** `in/out/total` from usage metadata. Never invent billed numbers. If missing: `n/a (not exposed)`.
- Keep a running ledger for steps −1…10 in `telemetry.md` (`started_at`, `ended_at`, `wall`, `subagents`, `tokens`).
- Skipping the Stage report is a process failure — same severity as skipping session docs.

## Loop cost summary (after the last completed step, and before Docs & PR / Stop)

Print this table even if some cells are `n/a`. Also write it to `docs/agentic/<session>/telemetry.md`.

```markdown
### Loop cost summary
| Step | Name | Wall | Subagents | Tokens in/out/total | Notes |
|------|------|------|-----------|---------------------|-------|
| −1 | Markup | … | 0 | n/a | skipped |
| 0 | Index | … | 0 | n/a | |
| … | … | … | … | … | |
| **Σ** | | **…** | **N** | **…** | |

- session_wall: <first stage start → now>
- idle_excluded: <optional: abort/user-away subtracted>
- tokens_source: usage metadata | n/a (not exposed)
```

Do not skip the summary because tokens are missing — still show wall time and subagent counts.
