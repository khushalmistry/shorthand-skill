---
name: "tool-setup"
description: >
  Authorized dependency setup skill in shorthand format. Use when another skill
  needs a missing CLI tool, with explicit approval before network downloads,
  package-manager changes, sudo, setcap, or source builds.
license: MIT
tier: 1.5
category: "tooling"
version: "1.0.0"
author: "shorthand-skill"
created: "2026-06-05"
updated: "2026-06-05"
status: "stable"
tags: [tooling, installation, dependencies, infrastructure]
depends: []
conflicts: []
produces: [tool_availability_status, installation_log]
consumes: [tool_requirement_spec]
---

# ⇢ tool-setup (t1.5)

Universal dependency resolver. Ensures pentest tools are present, installed, verified, ready. Called by every higher-tier skill before execution. Centralizes installation logic so skills don't duplicate.

## §2 tri

### Auto-triggers
- Higher-tier skill references a tool not available on system
- `⊕ tool-setup(name="x")` called by any skill
- Tool check returns exit 127 (not found)
- Pre-engagement checklist identifies missing tools

### Manual
- "install nmap", "make sure sqlmap is available", "setup all tools"

### Approval gate
- ✓ Ask operator before network download, package-manager install, sudo, setcap, symlink, or source build
- ✓ Prefer user-local paths (`~/tools`, `pip --user`) when approval for system changes is absent
- ✗ If approval denied → ↩Z manual/skip; do not mutate system

### ✗ When NOT to use
- Tool already verified installed + correct version
- Operator explicitly says "skip installation"
- Constrained environment (read-only forensic mode)
- Tool requires GUI in headless environment (warn + skip)

## §3 pre

### Sys req

| Req | Type | chk | Auto? |
|-----|------|-----|-------|
| sudo/root | priv | `sudo -n true 2>/dev/null; echo $?` | n |
| Internet | net | `curl -s --connect-timeout 5 https://github.com > /dev/null; echo $?` | n |
| pkg manager | pkg | `which apt \|\| which yum \|\| which apk \|\| which brew` | n |
| Python 3.8+ | bin | `python3 --version` | y (via ensurepip) |
| pip3 | pkg | `pip3 --version` | y |
| ~/tools/ | dir | `test -d ~/tools/ && echo exists` | y |
| ~/logs/setup/ | dir | `test -d ~/logs/setup/ && echo exists` | y |

### Skill deps

None — this is t1.5 with zero skill dependencies.

### Inputs

| Input | Type | req | def | Format |
|-------|------|-----|-----|--------|
| name | str | y | — | Tool name (e.g., "nmap", "sqlmap") |
| method | str | n | "auto" | apt/pip/snap/brew/github-release/source/auto |
| version | str | n | "latest" | Semver or "latest" |
| verify | bool | n | y | Run verification after install |
| quiet | bool | n | n | Suppress output except errors |
| post_install | str | n | "" | Additional config (e.g., "setcap") |

### Env
- ✓ Internet required for most methods
- ✓ sudo/root for system packages
- ⚠ Offline mode if tool cached in ~/tools/cache/
- ⚠ Write access to /usr/local/bin/ or ~/tools/

## §4 calls

### → TO: None (t1.5 calls no other skills)

### ← BY

| Skill | Tier | Why | Params |
|-------|------|-----|--------|
| port-scanner | 3 | Ensure nmap exists | name="nmap", method="auto", verify=y |
| sql-injector | 3 | Ensure sqlmap installed | name="sqlmap", method="pip" |
| web-fuzzer | 3 | Ensure ffuf binary | name="ffuf", method="apt" |
| nuclei-scanner | 3 | Ensure nuclei installed | name="nuclei", method="github-release" |
| engagement-plan | 1 | Pre-stage all tools | name="batch", tools=["nmap","nikto","sqlmap"] |

