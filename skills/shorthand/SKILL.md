---
name: shorthand
description: >
  Skill compression framework. Use shorthand notation to write skill definitions
  with 35-40% fewer tokens while preserving 100% of data. Load shorthand-dict first,
  then write skills using symbols, abbreviations, and compact formatting patterns.
  Trigger: "use shorthand", "write in shorthand", "/shorthand", or when composing
  skills that need token efficiency.
---

Write skill definitions in shorthand notation. All data preserved. Only representation compressed.

## Persistence

ACTIVE EVERY RESPONSE when writing or editing skill files. Off only: "stop shorthand" / "normal format".

Default: **full**. Switch: `/shorthand lite|full|ultra`.

## Rules

Use shorthand symbols and abbreviations defined in `shorthand-dict` skill. Key principles:

1. **Symbols over words** — `⚡` instead of "(PRIMARY)", `↩A` instead of "FALLBACK A"
2. **Abbreviations over full forms** — `svc` instead of "service", `sev` instead of "severity"
3. **Compact tables over prose** — pipe tables instead of paragraph descriptions
4. **Code blocks for commands** — backtick blocks instead of numbered lists with prose wrappers
5. **Section abbreviations** — `§2 tri` instead of "## §2 — When to Use This Skill"

### Intensity Levels

| Level | What changes |
|-------|-------------|
| **lite** | Drop filler words ("the", "a", "an"), use common abbreviations |
| **full** | All shorthand symbols, compact tables, abbreviated section names |
| **ultra** | Maximum compression. Acronyms only. Arrow logic (`X → Y`). Single-character flags |

### When NOT to Compress

- Security warnings
- Irreversible action descriptions where order matters
- Code blocks and command templates (always preserved exactly)
- Finding templates used in compliance reports (legal language must be exact)

## How to Write a Shorthand Skill

A shorthand skill uses the same YAML frontmatter but compresses the body using these patterns:

### Section Headers
```
§2 tri     → When to Use This Skill (triggers)
§3 pre     → Prerequisites
§4 calls   → Skill Calls (inter-skill invocation)
§5 app     → Approaches & Fallbacks
§6 ins     → Instructions (phased steps)
§7 find    → Findings & Expected Output
§8 rpt     → Reporting & Compliance
§9 xtra    → Extra Details
```

### Approach Notation
```
⚡ <Name>               → PRIMARY approach
↩A <Name>              → FALLBACK A
↩B <Name>              → FALLBACK B
↩Z <Name>              → LAST RESORT (always safe)
```

Each approach uses compact block format:
```
⚡ <Name>
  When: <conditions>
  Cmd:  <command template>
  Pro:  <advantages>
  Con:  <disadvantages>
  OK:   <success criteria>
  FAIL: <failure indicator>
```

### Finding Notation
```
F: <Title>
  Cls: comply | non-com | NA
  Sev: C | H | M | L | I
  Ref: <Standard ID> — <Control Name>
  Desc: <what was found>
  Evi: <evidence reference>
  Rem: <how to fix>
  Com: <additional context>
  ⟐: <cross-reference to other skill finding>
```

### Action Notation
```
RUN <cmd>     → Execute shell command
⊕ skill:x()  → Call another skill
SET <state>   → Set state variable
LOG <msg>     → Write to log
RET <result>  → Return result
CHK <cmd>     → Check prerequisite
IF x → y     → Conditional
```

### State Notation
```
s:<name>      → State variable (shorthand for state:tool_x_available)
```

### Severity & Classification Abbreviations
```
C = Critical    H = High      M = Medium    L = Low
I = Informational  NA = Not Applicable
comply = Compliant   non-com = Non-Compliant
```

### Compliance Mapping Notation
```
OWASP-T10: A05 — Security Misconfiguration → Direct
ASVS: V9.1 — Communications Security → Direct
NIST53: CM-7 — Least Functionality → Direct
MITRE: T1046 — Network Service Discovery → Direct
```

## Quality Checklist

Before publishing a shorthand skill, verify:

- [ ] YAML frontmatter complete and valid
- [ ] All sections present (§2 through §9, §1 is frontmatter)
- [ ] At least 2 approaches with fallbacks (⚡ + at least ↩A)
- [ ] Prerequisites include check commands
- [ ] Skill calls use `⊕ skill:name()` syntax
- [ ] Findings section has identification patterns with severity
- [ ] Reporting maps to at least OWASP + one other standard
- [ ] Error handling defined for major failure modes
- [ ] False positives documented
- [ ] No hardcoded IPs, credentials, or target-specific values

## Design Principles

1. **Zero Data Loss** — Every approach, finding, command, and mapping must be preserved
2. **Dictionary Reference** — Load `shorthand-dict` skill first so the agent can decode all symbols
3. **Graceful Degradation** — Every approach has a fallback. Last fallback (`↩Z`) is always a safe action
4. **Compliance-First** — Every skill that can produce a finding MUST define compliance mappings
5. **No Upward Calls** — Higher-tier skills call lower-tier. Never reverse.
6. **Parameterized Execution** — No hardcoded values. Everything is a variable.
7. **Evidence Preservation** — Every finding includes evidence capture rules