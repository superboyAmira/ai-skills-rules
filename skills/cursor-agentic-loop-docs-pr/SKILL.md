---
name: cursor-agentic-loop-docs-pr
description: >-
  Finalize documentation and open a pull request after cursor-agentic-loop or cursor-agentic-loop-plan-exec.
  Updates plan completed/, drafts PR summary, pushes with user consent, creates PR
  via gh. Use when the user says cursor-agentic-loop-docs-pr, docs-pr, /cursor-agentic-loop-docs-pr, open PR, create PR after the
  loop, or cursor-agentic-loop reaches Docs & PR.
disable-model-invocation: true
---

# Docs & PR

Finalize docs and create a PR after implementation + reviews.
Maps to diagram step **9 · Docs & PR** before human review.

## Preconditions

- Feature branch with the intended commits (or ask user to commit first)
- Reviews from `cursor-agentic-loop-review` skill done (or user explicitly skips)

## Steps

### 1. Docs pass

1. Diff vs default branch: what user-facing / operator-facing behavior changed?
2. Update only what is needed: README, AGENTS.md, CLAUDE.md, `docs/` — no unsolicited markdown sprawl.
3. If a plan file exists and all tasks/reviews are done: `mkdir -p docs/plans/completed && git mv <plan> docs/plans/completed/` (or move if untracked).

### 2. Commit (only if user asks or explicitly opted in)

Follow the repo's commit rules / user git rules. Prefer one focused commit for docs+plan move, or include in the PR branch history as the user prefers. Never `--no-verify`. Never push until step 3 confirms.

### 3. Push + PR

Ask before push if not already confirmed in this session.

```bash
git push -u origin HEAD
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...

## Agentic loop
- Plan: `docs/plans/completed/...`
- Reviews: agent / smells / external / critical — done
EOF
)"
```

Use `gh` for GitHub. If GitLab remote, use `glab` only if available; otherwise give the user the compare URL.

### 4. Hand off (step 10)

Return:

- PR URL
- Short summary of decisions/deviations from progress file (if any)
- Explicit: **Human Review** — your turn; agent stops unless asked to address review comments

## Do not

- Force-push
- Merge the PR
- Skip tests “to get the PR up” if the branch is red — warn and ask
