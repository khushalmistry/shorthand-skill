<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/pencil_270f-fe0f.png" width="120" />
</p>

<h1 align="center">shorthand-skill</h1>

<p align="center">
  <strong>compress skill files 35–40%. same data. fewer tokens. zero loss.</strong>
</p>

<p align="center">
  <a href="https://github.com/khushalmistry/shorthand-skill/stargazers"><img src="https://img.shields.io/github/stars/khushalmistry/shorthand-skill?style=flat&color=yellow" alt="Stars"></a>
  <a href="https://github.com/khushalmistry/shorthand-skill/commits/main"><img src="https://img.shields.io/github/last-commit/khushalmistry/shorthand-skill?style=flat" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/khushalmistry/shorthand-skill?style=flat" alt="License"></a>
</p>

<p align="center">
  <a href="#before--after">Before/After</a> •
  <a href="#install">Install</a> •
  <a href="#what-you-get">What You Get</a> •
  <a href="#benchmarks">Benchmarks</a> •
  <a href="#how-it-works">How It Works</a>
</p>

---

A skill compression framework for AI agents that uses **shorthand notation** (inspired by court stenography) to compress skill definitions by **35–40%** while preserving **100% of the original data** — every approach, finding template, compliance mapping, and error code stays intact.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Hermes Agent](https://hermes-agent.nousresearch.com), [OpenCode](https://github.com/opencode-ai/opencode), [Cline](https://cline.bot), [Cursor](https://cursor.com), [Windsurf](https://codeium.com/windsurf), [Copilot](https://github.com/features/copilot), and any agent that reads markdown skill files.

## Before / After

<table>
<tr>
<td width="50%">

### 📝 Normal (4,995 words)

```yaml
## Approaches & Fallbacks

### Approach 1: SYN Half-Open Scan (PRIMARY)
**When to use:** Default scan mode. Requires root/cap_net_raw.
**Steps:**
1. Verify nmap available via tool-installation
2. Verify root/cap_net_raw available
3. Build nmap command with SYN scan flags
...
**Pros:** Fast, stealthy, most accurate
**Cons:** Requires root privileges or capabilities
**Success Criteria:** Open/closed/filtered results
**Failure Indicator:** "Requires root" error

### Approach 2: TCP Connect Scan (FALLBACK A)
**When to use:** No root access. Full handshake.
...
```

</td>
<td width="50%">

### ✏️ Shorthand (3,257 words)

```yaml
## §5 app

### ⚡ SYN Half-Open (PRIMARY)
```
When: default. root/cap available. fast, stealthy, reliable.
Cmd:  nmap -sS -sV -O --top-ports <N> -T<time> ...
Pro:  fast, stealthy, most accurate
Con:  needs root/cap_net_raw
OK:   open/closed/filtered ports + OS guess conf >80%
FAIL: "requires root" error, hang, 100% filtered
```

### ↩A TCP Connect (FALLBACK A)
```
When: no root, no cap. Full TCP handshake.
Cmd:  nmap -sT -sV --top-ports <N> -T<time> ...
Pro:  works without privs, gets service versions
Con:  no OS detect, slower, noisy
```

</td>
</tr>
</table>

**Same approaches. Same fallbacks. Same commands. 35% fewer tokens. 🖊️**

```
┌─────────────────────────────────────┐
│  TOKENS SAVED           ████▓  38%   │
│  DATA PRESERVED         ██████ 100%  │
│  APPROACHES KEPT         ██████  5/5  │
│  FALLBACKS INTACT        ██████  5/5  │
│  COMPLIANCE MAPPINGS      ██████ 12/12│
│  VIBES                   🖊️ precise  │
└─────────────────────────────────────┘
```

## What You Get

| Component | What |
|-----------|------|
| `shorthand` skill | Core compression notation — symbol operators, abbreviations, compact formatting |
| `shorthand-dict` | Dictionary of all shorthand symbols, abbreviations, and patterns |
| `shorthand-commit` | Write compressed commit messages using shorthand notation |
| `shorthand-compress` | Rewrite any skill file into shorthand format |
| Sample skills | `port-scanner` and `tool-setup` — real working skills in shorthand format |

## Install

```bash
# Clone the repo
git clone https://github.com/khushalmistry/shorthand-skill.git
cd shorthand-skill

# Copy the skill to your agent's skill directory
cp -r skills/shorthand/ ~/.hermes/skills/
cp -r skills/shorthand-dict/ ~/.hermes/skills/

# For Claude Code, Hermes, OpenCode, or any skills-compatible agent:
# The shorthand dictionary is loaded automatically as a reference
```

Or use the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/khushalmistry/shorthand-skill/main/install.sh | bash
```

## Benchmarks

Real measurements from our sample skills:

| Metric | Normal | Shorthand | Saved |
|--------|-------:|----------:|------:|
| Words (port-scanner) | 4,995 | 3,257 | **35%** |
| Bytes (port-scanner) | 35,354 | 21,874 | **38%** |
| Lines (port-scanner) | 774 | 531 | **31%** |
| Approaches preserved | 5 | 5 | **100%** |
| Compliance mappings | 12 | 12 | **100%** |
| Error codes | 9 | 9 | **100%** |

**With dictionary overhead (one-time 854 words):**
- 1st skill: 3,257 + 854 = 4,111 words (still **18% less**)
- 2nd skill onwards: 3,257 words each (**35% savings per skill**)
- Over 10 skills: **~17,000 words saved in total**

> **Important:** Shorthand only compresses skill definition tokens. All technical accuracy, approaches, findings, and compliance data are **100% preserved**. Less tokens means faster loading, lower costs, and more skills fit in context.

## How It Works

1. **Dictionary First** — Load the `shorthand-dict` skill which defines all symbols (`⚡`, `↩`, `⊕`, `✗`, etc.), abbreviations (`svc`, `sev`, `chk`, `def`), and compact formatting patterns.

2. **Write in Shorthand** — Use the notation system to write skill definitions:
   - `⚡` = primary approach, `↩A/B/C` = fallbacks, `↩Z` = last resort
   - `⊕ skill:name()` = calls another skill
   - `s:<name>` = state variable
   - `CHK`, `SET`, `LOG`, `RET` = action prefixes
   - Compact tables replace verbose paragraphs

3. **Zero Data Loss** — Every approach, finding template, compliance mapping, error code, and command is preserved. The agent reads shorthand as fluently as prose.

### Shorthand at a Glance

| Symbol | Meaning | Example |
|--------|---------|---------|
| `⚡` | PRIMARY approach | `⚡ SYN Half-Open` |
| `↩A` | FALLBACK A | `↩A TCP Connect` |
| `↩Z` | LAST RESORT (safe) | `↩Z nc fallback` |
| `⊕` | calls skill | `⊕ tool-setup(name="nmap")` |
| `✗` | do NOT | `✗ use if stealth critical` |
| `✓` | required | `root ✓` |
| `?` | optional | `version ?` |
| `≈` | default/approximate | `timing ≈ T4` |
| `→` | produces/leads to | `→ s:nmap_avail` |
| `←` | consumes/input from | `ports ← target_spec` |

Full dictionary: [`skills/shorthand-dict/SKILL.md`](skills/shorthand-dict/SKILL.md)

## Philosophy

Court stenographers write at 200+ WPM using shorthand — compressing every word into symbolic notation without losing meaning. We applied the same principle to AI skill definitions.

Every word in a skill file costs tokens. Every token costs money and context window space. Shorthand compresses the **representation** while preserving the **information** — the same way stenography has worked for centuries.

**Less tokens → faster loading → lower costs → more skills in context → better agents.**

## Directory Structure

```
shorthand-skill/
├── README.md                     # You are here
├── LICENSE                       # MIT
├── install.sh                    # One-liner installer
├── skills/
│   ├── shorthand/SKILL.md        # Core skill: compression notation
│   ├── shorthand-dict/SKILL.md   # Dictionary: all symbols & patterns
│   ├── shorthand-commit/SKILL.md # Compressed commit messages
│   ├── shorthand-compress/SKILL.md # Skill-to-shorthand converter
│   └── samples/
│       ├── port-scanner.md        # Sample: port scanning skill (shorthand)
│       └── tool-setup.md          # Sample: tool setup skill (shorthand)
├── agents/
│   ├── shorthand-builder.md      # Subagent: build skills in shorthand
│   └── shorthand-reviewer.md     # Subagent: review shorthand quality
├── benchmarks/                   # Compression measurements
├── evals/                        # Quality evaluation harness
└── docs/                         # Additional guides
```

## Use Cases

- **Skill authors** — Write skills in shorthand, load dict once, save tokens forever
- **Agent frameworks** — Distribute compressed skills that load faster and cost less
- **Multi-skill systems** — Fit more skills in context window with zero information loss
- **CI/CD pipelines** — Compress skill files before deployment to reduce bundle size
- **Penetration testing frameworks** — Write recon, enumeration, and attack skills that load in milliseconds

## 🚀 Quick Start — One Prompt for Any Agent

Paste this prompt into **any** autonomous agent. It will clone the repo, copy skills, and start using shorthand immediately:

```
Clone https://github.com/khushalmistry/shorthand-skill and copy all folders from skills/ into your skill directory. Load the shorthand-dict skill first — it defines all symbols (⚡ primary, ↩ fallback, ⊕ call skill, ✗ do not, → produces, ← consumes) and abbreviations (tri=triggers, pre=prerequisites, app=approaches, find=findings, rpt=reporting, sev=severity, com=compliant). From now on, write and read all skill files using shorthand notation. Sections use § numbers: §2 tri, §3 pre, §4 calls, §5 app, §6 ins, §7 find, §8 rpt, §9 xtra. Every approach starts with ⚡ (primary) followed by ↩A/B/C (fallbacks) and ↩Z (last resort safe action). Use compact tables instead of prose. Zero data loss — every approach, finding, command, and compliance mapping must be preserved.
```

**That's it.** One prompt, any agent, shorthand active.

### Platform-Specific Setup

| Agent | How to Install | Skill Directory |
|-------|---------------|----------------|
| **Hermes Agent** | `hermes skills add shorthand-skill` or copy to | `~/.hermes/skills/` |
| **Claude Code** | Copy `skills/*/` folders to | `.claude/skills/` |
| **OpenCode** | Copy `skills/*/` folders to | `.opencode/skills/` |
| **Cline** | Copy `SKILL.md` contents into | `.clinerules/` |
| **Cursor** | Copy `SKILL.md` contents into | `.cursor/rules/` |
| **Windsurf** | Copy `SKILL.md` contents into | `.windsurfrules/` |
| **GitHub Copilot** | Copy into | `.github/copilot-instructions.md` |
| **OpenAI Codex** | Copy `skills/*/` folders to | `.codex/skills/` |
| **Any SKILL.md reader** | Copy all skill folders to your agent's skill directory | varies |

### Hermes Agent (Native)

```bash
# Option 1: Built-in command
hermes skills add shorthand-skill

# Option 2: Manual
git clone https://github.com/khushalmistry/shorthand-skill.git
cp -r shorthand-skill/skills/shorthand ~/.hermes/skills/
cp -r shorthand-skill/skills/shorthand-dict ~/.hermes/skills/
cp -r shorthand-skill/skills/shorthand-commit ~/.hermes/skills/
cp -r shorthand-skill/skills/shorthand-compress ~/.hermes/skills/

# Option 3: One-liner
curl -fsSL https://raw.githubusercontent.com/khushalmistry/shorthand-skill/main/install.sh | bash
```

### Claude Code

```bash
# Clone and copy skills
git clone https://github.com/khushalmistry/shorthand-skill.git
cd shorthand-skill
cp -r skills/shorthand .claude/skills/
cp -r skills/shorthand-dict .claude/skills/
cp -r skills/shorthand-commit .claude/skills/
cp -r skills/shorthand-compress .claude/skills/

# Or add to your project's .claude/ directory
```

### OpenCode

```bash
# Clone and copy skills
git clone https://github.com/khushalmistry/shorthand-skill.git
cd shorthand-skill
cp -r skills/shorthand .opencode/skills/
cp -r skills/shorthand-dict .opencode/skills/
cp -r skills/shorthand-commit .opencode/skills/
cp -r skills/shorthand-compress .opencode/skills/
```

### Other Agents (Cline, Cursor, Windsurf, Copilot)

For agents that don't use a `skills/` directory, merge the skill contents into your agent's rules file:

```bash
# Cline
cat skills/shorthand-dict/SKILL.md >> .clinerules

# Cursor
cat skills/shorthand-dict/SKILL.md >> .cursor/rules

# Windsurf
cat skills/shorthand-dict/SKILL.md >> .windsurfrules

# GitHub Copilot
cat skills/shorthand-dict/SKILL.md >> .github/copilot-instructions.md
```

### Universal Prompt (Works Everywhere)

If you can't install skill files, just paste this into your agent's system prompt or first message:

> Load the shorthand-dict skill from https://github.com/khushalmistry/shorthand-skill/blob/main/skills/shorthand-dict/SKILL.md — it defines all shorthand symbols and abbreviations. From now on, use shorthand notation (⚡, ↩, ⊕, ✗, §) when writing or reading skill files. Compress representation, preserve information.

## Compatibility

Works with any agent that reads markdown skill files:

| Agent | Status |
|-------|--------|
| Hermes Agent | ✅ Native `hermes skills add` |
| Claude Code | ✅ Via `.claude/skills/` |
| OpenCode | ✅ Via `.opencode/skills/` |
| Cline | ✅ Via `.clinerules/` |
| Cursor | ✅ Via `.cursor/rules/` |
| Windsurf | ✅ Via `.windsurfrules/` |
| Copilot | ✅ Via `.github/copilot-instructions.md` |
| Codex (OpenAI) | ✅ Via `.codex/skills/` |
| Any SKILL.md reader | ✅ Universal |

## Why Not Just...

- **Caveman** — Caveman compresses *agent output* (what the agent says). Shorthand compresses *skill definitions* (what the agent reads). They complement each other perfectly — use both for maximum savings.
- **gzip/brotli** — Compression algorithms make files smaller on disk but the agent still reads the uncompressed version. Shorthand compresses what the agent actually *sees*.
- **Just write shorter** — Shorthand is a **systematic** notation with a dictionary, symbols, and patterns. It's not "write less" — it's "encode efficiently."

## Credits

Inspired by court stenography — the technique used in courtrooms for centuries to capture every word at 200+ WPM using symbolic notation. Same principle, applied to AI skill definitions.

## License

MIT — free to use, modify, and distribute.