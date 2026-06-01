# ai-skills-rules

Personal Cursor skills & rules synced across machines via Git.

Source: `~/.cursor/skills` and `~/.cursor/rules`  
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
| **producer** | Copies `~/.cursor/skills` (+ `rules` if present) into this repo. Commits and **pushes only when files changed**. |
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
| `~/.cursor/skills-cursor/` | no | Built-in Cursor skills — enable via `SYNC_SKILLS_CURSOR=1` |

Excluded from rsync: `.DS_Store`, `__pycache__/`, `node_modules/`, `.git/`

## Logs

```
~/ai-skills-rules/logs/sync.log
```

## Files

```
ai-skills-rules/
├── sync.sh              # main script
├── config.env           # local config (gitignored)
├── config.env.example   # template
├── skills/              # mirrored from ~/.cursor/skills (after first producer run)
└── rules/               # mirrored from ~/.cursor/rules
```
