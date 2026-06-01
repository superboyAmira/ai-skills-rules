#!/usr/bin/env bash
# ai-skills-rules sync — producer pushes ~/.cursor skills/rules/mcp to git;
# consumer pulls from git into ~/.cursor once a day.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Config ────────────────────────────────────────────────────────────────────
load_config() {
  local config_file="$SCRIPT_DIR/config.env"
  if [[ -f "$config_file" ]]; then
    # shellcheck disable=SC1090
    source "$config_file"
  fi

  : "${SYNC_MODE:=producer}"
  : "${CURSOR_HOME:=$HOME/.cursor}"
  : "${REPO_DIR:=$SCRIPT_DIR}"
  : "${GIT_BRANCH:=main}"
  : "${GIT_REMOTE:=origin}"
  : "${SYNC_SKILLS:=1}"
  : "${SYNC_RULES:=1}"
  : "${SYNC_SKILLS_CURSOR:=0}"
  : "${SYNC_MCP:=1}"
  : "${MCP_REPO_FILE:=mcp/mcp.json}"
  : "${MCP_CURSOR_FILE:=mcp.json}"
  : "${RSYNC_DELETE:=1}"
  : "${LOG_FILE:=$REPO_DIR/logs/sync.log}"
}

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg"
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "$msg" >>"$LOG_FILE"
}

die() {
  log "ERROR: $*"
  exit 1
}

# ── rsync helpers ─────────────────────────────────────────────────────────────
RSYNC_EXCLUDES=(
  --exclude='.DS_Store'
  --exclude='__pycache__/'
  --exclude='*.pyc'
  --exclude='.git/'
  --exclude='node_modules/'
)

rsync_mirror() {
  local src="$1" dst="$2" delete_flag="${3:-0}"

  mkdir -p "$src" "$dst"

  local delete_args=()
  if [[ "$delete_flag" == "1" ]]; then
    delete_args=(--delete)
  fi

  rsync -a "${RSYNC_EXCLUDES[@]}" "${delete_args[@]}" "$src/" "$dst/"
}

sync_pair() {
  local label="$1" cursor_rel="$2" repo_rel="$3" direction="$4"

  local cursor_path="$CURSOR_HOME/$cursor_rel"
  local repo_path="$REPO_DIR/$repo_rel"

  case "$direction" in
    to_repo)
      log "  $label: $cursor_path → $repo_path"
      rsync_mirror "$cursor_path" "$repo_path" "$RSYNC_DELETE"
      ;;
    to_cursor)
      if [[ ! -d "$repo_path" ]] || [[ -z "$(ls -A "$repo_path" 2>/dev/null)" ]]; then
        log "  $label: skip (empty or missing in repo)"
        return 0
      fi
      log "  $label: $repo_path → $cursor_path"
      rsync_mirror "$repo_path" "$cursor_path" "$RSYNC_DELETE"
      ;;
    *)
      die "Unknown direction: $direction"
      ;;
  esac
}

sync_mcp() {
  local direction="$1"
  local cursor_file="$CURSOR_HOME/$MCP_CURSOR_FILE"
  local repo_file="$REPO_DIR/$MCP_REPO_FILE"
  local py="$SCRIPT_DIR/scripts/mcp_sync.py"

  [[ "$SYNC_MCP" == "1" ]] || return 0
  [[ -f "$py" ]] || die "Missing MCP helper: $py"

  case "$direction" in
    to_repo)
      if [[ ! -f "$cursor_file" ]]; then
        log "  mcp: skip (no $cursor_file)"
        return 0
      fi
      python3 "$py" sanitize "$cursor_file" "$repo_file"
      log "  mcp: $cursor_file → $repo_file (secrets redacted, paths → \${HOME})"
      ;;
    to_cursor)
      if [[ ! -f "$repo_file" ]]; then
        log "  mcp: skip (no $repo_file in repo)"
        return 0
      fi
      mkdir -p "$(dirname "$cursor_file")"
      if [[ -f "$cursor_file" ]]; then
        python3 "$py" merge "$repo_file" "$cursor_file" "$cursor_file"
        log "  mcp: $repo_file → $cursor_file (merged, local secrets kept)"
      else
        cp "$repo_file" "$cursor_file"
        python3 "$py" merge "$repo_file" "$cursor_file" "$cursor_file"
        log "  mcp: $repo_file → $cursor_file (installed from repo)"
      fi
      ;;
    *)
      die "Unknown MCP direction: $direction"
      ;;
  esac
}

# ── Git helpers ───────────────────────────────────────────────────────────────
git_has_changes() {
  [[ -n "$(git -C "$REPO_DIR" status --porcelain)" ]]
}

git_pull_if_needed() {
  log "Fetching $GIT_REMOTE/$GIT_BRANCH …"
  git -C "$REPO_DIR" fetch "$GIT_REMOTE" "$GIT_BRANCH"

  local local_rev remote_rev
  local_rev="$(git -C "$REPO_DIR" rev-parse HEAD)"
  remote_rev="$(git -C "$REPO_DIR" rev-parse "$GIT_REMOTE/$GIT_BRANCH")"

  if [[ "$local_rev" == "$remote_rev" ]]; then
    log "Already up to date ($local_rev)"
    return 1
  fi

  log "Pulling $GIT_REMOTE/$GIT_BRANCH ($local_rev → $remote_rev) …"
  git -C "$REPO_DIR" pull --ff-only "$GIT_REMOTE" "$GIT_BRANCH"
  return 0
}