### Syntax
```
⊕ tool-setup(name="nmap", method="auto", verify=y)
IF FAIL:
  LOG "[setup] FAILED <name> via <method>" to ~/logs/setup/
  SET s:<name>_avail=false
  ATTEMPT next fallback method
  IF ALL EXHAUSTED:
    LOG "[setup] <name> UNAVAILABLE — calling skill may degrade"
    RET fail(name="<name>", reason="all methods exhausted")
```

## §5 app

### ⚡ System Package Manager (PRIMARY)
```
When: Tool in OS package manager. Fastest, most reliable.
Steps:
  1. Detect OS + pkg manager (apt/yum/apk/brew/snap)
  2. ASK approval for package-manager change and sudo if needed
  3. Update package index only after approval
  4. Install via detected manager
  5. Verify with version check
  6. SET s:<name>_avail=true, s:<name>_method="pkg"
Pro:  fast, reliable, auto-deps, signed packages
Con:  may not have latest version, some tools not in repos, needs sudo
OK:   which <tool> returns 0 AND <tool> --version returns expected
FAIL: package not found, sudo denied, network timeout
```

### ↩A pip (FALLBACK A)
```
When: Python package or not in system repos.
Steps:
  1. Verify Python 3.8+ + pip3
  2. pip3 install <tool> (--user if no sudo)
  3. Verify import/version
Pro:  always latest, works without sudo (--user), huge ecosystem
Con:  no system-level deps, may need venv, version conflicts
OK:   pip3 show <tool> returns metadata AND version check passes
FAIL: pip install fails, import error, permission denied
```

### ↩B GitHub Release Binary (FALLBACK B)
```
When: Tool distributes pre-built binaries via GitHub. Not in repos or pip.
Steps:
  1. ASK approval for network download + local binary install
  2. Query GitHub API for latest release
  3. Parse assets for matching OS/arch
  4. Download to ~/tools/cache/<name>/
  5. Extract if archive (tar/zip)
  6. chmod +x, symlink to ~/tools/bin/<name>
  7. Verify: <tool> --version
Pro:  always latest, no compile, works for Go/Rust binaries
Con:  needs GitHub repo URL, may not have all platforms
OK:   binary executes and returns version string
FAIL: download fails, wrong architecture, glibc mismatch
```

### ↩C Source Build (FALLBACK C)
```
When: No binary available. Must compile from source.
Steps:
  1. ASK approval for clone/build/install
  2. git clone to ~/tools/cache/<name>/src/
  3. Check Makefile/setup.py/Cargo.toml/go.mod
  4. Install build deps only after approval
  5. Build + install
  6. Verify + clean artifacts
Pro:  works for any source-available tool, maximum build control
Con:  slow, requires build toolchain, dependency loops possible
OK:   built binary runs and returns version
FAIL: build fails, missing compiler, dependency loop
```

### ↩Z Manual / Skip (LAST RESORT — SAFE)
```
When: All methods exhausted or environment forbids installation.
Steps:
  1. LOG failure with full details to ~/logs/setup/<name>_<ts>.log
  2. SET s:<name>_avail=false, s:<name>_setup_failed=true
  3. Suggest manual installation steps to operator
  4. Identify which skills will degrade (trace depends)
  5. Continue engagement — do NOT halt
Pro:  safe, no damage, engagement continues
Con:  skills that need this tool degrade or skip
```

## §6 ins

### P1: Check & Decide
```
1. INPUT: name="<tool>", method="<method>", version="latest", verify=y

2. CHK: which <tool> 2>/dev/null
   IF found AND verify=y → RUN <tool> --version
   IF version matches → SET s:<name>_avail=true, RET success(already_installed)
   IF found AND verify=n → RET success(skip_verification)
   IF version mismatch → LOG "wrong version, proceeding with install"

3. DECIDE method:
   IF method="auto" → lookup INSTALL_REGISTRY → try ⚡→↩A→↩B→↩C→↩Z
   IF method specified → use that method directly

4. APPROVAL:
   IF method mutates system OR downloads/builds code → ASK operator first
   IF denied → ↩Z manual/skip
```

