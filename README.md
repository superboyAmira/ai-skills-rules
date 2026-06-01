# ai-skills-rules

Personal Cursor skills, rules & MCP servers synced across machines via Git.

Source: `~/.cursor/skills`, `~/.cursor/rules`, `~/.cursor/mcp.json`  
Remote: [github.com/superboyAmira/ai-skills-rules](https://github.com/superboyAmira/ai-skills-rules)

## Quick start

```bash
chmod +x sync.sh
cp config.env.example config.env   # edit SYNC_MODE
./sync.sh run
```

## Modes

| Mode | What it does |
|------|--------------|
| **producer** | Copies skills, rules, MCP config into this repo. Commits and **pushes only when files changed**. |
| **consumer** | `git pull` once. If remote has updates, copies repo → `~/.cursor/`. No pull → no overwrite. |

### Producer setup (main machine)

```bash
cp config.env.example config.env
# SYNC_MODE=producer  (default)

./sync.sh producer          # manual run
./sync.sh install-launchd   # daily at 09:00
```

### Consumer setup (other machines)

```bash
git clone git@github.com:superboyAmira/ai-skills-rules.git ~/ai-skills-rules
cd ~/ai-skills-rules

cp config.env.example config.env
# set SYNC_MODE=consumer

./sync.sh consumer          # manual run
./sync.sh install-launchd   # daily pull
```

## Commands

```bash
./sync.sh run                 # uses SYNC_MODE from config.env
./sync.sh producer            # force producer
./sync.sh consumer            # force consumer
./sync.sh status              # show config + recent logs
./sync.sh install-launchd     # macOS: daily scheduler via launchd
./sync.sh uninstall-launchd   # remove scheduler
```

Schedule time (before `install-launchd`):

```bash
LAUNCHD_HOUR=9 LAUNCHD_MINUTE=30 ./sync.sh install-launchd
```

## What gets synced

| Path | Synced | Notes |
|------|--------|-------|
| `~/.cursor/skills/` | yes | Personal skills |
| `~/.cursor/rules/` | yes | Created on first sync if missing |
| `~/.cursor/mcp.json` | yes | MCP servers (see security below) |
| `~/.cursor/skills-cursor/` | no | Built-in Cursor skills — enable via `SYNC_SKILLS_CURSOR=1` |

Excluded from rsync: `.DS_Store`, `__pycache__/`, `node_modules/`, `.git/`

## MCP sync & secrets

On **producer**, before commit:

- API keys / tokens in `env` and `headers` → replaced with `YOUR_*_HERE` placeholders
- Absolute home paths (e.g. filesystem MCP args) → `${HOME}`

On **consumer**, after pull:

- Server list and structure updated from repo
- **Local secrets preserved** — existing non-placeholder values in `~/.cursor/mcp.json` are not overwritten
- Local-only MCP servers (not in repo) are kept

Fill in secrets on each machine after first consumer sync.

## Logs

```
~/ai-skills-rules/logs/sync.log
```

## Files

```
ai-skills-rules/
├── sync.sh              # main script
├── scripts/
│   └── mcp_sync.py      # sanitize + merge MCP config
├── config.env           # local config (gitignored)
├── config.env.example   # template
├── skills/              # mirrored from ~/.cursor/skills
├── rules/               # mirrored from ~/.cursor/rules
└── mcp/
    └── mcp.json         # sanitized MCP config from ~/.cursor/mcp.json
```
