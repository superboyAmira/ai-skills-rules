# Session documentation (brainstorm + planning)

The full dialogue during brainstorm and planning must land in **structured docs**, not only in chat history.

## Where to write

Create a session folder once (slug from plan title / task id):

```text
docs/agentic/yyyymmdd-<slug>/
  README.md           # index of this session
  brainstorm.md       # structured brainstorm dialogue + decisions
  planning.md         # plan-make Q&A, approaches, constraints
  needs-documenting.md
  plan.md             # optional symlink/copy pointer to docs/plans/...
```

Also keep the executable plan at `docs/plans/yyyymmdd-<slug>.md` (source of truth for `plan-exec`).

## brainstorm.md (required after step 1)

Structure:

```markdown
# Brainstorm — <title>

## Goal
## Context discovered
## Questions & answers
| # | Question | Answer | When |
## Approaches considered
### A (recommended) / B / C — trade-offs
## Selected approach
## Design (validated sections)
## Open questions
## Rejected ideas
```

Capture **every** user answer from the one-at-a-time Q&A. Do not leave decisions only in chat.

## planning.md (required after step 2)

```markdown
# Planning notes — <title>
## Intent
## Scope / out of scope
## Constraints
## Testing approach
## Approach choice (link to brainstorm)
## Plan file
`docs/plans/yyyymmdd-<slug>.md`
## Deviations during planning
```

## needs-documenting.md (required; living list)

Things that still need docs beyond this session — update as you learn:

```markdown
# Needs documenting
- [ ] <topic> — why / for whom / suggested path (e.g. docs/business-processes/…)
- [ ] Update `.cursor/manifest.json` entries for new docs
- [ ] README / runbook / API / metrics / runbooks / ADR if architecture changed
```

Promote items into real docs during step 9 (`cursor-agentic-loop-docs-pr`) or earlier if blocking.

## Rules

- Write/update these files **before** leaving brainstorm / plan-make steps.
- Prefer updating existing session files over creating duplicates.
- Link session folder from the plan Overview.
- Russian or English — match the project's docs language (employee-stat → Russian OK).