### P2: Execute Installation
```
1. ATTEMPT selected approach (see §5 steps)

2. IF success:
   VERIFY (P3)
   SET s:<name>_avail=true, s:<name>_method=<approach>, s:<name>_path=<path>
   LOG "[setup] SUCCESS: <name> via <method> at <path>"
   LOG to ~/logs/setup/<name>_<ts>.log
   RET success(name=<name>, method=<method>, path=<path>, version=<ver>)

3. IF fail:
   LOG "[setup] FAILED: <name> via <method> — <error>"
   IF more fallbacks → try next approach
   IF all exhausted → P4
```

### P3: Post-Install Verification
```
1. IF verify=y:
   RUN: <tool> --version
   IF passes → smoke test: <tool> --help > /dev/null
   IF post_install contains "setcap" → ASK approval, then sudo setcap cap_net_raw+ep $(which <tool>)
   IF passes → RET verified

2. IF verify=n:
   LOG "[setup] verification skipped"
   RET installed_unverified
```

### P4: Post-Install Config
```
1. IF tool needs config (wordlists, API keys, templates):
   CHK: ~/config/<tool>/ exists? IF NOT → create default structure
2. IF tool needs wordlists:
   CHK: ~/wordlists/ exists? IF NOT → LOG warning
3. IF tool needs API keys:
   CHK: ~/config/<tool>/api.key exists? IF NOT → LOG warning, SET s:<name>_api_key=false
```

### err

| Code | Err | Action | Retry |
|------|-----|--------|-------|
| E_PKG_NOT_FOUND | Package not in repo | Try next fallback | n |
| E_SUDO_DENIED | sudo permission denied | Try --user install | n |
| E_NET_TIMEOUT | Network timeout | Retry once (10s) | y(1x) |
| E_DISK_FULL | Disk space insufficient | Log, suggest cleanup | n |
| E_ARCH_MISMATCH | Wrong architecture binary | Try different release asset | n |
| E_BUILD_FAIL | Build compilation failed | Log, try next fallback | n |
| E_VERIFY_CRASH | Tool crashes on verify | Uninstall, try different method | y(1x) |

### st

| Key | Persist | Def | Desc |
|-----|---------|-----|------|
| s:<name>_avail | engagement | n | Tool ready to use? |
| s:<name>_path | engagement | "" | Full path to binary |
| s:<name>_ver | engagement | "" | Installed version |
| s:<name>_method | engagement | "" | How installed |
| s:<name>_api_key | session | n | API key configured? |
| s:<name>_setup_failed | engagement | n | All install methods failed? |

## §7 find

### Artifacts

| Artifact | Type | Path | Retain |
|----------|------|------|--------|
| Install log | file | ~/logs/setup/\<name\>_\<ts\>.log | engagement |
| Tool status | var | s:\<name\>_avail | engagement |
| Fail report | file | ~/logs/setup/failed/\<name\>.log | engagement |

### Expected Results

**Success:**
```
[setup] Checking nmap... NOT FOUND
[setup] ⚡ Approach 1: System Package Manager (apt)
[setup] Running: sudo apt-get update && sudo apt-get install -y nmap
[setup] Installing... done (12.3s)
[setup] Verifying: nmap --version → 7.94
[setup] Post-install: sudo setcap cap_net_raw+ep $(which nmap)
[setup] SUCCESS: nmap via apt at /usr/bin/nmap, v7.94
[setup] s:nmap_avail=true, s:nmap_method=apt, s:nmap_path=/usr/bin/nmap
```

**Already Installed:**
```
[setup] Checking nmap... FOUND at /usr/bin/nmap
[setup] Verifying: nmap --version → 7.94
[setup] SKIP: nmap already available
```

