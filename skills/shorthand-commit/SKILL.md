---
name: shorthand-commit
description: >
  Write commit messages in shorthand notation. Terse, conventional,
  why-over-what. Subject ≤50 chars. Use when writing commits for
  projects that use shorthand-formatted skill files.
license: MIT
---

Write commit messages terse. Conventional Commits format. Why over what.

## Rules

**Subject:** `<type>(<scope>): <imperative>` — scope optional, ≤50 chars, no period.
**Types:** feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert
**Body:** Only if subject isn't self-explanatory. Wrap 72. Bullets with `-`. Refs at end.

**Never:** "This commit does X", "I", "we", "now", "currently" — diff says what.

**Shorthand-specific commits:**
- When adding shorthand notation symbols: `feat(dict): add ⟐ cross-ref symbol`
- When adding a new skill in shorthand: `feat(skills): add port-scanner t3 shorthand skill`
- When compressing a skill: `perf(port-scanner): compress from verbose to shorthand (38% reduction)`
