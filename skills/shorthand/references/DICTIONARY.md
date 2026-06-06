---
name: shorthand-dict
description: >
  Dictionary and reference for shorthand notation used in skill definitions.
  Load this skill first when reading or writing shorthand-formatted skills.
  Defines all symbols, abbreviations, section headers, and formatting patterns.
  This is the single source of truth for decoding compressed skill files.
---

# Shorthand Dictionary v1.0

Decode key for all shorthand-formatted skill files. Load before reading any `§`-formatted skill.

---

## ◈ Symbol Operators

| Symbol | Meaning | Example |
|--------|---------|---------|
| `⚡` | PRIMARY approach | `⚡ SYN Half-Open` |
| `↩A` | FALLBACK A | `↩A TCP Connect` |
| `↩B` | FALLBACK B | `↩B Fragmented SYN` |
| `↩C` | FALLBACK C | `↩C Decoy Scan` |
| `↩Z` | LAST RESORT (safe action) | `↩Z nc fallback` |
| `→` | produces / leads to | `→ s:nmap_avail` |
| `←` | consumes / input from | `ports ← target_spec` |
| `⊕` | calls (skill invocation) | `⊕ tool-setup(name="nmap")` |
| `⊗` | conflicts with | `⊗ masscan` |
| `✗` | NOT / do not | `✗ use if stealth critical` |
| `✓` | required / yes | `root ✓` |
| `?` | optional | `version ?` |
| `≈` | default / approximate | `timing ≈ T4` |
| `△` | severity upgrade | `△ High for risky services` |
| `▽` | severity downgrade | `▽ Info for hardened hosts` |
| `⟐` | cross-reference | `⟐ → sql-injection skill` |
| `∞` | always / infinite | `∞ log on failure` |

---

## ◈ Section Abbreviations

| Abbr | Full Section | Purpose |
|------|-------------|---------|
| `id` | Skill Identity | Name, tier, version, status |
| `tri` | When to Use (Triggers) | Auto-trigger conditions, anti-patterns |
| `pre` | Prerequisites | System reqs, skill deps, inputs, env |
| `calls` | Skill Calls | Calls TO, called BY, call syntax |
| `app` | Approaches & Fallbacks | ⚡ primary + ↩ fallbacks |
| `ins` | Instructions | Phased steps, error handling, state |
| `find` | Findings & Expected Output | Artifacts, patterns, false positives |
| `rpt` | Reporting & Compliance | Mappings, finding templates |
| `xtra` | Extra Details | Limitations, tuning, references |

In skill files, sections are numbered: `§2 tri`, `§3 pre`, `§4 calls`, `§5 app`, `§6 ins`, `§7 find`, `§8 rpt`, `§9 xtra` (§1 is the YAML frontmatter).

---

## ◈ Type Abbreviations

| Abbr | Full | Abbr | Full |
|------|------|------|------|
| `str` | string | `bool` | boolean |
| `int` | integer | `list` | array/list |
| `dict` | object/dict | `re` | regex |
| `y` | yes/true | `n` | no/false |
| `def` | default | `fb` | fallback |
| `req` | required | `opt` | optional |

---

## ◈ Prerequisites Abbreviations

| Abbr | Full | Abbr | Full |
|------|------|------|------|
| `bin` | binary/executable | `pkg` | system package |
| `lib` | library/dependency | `priv` | privilege level |
| `dir` | directory | `env` | environment |
| `net` | network access | `chk` | check command |

---

## ◈ Finding Abbreviations

| Abbr | Full | Abbr | Full |
|------|------|------|------|
| `sev` | Severity | `conf` | Confidence |
| `fp` | False Positive | `fn` | False Negative |
| `C` | Critical | `H` | High |
| `M` | Medium | `L` | Low |
| `I` | Informational | `NA` | Not Applicable |
| `comply` | Compliant | `non-com` | Non-Compliant |

---

## ◈ Compliance Standards

| Abbr | Full |
|------|------|
| `OWASP-T10` | OWASP Top 10 (2021) |
| `ASVS` | OWASP ASVS 4.0 |
| `NIST53` | NIST 800-53 |
| `MITRE` | MITRE ATT&CK |
| `PTES` | PTES |
| `CIS` | CIS Controls v8 |
| `OSSTMM` | OSSTMM |

---

## ◈ Action Notation

| Pattern | Meaning |
|---------|---------|
| `RUN <cmd>` | Execute shell command |
| `⊕ skill:name(params)` | Call another skill |
| `SET <variable>` | Set state variable |
| `LOG <msg>` | Write to log file |
| `RET <result>` | Return result |
| `CHK <cmd>` | Check prerequisite |
| `IF <cond> → <action>` | Conditional branch |
| `IF ALL Fail → <action>` | All fallbacks exhausted |

---

## ◈ State Notation

| Pattern | Meaning |
|---------|---------|
| `s:<name>` | State variable |
| `s:x_avail` | `state:x_available` |
| `s:x_path` | `state:x_path` |
| `s:x_ver` | `state:x_version` |
| `s:x_method` | `state:x_method` |
| `s:t_<ip>_ports` | `state:target_<ip>_ports` |
| `s:t_<ip>_svc` | `state:target_<ip>_services` |
| `s:t_<ip>_os` | `state:target_<ip>_os` |

---

## ◈ Finding Template Format

```
F: <Title>
  Cls: comply | non-com | NA
  Sev: C | H | M | L | I
  Ref: <Standard ID> — <Control Name>
  Desc: <what was found>
  Evi: <evidence / command output reference>
  Rem: <how to fix>
  Com: <additional context>
  ⟐: <cross-reference to other skill>
```

---

## ◈ Error Notation

```
E_<CODE> | <Description> | <Action> | Retry: y/n
```

Example:
```
E_TIMEOUT | Scan exceeded timeout | Reduce timing, retry | y(1x)
E_NO_ROOT | SYN scan needs root | Switch to -sT | n
```

---

## ◈ Tier System

| Tier | Name | Calls | Called By |
|------|------|-------|----------|
| 1 | Core | 1.5, 2, 3 | Operator |
| 1.5 | Sub-Core | 3 | 1, 2 |
| 2 | Attack-Specific | 3, 1.5 | 1 |
| 3 | Tools & Methods | — | 1, 1.5, 2 |

**Rule:** Higher tiers call lower. Lower tiers never call higher.

---

*End of Shorthand Dictionary v1.0*