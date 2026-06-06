---
name: shorthand-compress
description: >
  Rewrite skill files from verbose/normal format to shorthand notation.
  Reduces token count by 35-40% while preserving 100% of required data in evaluation.
  Trigger: /shorthand-compress <filepath> or "compress this skill to shorthand".
license: MIT
---

# Shorthand Compress

## Purpose

Rewrite skill files from verbose/normal markdown into shorthand notation. Uses symbols, abbreviations, and compact tables from `shorthand-dict`. Default output is `<file>.shorthand.md`; overwrite the original only when the operator explicitly asks for in-place compression. When overwriting, save a timestamped backup as `<file>.original.<YYYYMMDDHHMMSS>.md`.

## Process

1. Read the input skill file
2. Parse all sections into structured data
3. Apply shorthand transformations:
   - Section headers: `## When to Use` → `## §2 tri`
   - Approaches: `(PRIMARY)` → `⚡`, `(FALLBACK A)` → `↩A`
   - Skill calls: `CALL skill:name()` → `⊕ skill:name()`
   - State variables: `state:tool_x_available` → `s:x_avail`
   - Tables: compress prose into pipe tables
   - Finding templates: expand `Finding:` → `F:` with `Cls:`, `Sev:`, `Ref:`
4. Write compressed version to `<file>.shorthand.md`
5. If user explicitly requested in-place overwrite, save backup as `<filename>.original.<YYYYMMDDHHMMSS>.md`, then replace original
6. Run the evaluation harness or a task-specific preservation checklist
7. Report token savings and any missing facts

## Transformations

| Verbose | Shorthand |
|---------|-----------|
| `(PRIMARY)` | `⚡` |
| `(FALLBACK A)` | `↩A` |
| `(FALLBACK B)` | `↩B` |
| `(LAST RESORT)` | `↩Z` |
| `CALL skill:name()` | `⊕ skill:name()` |
| `state:tool_nmap_available` | `s:nmap_avail` |
| `Required: yes` | `req: y` |
| `Severity: Critical/High/Medium/Low/Informational` | `Sev: C/H/M/L/I` |
| `Classification: Compliant/Non-Compliant/Not Applicable` | `Cls: comply/non-com/NA` |
| `When to Use This Skill` | `§2 tri` |
| `Prerequisites` | `§3 pre` |
| `Skill Calls` | `§4 calls` |
| `Approaches & Fallbacks` | `§5 app` |
| `Instructions` | `§6 ins` |
| `Findings & Expected Output` | `§7 find` |
| `Reporting & Compliance` | `§8 rpt` |
| `Extra Details` | `§9 xtra` |

## Boundaries

- Never compress code blocks — preserve exactly
- Never compress YAML frontmatter — preserve exactly
- Never compress legal/compliance language in finding templates that requires exact wording
- Always load `shorthand-dict` skill first so the agent understands the output
- Never claim 0% loss unless an explicit preservation manifest/evaluation passes
