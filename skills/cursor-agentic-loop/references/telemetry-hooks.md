# Collecting real telemetry from Cursor hooks

Stage reports must not guess numbers. Cursor exposes real token counts, durations and
subagent stats through **hooks**, so wire them up once per project and read the ledger
instead of writing `n/a`.

Reference: [Cursor hooks docs](https://cursor.com/docs/agent/hooks) and the forum thread
[How to obtain token usage per request](https://forum.cursor.com/t/how-to-obtain-token-usage-per-request/168317/8).

## What hooks actually expose

| Field in Stage report | Source hook | Payload fields |
|---|---|---|
| `tokens` | `stop` | `input_tokens`, `output_tokens`, `cache_read_tokens`, `cache_write_tokens` |
| `model_parent` | any hook | `model`, `model_id`, `model_params[]` |
| `context` | `preCompact` | `context_tokens`, `context_window_size`, `context_usage_percent` |
| `wall_time` | `beforeSubmitPrompt` → `stop` | join on `generation_id`; whole session on `sessionEnd.duration_ms` |
| `agents_used`, `models_subagents` | `subagentStart` / `subagentStop` | `subagent_type`, `subagent_model`, `status`, `duration_ms`, `tool_call_count` |
| `tools` | `postToolUse`, `postToolUseFailure` | `tool_name`, `duration`, `failure_type` |
| `files_touched` | `afterFileEdit`, `subagentStop` | `file_path`, `modified_files[]` |

Four rules the collector must respect:

1. **`input_tokens` already includes `cache_read_tokens` + `cache_write_tokens`.** For a
   non-overlapping figure use `max(0, input − cache_read − cache_write)`.
2. **Counts are cumulative per turn, not per message.** `stop` and `afterAgentResponse`
   report identical numbers for the same `generation_id` — pick `stop` as the single source
   of truth and never sum both.
3. **Token fields are optional.** Treat them as possibly absent; do not default to `0`.
4. **Reasoning tokens are not exposed**, and `subagentStop` has no token counts — report
   subagent cost as duration/tool calls, not tokens.

Transcript JSONL files only contain `{role, message}`, so there is no token data to recover
there after the fact. If hooks were not installed during a step, the honest value is
`n/a (hooks not installed)`.

## Install the collector

The collector lives in `~/.cursor/hooks/` and is installed user-wide by
[cursor-agentic-loop](https://github.com/superboyAmira/cursor-agentic-loop)'s `install.sh`,
alongside the skills and agents:

```bash
cd ~/cursor-agentic-loop && ./install.sh      # skills + agents + hooks
```

That writes `~/.cursor/hooks/{telemetry-collect.sh,telemetry-report.py,merge-hooks.py,hooks.template.json}`
and merges the wiring into `~/.cursor/hooks.json` (existing hooks are preserved, re-running
is idempotent). From then on **every project on this machine** collects telemetry — nothing
to set up per repo.

The install is **user-wide only** — there is no per-project variant, so nothing about the
collector ever lands in a repo. One consequence: cloud agents load project hooks but never
user hooks, so cloud runs produce no telemetry (report `n/a (cloud run, user hooks not loaded)`).

To remove it:

```bash
python3 ~/.cursor/hooks/merge-hooks.py --target ~/.cursor/hooks.json \
  --template ~/.cursor/hooks/hooks.template.json --uninstall
```

The collector is deliberately safe for a hot path: it whitelists scalar fields only (never
prompt text, thinking text, file diffs or tool output), appends one JSON line per event,
rotates at 20 MB, and always prints `{}` with exit `0` so a broken collector can never block
the agent.

### Where the ledger lands

One ledger per project, even though the hook is global:

- `<workspace>/.llm/telemetry/events.jsonl` when the project has a `.llm` directory (Step −1 creates it)
- `~/.cursor/telemetry/<project>-<hash>/events.jsonl` otherwise
- `$CURSOR_LOOP_TELEMETRY_DIR` overrides both

The ledger is never committed: the project `.gitignore` lists `.llm/telemetry/`, and the
collector additionally drops a self-ignoring `.gitignore` (`*`) into the directory, so a
user-wide hook cannot dirty the git status of a project that has not set that up yet.
Only `.llm/manifest.json` is shared — see [step-minus-one.md](step-minus-one.md).

## Use it during the loop

```bash
# at the start of each step
python3 ~/.cursor/hooks/telemetry-report.py mark "Step 6 · Code smells"

# when the step ends → paste into chat + telemetry.md
python3 ~/.cursor/hooks/telemetry-report.py report --step 6 --name "Code smells"

# before Docs & PR / stop
python3 ~/.cursor/hooks/telemetry-report.py summary

# sanity check that hooks are firing
python3 ~/.cursor/hooks/telemetry-report.py status
```

Run these from the project directory — the reporter resolves the ledger from the current
working directory.

`report` prints the Stage report block with every measurable field filled from the ledger
and `<fill: …>` placeholders for the judgement fields (`status`, `artifacts`, `next`).
Fill those in yourself — never ship a report with placeholders left in it.

Example of a generated block:

```markdown
### Stage report — Step 6 · Code smells
- status: done
- model_parent: grok-4.6 (effort=xhigh, fast=true)
- models_subagents: [claude-opus-5-thinking-high]
- agents_used: [cursor-agentic-loop-quality (completed, 45s, 8 tool calls)]
- tools: Read×12/Shell×4; 1m 20s in tools
- files_touched: 2 (internal/a.go, internal/b.go)
- tokens: in 1 180 993 / out 8 146 / total 1 189 139 (uncached in 14; cache read 1 007 022, write 173 957) over 6 turn(s)
- context: 120 000/128 000 (85%) at last compaction; compactions: 1
- wall_time: 12m 04s (12:36:19→12:48:23 UTC)
- cost_notes: 6 turn(s), 1 subagent(s), 214 hook events
- artifacts: internal/service/achievements/iron_reputation.go
- next: Step 7 · External review
```

## Caveats

- A `stop` hook fires per **turn**, so a step spanning several user messages aggregates
  several turns — that is why the report says `over N turn(s)`.
- Hook telemetry covers the **parent** agent's tokens. Subagent token usage is not exposed;
  it still lands in your billing, so treat the parent total as a lower bound.
- `wall_time` from the ledger includes user gate waits. Note idle time separately when a
  step sat waiting for a human.
- If `status` shows `stop events carrying tokens: 0`, the hooks are firing but your Cursor
  build does not populate token fields — report `n/a (not exposed)` and keep the rest.

## Cross-check with the Admin API (teams)

Hook data is local and per turn. For billed numbers, a team admin can reconcile via
`POST https://api.cursor.com/teams/filtered-usage-events` (Basic auth, API key as username):

```bash
curl -X POST https://api.cursor.com/teams/filtered-usage-events \
  -u YOUR_API_KEY: \
  -H "Content-Type: application/json" \
  -d '{"startDate": 1748411762359, "endDate": 1751003762359, "email": "you@company.com"}'
```

Each event carries `model`, `conversationId`, `tokenUsage.{inputTokens,outputTokens,cacheWriteTokens,cacheReadTokens}`
and `chargedCents`. Join it to the ledger on `conversation_id` to attribute real spend to a
loop session. Data is hourly-aggregated — poll at most once per hour.
