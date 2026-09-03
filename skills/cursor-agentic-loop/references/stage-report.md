# Stage telemetry (after every step)

After **each** completed step (−1…10), print a **Stage report** block before moving on. Do not skip.

```markdown
### Stage report — Step N · <Name>
- status: done | skipped | blocked
- model_parent: <id or unknown>
- models_subagents: [<id>, ...]
- agents_used: [<cursor-agentic-loop-*>, ...]
- tools: Read/Grep/Task/... (counts if known)
- files_touched: N (list key paths, max 10)
- tokens: <input/output/total if Cursor exposes them; else `n/a (not exposed)`>
- context: <window setting e.g. 300k/1M; estimated used % if known; else `n/a`>
- wall_time: <if known>
- cost_notes: <pool hints if known: first-party vs API>
- artifacts: <paths written this step>
- next: Step N+1 · <Name>
```

Rules:
- Prefer real numbers from Cursor usage UI / response metadata when available.
- If tokens/context are not exposed to the agent, say so explicitly — still fill every other field.
- Include failed/retried subagents in the report.
- Keep the block compact; no essay.
- **wall_time is mandatory:** clock time of the step (ISO local or `Xm Ys`). Include user-gate wait; note idle/abort separately.
- **tokens:** `in/out/total` from usage metadata. Never invent billed numbers. If missing: `n/a (not exposed)`.
- Keep a running ledger for steps −1…10 (`started_at`, `ended_at`, `wall`, `subagents`, `tokens`).

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