**All Failed:**
```
[setup] Checking custom-tool... NOT FOUND
[setup] ⚡ (apt): Package not found → SKIP
[setup] ↩A (pip): Not a Python package → SKIP
[setup] ↩B (github): No matching binary → SKIP
[setup] ↩C (source): Build failed → SKIP
[setup] ↩Z (manual): Logging failure, suggesting manual install
[setup] FAILED: custom-tool unavailable — all methods exhausted
[setup] Affected skills: port-scanner (will degrade/skip)
```

### Identification Patterns

| Find | Pattern | Sev | Conf |
|------|---------|-----|------|
| Tool in PATH | `which <tool>` exit 0 | I | H |
| Version matches | Output contains version string | I | H |
| Has capabilities | `getcap` shows caps | I | M |
| Install failed | s:<name>_setup_failed=true | H | H |
| API key missing | Config file absent | M | H |

### fp
- Tool is alias/shell function (not real binary) → verify with `file $(which <tool>)`
- Tool exists but outdated → version check catches this
- Tool installed but broken (missing shared libs) → `ldd` check

### Negative Results
Tool cannot be installed → **degradation event**, NOT a finding. Engagement continues. Skills adapt.

## §8 rpt

### Compliance

PTES: 01.1 — Engagement Planning → Indirect
NIST53: CM-7 — Least Functionality → Indirect
ISO 27001: A.12.6 — Technical Vulnerability Mgmt → Indirect

### Finding Template (critical tool failure):
```
F: Required Tool Unavailable — <name>
  Cls: NA
  Sev: I
  Ref: PTES 01.1 — Engagement Planning
  Desc: <name> could not be installed. All methods attempted: <methods>.
        Tests requiring this tool were not performed.
  Evi: ~/logs/setup/failed/<name>.log
  Rem: Install <name> manually before re-engagement. Best method: <best_method>
  Com: Affected tests marked NA in findings. Engagement NOT halted.
```

### Report Rules
1. ✅ Add installed tools to Methodology → Tool Inventory
2. ✅ Add finding when CRITICAL tool fails
3. ❌ No finding for non-critical tool failures (log only)
4. ✅ Mark specific tests as NA if they require a failed tool
5. ✅ ⟐ trace affected skills via depends chain

## §9 xtra

### Limitations
- No GUI tool installation in headless environments
- No paid license tools (Burp Suite Pro, Nessus)
- No circular build dependency resolution
- Offline requires pre-cached binaries in ~/tools/cache/
- Some tools need kernel modules (DTrace, etc.) — can't install

### Tuning
- Cache first: always check ~/tools/cache/ before downloading
- Batch install: method="batch" for multiple tools
- Skip if available: first check saves 30+ seconds per tool
- Version pinning: set version param to avoid upgrades

### Anti-Detection
- Package manager calls appear in system logs → cleanup if stealth needed
- GitHub downloads leave DNS records → use proxy if opsec demands
- pip logs may contain package names → ~/.pip/

### Debugging
- "installed but not found" → PATH not updated → source shell profile
- "permission denied" → try pip3 install --user
- "build fails" → check ~/logs/setup/<name>_<ts>.log
- "version wrong" → uninstall first, then install pinned version

### Built-In Tool Registry

| Tool | Primary | Fallback | GitHub |
|------|---------|----------|--------|
| nmap | apt | brew, source | github.com/nmap/nmap |
| sqlmap | pip | apt, github | github.com/sqlmapproject/sqlmap |
| nikto | apt | pip, github | github.com/sullo/nikto |
| gobuster | apt | github | github.com/OJ/gobuster |
| nuclei | github | source | github.com/projectdiscovery/nuclei |
| httpx | github | source | github.com/projectdiscovery/httpx |
| ffuf | apt | github | github.com/ffuf/ffuf |
| hydra | apt | source | github.com/vanhauser-thc/thc-hydra |
| john | apt | source | github.com/openwall/john |
| hashcat | apt | github | github.com/hashcat/hashcat |

### Refs
- https://packages.debian.org/
- https://pypi.org/
- https://www.kali.org/tools-list/

*End skill: tool-setup v1.0.0*
