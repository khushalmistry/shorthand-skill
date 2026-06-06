<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/pencil_270f-fe0f.png" width="120" />
</p>

<h1 align="center">shorthand-skill</h1>

<p align="center">
  <strong>compress skill files ~35–40%. same data. fewer tokens. zero evaluated loss.</strong>
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
  <a href="#evaluation">Evaluation</a> •
  <a href="#how-it-works">How It Works</a>
</p>

---

A skill compression framework for AI agents that uses **shorthand notation** (inspired by court stenography) to compress skill definitions by **~35–40%** while preserving **100% of required data in evaluation** — every required approach, finding template, compliance mapping, and error code stays intact.

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Hermes Agent](https://hermes-agent.nousresearch.com), [OpenCode](https://github.com/opencode-ai/opencode), [Cline](https://cline.bot), [Cursor](https://cursor.com), [Windsurf](https://codeium.com/windsurf), [Copilot](https://github.com/features/copilot), and any agent that reads markdown skill files.

## Before / After

<table>
<tr>
<td width="50%">

### 📝 Normal (3,705 words)

```text
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

### ✏️ Shorthand (2,211 words)

```text
## §5 app

### ⚡ SYN Half-Open (PRIMARY)
When: default. root/cap available. fast, stealthy, reliable.
Cmd:  nmap -sS -sV -O --top-ports <N> -T<time> ...
Pro:  fast, stealthy, most accurate
Con:  needs root/cap_net_raw
OK:   open/closed/filtered ports + OS guess conf >80%
FAIL: "requires root" error, hang, 100% filtered

### ↩A TCP Connect (FALLBACK A)
When: no root, no cap. Full TCP handshake.
Cmd:  nmap -sT -sV --top-ports <N> -T<time> ...
Pro:  works without privs, gets service versions
Con:  no OS detect, slower, noisy
```

</td>
</tr>
</table>

**Same approaches. Same fallbacks. Same commands. 40.32% fewer words in the included evaluation. 🖊️**

```
┌─────────────────────────────────────┐
│  WORDS SAVED            ████▓  40.32%│
│  DATA PRESERVED         ██████ 100%  │
│  APPROACHES KEPT         ██████  5/5  │
│  FALLBACKS INTACT        ██████  5/5  │
│  REQUIRED FACTS          ██████ 26/26│
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
| Example skills | `port-scanner` and `tool-setup` — installable shorthand skills with safety gates |

## Install

```bash
# Clone the repo
git clone https://github.com/khushalmistry/shorthand-skill.git
cd shorthand-skill

# Install all skills for your agent
bash install.sh --agent codex
bash install.sh --agent claude
bash install.sh --agent hermes
bash install.sh --agent opencode
```

Core-only install:

```bash
bash install.sh --agent codex --core-only
```

One-liner, after review:

```bash
# Review first
curl -fsSL https://raw.githubusercontent.com/khushalmistry/shorthand-skill/main/install.sh -o /tmp/shorthand-install.sh
less /tmp/shorthand-install.sh

# Then run
bash /tmp/shorthand-install.sh --agent codex
```

Pinned install:

```bash
REF="trusted-tag-or-sha"
curl -fsSL "https://raw.githubusercontent.com/khushalmistry/shorthand-skill/${REF}/install.sh" \
  | bash -s -- --agent codex --ref "$REF"
```

Custom directory:

```bash
bash install.sh --target ~/.codex/skills
```

## Evaluation

Run the evaluation locally:

```bash
python3 evals/evaluate.py
gh skill publish --dry-run .
```

Latest checked result:

| Metric | Normal | Shorthand | Saved |
|--------|-------:|----------:|------:|
| Words (port-scanner) | 3,705 | 2,211 | **40.32%** |
| Bytes (port-scanner) | 24,737 | 14,053 | **43.19%** |
| Lines (port-scanner) | 478 | 386 | **19.25%** |
| Required facts preserved | 26 | 26 | **100%** |
| Lost facts | 0 | 0 | **0.00% loss** |
| Skill validation | 6 skills | 6 pass | **0 errors** |

The saved report is in [`evals/results/latest.md`](evals/results/latest.md).

### How the Evaluation Works

The evaluator compares:

1. A verbose baseline: [`evals/fixtures/port-scanner.verbose.md`](evals/fixtures/port-scanner.verbose.md)
2. The shorthand skill: [`skills/port-scanner/SKILL.md`](skills/port-scanner/SKILL.md)
3. A preservation manifest: [`evals/manifests/port-scanner.json`](evals/manifests/port-scanner.json)

The manifest lists required facts: approaches, commands, safety gates, artifacts, error codes, state variables, finding templates, and compliance mappings. The result is **0% evaluated loss** when every required fact present in the verbose baseline is also present in the shorthand skill.

That does **not** mean the words are identical. It means the same operational data is carried in a shorter representation. Shorthand is a different language for the same meaning: shorter symbols, abbreviated section names, and compact tables, but the required facts stay intact.

## How It Works

1. **Dictionary First** — Read `skills/shorthand/references/DICTIONARY.md` or load the `shorthand-dict` skill. It defines all symbols (`⚡`, `↩`, `⊕`, `✗`, etc.), abbreviations (`svc`, `sev`, `chk`, `def`), and compact formatting patterns.

2. **Write in Shorthand** — Use the notation system to write skill definitions:
   - `⚡` = primary approach, `↩A/B/C` = fallbacks, `↩Z` = last resort
   - `⊕ skill:name()` = calls another skill
   - `s:<name>` = state variable
   - `CHK`, `SET`, `LOG`, `RET` = action prefixes
   - Compact tables replace verbose paragraphs

3. **Zero Evaluated Data Loss** — Every required approach, finding template, compliance mapping, error code, and command is preserved in the manifest-based evaluation. The agent reads shorthand as fluently as prose.

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

Full dictionary: [`skills/shorthand/references/DICTIONARY.md`](skills/shorthand/references/DICTIONARY.md) or [`skills/shorthand-dict/SKILL.md`](skills/shorthand-dict/SKILL.md)

## Philosophy

Court stenographers write at 200+ WPM using shorthand — compressing every word into symbolic notation without losing meaning. We applied the same principle to AI skill definitions.

Every word in a skill file costs tokens. Every token costs money and context window space. Shorthand compresses the **representation** while preserving the **information** — the same way stenography has worked for centuries.

**Less tokens → faster loading → lower costs → more skills in context → better agents.**

## Directory Structure

```
shorthand-skill/
├── README.md                     # You are here
├── LICENSE                       # MIT
├── install.sh                    # Agent-aware installer
├── skills/
│   ├── shorthand/
│   │   ├── SKILL.md              # Core skill: compression notation
│   │   └── references/
│   │       └── DICTIONARY.md     # Embedded notation dictionary
│   ├── shorthand-dict/SKILL.md   # Dictionary: all symbols & patterns
│   ├── shorthand-commit/SKILL.md # Compressed commit messages
│   ├── shorthand-compress/SKILL.md # Skill-to-shorthand converter
│   ├── tool-setup/SKILL.md       # Example: approval-gated dependency setup
│   └── port-scanner/SKILL.md     # Example: authorized network recon
├── evals/
│   ├── evaluate.py               # Compression + preservation evaluator
│   ├── fixtures/                 # Verbose baselines
│   ├── manifests/                # Required-fact manifests
│   └── results/                  # Latest evaluation output
└── docs/                         # Additional guides
```

## Use Cases

- **Skill authors** — Write skills in shorthand, load dict once, save tokens forever
- **Agent frameworks** — Distribute compressed skills that load faster and cost less
- **Multi-skill systems** — Fit more skills in context window with zero evaluated information loss
- **CI/CD pipelines** — Compress skill files before deployment to reduce bundle size
- **Authorized security workflows** — Write recon and enumeration skills with explicit scope/approval gates

## 🚀 Quick Start — One Prompt for Any Agent

Paste this prompt into **any** autonomous agent. It will clone the repo, copy skills, and start using shorthand immediately:

```
Clone https://github.com/khushalmistry/shorthand-skill, run bash install.sh --agent codex (or --agent claude/hermes/opencode), then read shorthand/references/DICTIONARY.md. From now on, write and read skill files using shorthand notation: ⚡ primary, ↩ fallback, ⊕ call skill, ✗ do not, → produces, ← consumes. Sections use § numbers: §2 tri, §3 pre, §4 calls, §5 app, §6 ins, §7 find, §8 rpt, §9 xtra. Every approach starts with ⚡ followed by ↩A/B/C fallbacks and ↩Z safe last resort. Use compact tables instead of prose. Preserve every required approach, finding, command, error code, and compliance mapping; verify preservation with python3 evals/evaluate.py.
```

**That's it.** One prompt, any agent, shorthand active.

### Platform-Specific Setup

| Agent | How to Install | Skill Directory |
|-------|---------------|----------------|
| **Hermes Agent** | `bash install.sh --agent hermes` | `~/.hermes/skills/` |
| **Claude Code** | `bash install.sh --agent claude` | `~/.claude/skills/` |
| **OpenCode** | `bash install.sh --agent opencode` | `~/.opencode/skills/` |
| **OpenAI Codex** | `bash install.sh --agent codex` | `~/.codex/skills/` |
| **Cline** | Merge dictionary/rules manually | `.clinerules/` |
| **Cursor** | Merge dictionary/rules manually | `.cursor/rules/` |
| **Windsurf** | Merge dictionary/rules manually | `.windsurfrules/` |
| **GitHub Copilot** | Use `gh skill install` or project custom instructions | `.github/skills/` or `.github/copilot-instructions.md` |
| **Any SKILL.md reader** | Copy all skill folders to your agent's skill directory | varies |

### Manual Copy

```bash
git clone https://github.com/khushalmistry/shorthand-skill.git
cd shorthand-skill

mkdir -p ~/.codex/skills
cp -R skills/shorthand ~/.codex/skills/
cp -R skills/shorthand-dict ~/.codex/skills/
cp -R skills/shorthand-commit ~/.codex/skills/
cp -R skills/shorthand-compress ~/.codex/skills/
cp -R skills/tool-setup ~/.codex/skills/
cp -R skills/port-scanner ~/.codex/skills/
```

### Other Agents (Cline, Cursor, Windsurf)

For agents that don't use a `skills/` directory, merge the dictionary and core shorthand rules into your agent's rules file:

```bash
# Cline
cat skills/shorthand/SKILL.md skills/shorthand/references/DICTIONARY.md >> .clinerules

# Cursor
cat skills/shorthand/SKILL.md skills/shorthand/references/DICTIONARY.md >> .cursor/rules

# Windsurf
cat skills/shorthand/SKILL.md skills/shorthand/references/DICTIONARY.md >> .windsurfrules
```

### GitHub CLI

```bash
gh skill preview khushalmistry/shorthand-skill shorthand
gh skill install khushalmistry/shorthand-skill shorthand
```

### Universal Prompt (Works Everywhere)

If you can't install skill files, just paste this into your agent's system prompt or first message:

> Load the shorthand dictionary from https://github.com/khushalmistry/shorthand-skill/blob/main/skills/shorthand/references/DICTIONARY.md — it defines all shorthand symbols and abbreviations. From now on, use shorthand notation (⚡, ↩, ⊕, ✗, §) when writing or reading skill files. Compress representation, preserve information.

## Compatibility

Works with any agent that reads markdown skill files:

| Agent | Status |
|-------|--------|
| Hermes Agent | ✅ Via `--agent hermes` |
| Claude Code | ✅ Via `--agent claude` |
| OpenCode | ✅ Via `--agent opencode` |
| Codex (OpenAI) | ✅ Via `--agent codex` |
| GitHub CLI skills | ✅ `gh skill publish --dry-run .` passes |
| Cline / Cursor / Windsurf | ✅ Manual rules-file merge |
| Any SKILL.md reader | ✅ Copy skill folders |

## Why Not Just...

- **Caveman** — Caveman compresses *agent output* (what the agent says). Shorthand compresses *skill definitions* (what the agent reads). They complement each other perfectly — use both for maximum savings.
- **gzip/brotli** — Compression algorithms make files smaller on disk but the agent still reads the uncompressed version. Shorthand compresses what the agent actually *sees*.
- **Just write shorter** — Shorthand is a **systematic** notation with a dictionary, symbols, and patterns. It's not "write less" — it's "encode efficiently."

## Credits

Inspired by court stenography — the technique used in courtrooms for centuries to capture every word at 200+ WPM using symbolic notation. Same principle, applied to AI skill definitions.

## License

MIT — free to use, modify, and distribute.
