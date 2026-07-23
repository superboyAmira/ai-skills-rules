# Reviewer prompts (fallback if custom agents missing)

Substitute: `DEFAULT_BRANCH`, `PLAN_FILE_PATH` (or "none").

All reviewers are **read-only**. Severity: `CRITICAL` | `MAJOR` | `MINOR` | `NIT`.  
Model for these fallbacks: `cursor-grok-4.5-high-fast`.

---

## quality — Best practices

Correctness, edge cases, error handling, races, leaks, insecure patterns, API breaks. Ignore pure style nits unless they hide bugs.

---

## implementation — Соответствие плану

Compare diff to `PLAN_FILE_PATH`. Missing pieces? Scope creep? Wrong layer?

---

## testing — Покрытие, краевые случаи

Missing success/error cases, brittle tests, untested new branches.

---

## documentation — Комментарии, докстринги

Misleading/stale comments, missing docs when behavior changes. No docs for trivial renames.

---

## simplification — Избыточность

Unnecessary abstractions, dead code from the change, YAGNI violations.

---

## smells

Project conventions (AGENTS.md, CLAUDE.md, .cursor/rules), duplication vs abstraction, naming/layout/logging patterns.

---

## external (Codex)

Independent adversarial review. Tag `CRITICAL`/`MAJOR`/`MINOR`. Clean → `NO ISSUES FOUND`.
