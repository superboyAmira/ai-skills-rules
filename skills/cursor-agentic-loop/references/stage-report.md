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