# ── Modes ─────────────────────────────────────────────────────────────────────
producer_run() {
  log "=== PRODUCER: ~/.cursor → repo → push ==="

  cd "$REPO_DIR"

  [[ "$SYNC_SKILLS" == "1" ]] && sync_pair "skills" "skills" "skills" "to_repo"
  [[ "$SYNC_RULES" == "1" ]] && sync_pair "rules" "rules" "rules" "to_repo"
  [[ "$SYNC_SKILLS_CURSOR" == "1" ]] && sync_pair "skills-cursor" "skills-cursor" "skills-cursor" "to_repo"
  sync_mcp "to_repo"

  if ! git_has_changes; then
    log "No changes — skip commit/push"
    return 0
  fi

  log "Changes detected — committing …"
  git add -A
  git commit -m "sync: update skills/rules/mcp $(date '+%Y-%m-%d %H:%M:%S')"

  log "Pushing to $GIT_REMOTE/$GIT_BRANCH …"
  git push "$GIT_REMOTE" "$GIT_BRANCH"
  log "Push complete"
}

consumer_run() {
  log "=== CONSUMER: pull → ~/.cursor ==="

  cd "$REPO_DIR"

  if ! git_pull_if_needed; then
    log "No remote updates — skip rsync"
    return 0
  fi

  [[ "$SYNC_SKILLS" == "1" ]] && sync_pair "skills" "skills" "skills" "to_cursor"
  [[ "$SYNC_RULES" == "1" ]] && sync_pair "rules" "rules" "rules" "to_cursor"
  [[ "$SYNC_SKILLS_CURSOR" == "1" ]] && sync_pair "skills-cursor" "skills-cursor" "skills-cursor" "to_cursor"
  sync_mcp "to_cursor"

  log "Consumer sync complete"
}

# ── launchd (macOS daily scheduler) ───────────────────────────────────────────
launchd_label() {
  echo "com.ai-skills-rules.${SYNC_MODE}"
}

install_launchd() {
  local plist_dir="$HOME/Library/LaunchAgents"
  local label
  label="$(launchd_label)"
  local plist_path="$plist_dir/${label}.plist"
  local hour="${LAUNCHD_HOUR:-9}"
  local minute="${LAUNCHD_MINUTE:-0}"

  mkdir -p "$plist_dir" "$(dirname "$LOG_FILE")"

  cat >"$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT_DIR}/sync.sh</string>
    <string>run</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>${hour}</integer>
    <key>Minute</key>
    <integer>${minute}</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>${LOG_FILE}</string>
  <key>StandardErrorPath</key>
  <string>${LOG_FILE}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
PLIST

  launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist_path"
  log "Installed launchd agent: $plist_path (daily ${hour}:$(printf '%02d' "$minute"))"
}

uninstall_launchd() {
  local label
  label="$(launchd_label)"
  local plist_path="$HOME/Library/LaunchAgents/${label}.plist"

  launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || true
  rm -f "$plist_path"
  log "Removed launchd agent: $label"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  run                 Execute sync based on SYNC_MODE in config.env
  producer            Force producer mode (copy ~/.cursor → repo → push)
  consumer            Force consumer mode (pull repo → ~/.cursor)
  install-launchd     Install daily launchd agent (macOS)
  uninstall-launchd   Remove launchd agent
  status              Show config and last log lines

Config: $SCRIPT_DIR/config.env  (copy from config.env.example)
EOF
}

show_status() {
  load_config
  echo "Mode:        $SYNC_MODE"
  echo "Repo:        $REPO_DIR"
  echo "Cursor home: $CURSOR_HOME"
  echo "Branch:      $GIT_BRANCH"
  echo "Sync:        skills=$SYNC_SKILLS rules=$SYNC_RULES skills-cursor=$SYNC_SKILLS_CURSOR mcp=$SYNC_MCP"
  echo "Log:         $LOG_FILE"
  echo ""
  if [[ -f "$LOG_FILE" ]]; then
    echo "Last 10 log lines:"
    tail -10 "$LOG_FILE"
  else
    echo "No log file yet."
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-run}"
  load_config

  case "$cmd" in
    run)
      case "$SYNC_MODE" in
        producer) producer_run ;;
        consumer) consumer_run ;;
        *) die "Unknown SYNC_MODE: $SYNC_MODE (use producer or consumer)" ;;
      esac
      ;;
    producer) producer_run ;;
    consumer) consumer_run ;;
    install-launchd) install_launchd ;;
    uninstall-launchd) uninstall_launchd ;;
    status) show_status ;;
    -h|--help|help) usage ;;
    *) die "Unknown command: $cmd. Run with --help." ;;
  esac
}

main "$@"
