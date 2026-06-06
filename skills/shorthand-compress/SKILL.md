---
name: shorthand-compress
description: >
  Rewrite skill files from verbose/normal format to shorthand notation.
  Reduces token count by 35-40% while preserving 100% of data.
  Trigger: /shorthand-compress <filepath> or "compress this skill to shorthand".
---

# Shorthand Compress

## Purpose

Rewrite skill files from verbose/normal markdown into shorthand notation. Uses symbols, abbreviations, and compact tables from `shorthand-dict`. Compressed version overwrites original. Backup saved as `<file>.original.md`.

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
4. Write compressed version to original path
5. Save backup as `<filename>.original.md`
6. Report token savings

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