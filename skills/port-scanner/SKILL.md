---
name: "port-scanner"
description: >
  Authorized network reconnaissance skill in shorthand format. Use only for
  in-scope systems where the operator has explicit permission to run port scans,
  service detection, and optional stealth/evasion checks.
license: MIT
tier: 3
category: "reconnaissance"
version: "1.0.0"
author: "shorthand-skill"
created: "2026-06-05"
updated: "2026-06-05"
status: "stable"
tags: [reconnaissance, port-scanning, network-enumeration, service-identification]
depends:
  - name: "tool-setup"
    tier: 1.5
    required: y
conflicts: [masscan]
produces: [port_scan_results, service_fingerprint, os_fingerprint, host_discovery]
consumes: [target_specification, scope_definition]
---

# ⇢ port-scanner (t3)

Network reconnaissance skill. Wraps nmap with intelligent scan strategy, result parsing, fallback chain, and compliance-aligned reporting.

## §2 tri

### Auto-triggers
- Recon/Enum phase starts
- Higher-tier skill needs port/service info
- New in-scope host discovered (unscanned)
- Operator requests: "scan <target>", "enumerate services", "what OS"

### Authorization gate
- ✓ Explicit permission for target and scan type is required before RUN
- ✓ Scope document must include target or target range
- ✗ If permission/scope missing → ask operator, log blocked, RET no-op
- ⚠ Stealth/evasion modes require explicit written authorization

### ✗ When NOT to use
- Masscan better for /16+ (10x faster raw port discovery)
- Target out of scope — ∞ verify first
- Authorization not confirmed — never probe first and ask later
- Only web testing needed → use web-specific tools
- Already fully scanned this engagement (avoid redundant)

## §3 pre

### Sys req

| Req | Type | chk | Auto? |
|-----|------|-----|-------|
| nmap | bin | `which nmap && nmap --version` | y ⊕ tool-setup() |
| cap_net_raw | priv | `getcap $(which nmap) \| grep cap_net_raw` | y (post_install="setcap") |
| sudo | priv | `sudo -n true 2>/dev/null; echo $?` | n |
| Disk >500MB | res | `df -h && awk` | n |

### Skill deps

| Skill | Tier | req | Why |
|-------|------|-----|-----|
| tool-setup | 1.5 | y | Ensures nmap binary available |

### Inputs

| Input | Type | req | def | Format |
|-------|------|-----|-----|--------|
| target | str | y | — | IP, CIDR, hostname, range |
| scan_type | str | n | "standard" | quick/standard/full/stealth/udp/comprehensive/custom |
| ports | str | n | auto by type | "1-1000","80,443","U:53,T:21-25" |
| timing | str | n | T4 trusted | T0–T5 |
| output_format | str | n | "all" | xml/grepable/normal/all |
| script | str | n | — | NSE: vuln,auth,default,discovery |

### Env
- ✓ Net access to target (L3)
- ✓ Target in scope
- ⚡ SYN needs root OR cap_net_raw
- ⚠ UDP slow/unreliable — only if needed
- ⚠ IDS/IPS may detect aggressive → adjust timing

## §4 calls

### → TO

| Skill | Tier | When | Params | On Fail |
|-------|------|------|--------|---------|
| tool-setup | 1.5 | nmap not found | name="nmap", method="auto", verify=y, post_install="setcap" | s:nmap_avail=false, degrade to nc |

### ← BY

| Skill | Tier | Why | Params |
|-------|------|-----|--------|
| recon-initial | 2 | Initial scan | target, scan_type="standard" |
| service-enum | 2 | Svc versions | target, script="default,vulns" |
| db-attack | 2 | Check DB ports | target, ports="1433,3306,5432" |
| web-testing | 2 | Find web ports | target, ports="80,443,8080,8443" |
| lateral-move | 2 | Map internal | target, scan_type="quick" |

### Syntax
```
⊕ tool-setup(name="nmap", method="auto", verify=y, post_install="setcap")
IF FAIL → LOG "[scanner] nmap unavailable", s:nmap_avail=false, CONTINUE

⊕ port-scanner(target="10.0.0.1", scan_type="standard")
⊕ port-scanner(target="10.0.0.1", ports="1433,3306,5432", scan_type="custom")
```

## §5 app

### ⚡ SYN Half-Open (PRIMARY)
```
When: default. root/cap available. fast, stealthy, reliable.
Cmd:  nmap -sS -sV -O --top-ports <N> -T<time> --osscan-guess --max-os-tries 3
      -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
Pro:  fast, stealthy (no handshake), most accurate
Con:  needs root/cap_net_raw
OK:   open/closed/filtered + OS guess conf >80%
FAIL: "requires root", hang >2x expected, 100% filtered
```

### ↩A TCP Connect (FALLBACK A)
```
When: no root, no cap. Full TCP handshake.
Cmd:  nmap -sT -sV --top-ports <N> -T<time>
      -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
Pro:  works without privs, svc versions still work
Con:  no OS detect, slower, noisier, logged by target
OK:   port results with svc versions
FAIL: all filtered or extremely slow
```

### ↩B Fragmented SYN (FALLBACK B — EVASION)
```
When: IDS/IPS blocking standard SYN AND authorization explicitly allows evasion. Fragment pkts bypass simple rules.
Cmd:  nmap -sS -f -sV --top-ports <N> -T2 --data-length 24
      -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
Pro:  bypasses many IDS, SYN accuracy preserved
Con:  very slow, modern IDS may still catch, more pkt loss
OK:   more open ports than standard SYN (which was all filtered)
FAIL: still 100% filtered or timeout
```

### ↩C Decoy Scan (FALLBACK C — ADVANCED EVASION)
```
When: frag+slow still detected AND authorization explicitly allows decoys. Hide source among decoys.
Cmd:  nmap -sS -D RND:<N> --source-port 53 -sV --top-ports <N> -T2
      -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
Pro:  very hard to attribute
Con:  extremely slow, lots of traffic, decoys may alert target
OK:   any unfiltered results
FAIL: complete block or all probes timeout
```

### ↩Z nc / /dev/tcp (LAST RESORT — SAFE)
```
When: nmap unavailable or all scan types blocked. Safe — engagement continues.
Steps:
  1. CHK nc available
  2. IF y → nc -zv -w3 <tgt> <port> per port
  3. IF n → bash /dev/tcp probe
  4. Iterate top-100 ports only → open/closed
  5. No svc/OS detect. Minimal info.
Pro:  works with nothing, no install needed
Con:  no svc/OS, extremely slow, no stealth
```

### Scan Type → Approach

| scan_type | ports | timing | scripts | OS | App Priority |
|-----------|-------|--------|---------|----|-------------|
| quick | 100 | T4 | — | n | 1→2→Z |
| standard | 1000 | T4 | default | y | 1→2→3→Z |
| full | 65535 | T3 | default | y | 1→2→Z |
| stealth | 100 | T2 | — | n | 3→4→1→2 |
| udp | top100 UDP | T3 | default | n | 1→2→Z |
| comprehensive | 65535 | T3 | vuln,auth,default,discovery | y | 1→2→Z |
| custom | user | user | user | user | 1→2→Z |

## §6 ins

### P1: Pre-Flight
```
1. VERIFY authorization + scope: <target> in scope config AND scan type allowed?
   ✗ → ASK operator for written permission or scope update, LOG "REJECTED: out of scope/unauthorized", RET fail

2. VERIFY nmap: ⊕ tool-setup(name="nmap", method="auto", verify=y, post_install="setcap")
   IF s:nmap_avail=y → CHK root/cap → s:scan_cap="syn"|"connect"
   ELSE → s:scan_cap="nc_fb"

3. DETERMINE params by scan_type (see table above)

4. MKDIR ~/output/scanner/
```

### P2: Execute
```
1. BUILD command from scan_type table + scan_cap
2. RUN <cmd> only after authorization gate passes; timeout=(topN/100)*60s min, max 3600s
   MONITOR: hang → kill+slow timing, "host down" → add -Pn, 100% filtered → ↩B/↩C
3. CAPTURE exit: 0=ok, 1=partial, 2=error
   IF exit=2 → LOG error, attempt ↩ approach
```

### P3: Parse & Normalize
```
1. PARSE XML from ~/output/scanner/<tgt>_<type>_<ts>.xml
2. NORMALIZE to structured JSON (meta, hosts, ports, svc, os, scripts)
3. WRITE ~/output/scanner/<tgt>_<type>_<ts>_normalized.json
4. SET state variables
```

### P4: Assessment
```
1. Flag high-interest ports: 21/FTP, 22/SSH, 23/Telnet, 53/DNS,
   80/443/HTTP(S), 445/SMB, 1433/3306/5432/DBs, 3389/RDP, 8080/alt-http
2. CREATE preliminary findings for NSE "VULNERABLE" results
3. CROSS-REF scope document
```

### err

| Code | Err | Action | Retry |
|------|-----|--------|-------|
| E_HOST_DOWN | Host seems down | Add `-Pn`, retry | y(1x) |
| E_NO_ROOT | SYN needs root | Switch -sT | n |
| E_TIMEOUT | Scan timeout | Reduce timing/ports | y(1x) |
| E_ALL_FILTERED | All filtered | Try ↩B/↩C | y(1x) |
| E_BAD_PORTS | Bad port spec | Use default top-ports | n |
| E_NSE_ERR | NSE script error | Remove failing script | y(1x) |
| E_DNS_FAIL | DNS failed | Use `-n`, scan by IP | n |

### st

| Key | Persist | Def | Desc |
|-----|---------|-----|------|
| s:nmap_avail | engagement | n | nmap installed? |
| s:scan_cap | engagement | nc_fb | syn/connect/nc_fb |
| s:last_scan | session | "" | Last scan ts |
| s:t_<ip>_ports | engagement | [] | Open ports |
| s:t_<ip>_svc | engagement | [] | Services |
| s:t_<ip>_os | engagement | {} | OS fingerprint |

## §7 find

### Artifacts

| Artifact | Type | Path | Retain |
|----------|------|------|--------|
| Raw output | file | ~/output/scanner/\<tgt\>_\<type\>_\<ts\>.nmap | engagement |
| XML | file | ~/output/scanner/\<tgt\>_\<type\>_\<ts\>.xml | engagement |
| Grepable | file | ~/output/scanner/\<tgt\>_\<type\>_\<ts\>.gnmap | engagement |
| Normalized JSON | file | ~/output/scanner/\<tgt\>_\<type\>_\<ts\>_normalized.json | engagement |

### Identification Patterns

| Find | Pattern | Sev | Conf |
|------|---------|-----|------|
| Open port | `STATE: open` | I | H |
| Filtered (fw) | `STATE: filtered` | L | M |
| Service version | `VERSION: <prod> <ver>` | I→feeds vuln correlation | H |
| OS fingerprint | `OS: <name> <ver> acc <N>%` | I→exploit targeting | M-H |
| NSE VULNERABLE | Script contains "VULNERABLE" | varies | M |
| Expired SSL | ssl-cert shows expired | M | H |
| Anon FTP | ftp-anon: "Anonymous FTP login allowed" | M | H |
| SMB signing off | smb-security-mode: "signing: disabled" | M | H |

### fp (False Positives)
- All filtered → may be host down → verify with `-Pn` + ICMP
- svc "unknown" → nmap couldn't fingerprint → probe manually
- OS guess <80% → too many possibilities → don't rely for exploit selection
- "VULNERABLE" false alarms → some scripts aggressive → verify before reporting

### Negative Results
All ports closed/filtered + host up → try `-Pn`, try UDP for DNS/SNMP, consider honeypot, **LOG "no ports found"** (this IS a finding), move to web testing if web ports expected.

## §8 rpt

### Compliance

OWASP-T10: A05 — Security Misconfiguration → Direct
OWASP-T10: A07 — Identification & Auth Failures → Direct
ASVS: V1.2 — Architecture → Direct
ASVS: V9.1 — Communications Security → Direct
NIST53: CM-7 — Least Functionality → Direct
NIST53: SC-7 — Boundary Protection → Direct
MITRE: T1046 — Network Service Discovery → Direct
PTES: 02 — Intelligence Gathering → Direct
CIS: 4.1 — Secure Configuration → Direct
OSSTMM: 4.1 — Network Services → Direct

### Finding Templates

**F1 — Open Port (Baseline):**
```
F: Open Service Port — <svc>(<port>/<proto>)
  Cls: non-com
  Sev: I (↑ for risky svcs)
  Ref: CIS 4.1 — Secure Config; NIST53 CM-7
  Desc: <svc> on <port>/<proto>. Product: <prod> <ver> (conf:<N>/10).
  Evi: nmap -sV → "<port>/tcp open <svc> <prod> <ver>"
  Rem: Disable if not required. Harden if required (strong auth, patches, net restriction).
  Com: Severity upgraded per context — see F2.
```

**F2 — Insecure Protocol:**
```
F: Insecure Protocol Exposed — <svc> on <port>
  Cls: non-com
  Sev: H
  Ref: ASVS V9.1.1; OWASP-T10 A05; NIST53 SC-8
  Desc: Cleartext/unencrypted svc: <svc> on <port>. Risk: <specific risk>
  Evi: nmap -sV identified <prod> <ver> on <port>
  Rem: Disable <svc>. Replace with secure alternative (SSH↔Telnet, SFTP↔FTP).
  Com: Direct compliance violation for encrypted comms standards.
```

**F3 — No Open Ports (Hardened):**
```
F: No Open Ports — Possible Hardened Configuration
  Cls: comply
  Sev: I
  Ref: CIS 4; NIST53 CM-7
  Desc: Zero open ports on <target> via <approach>. May be hardened, strict fw, or host down.
  Evi: nmap shows 0 open ports across <N> scanned ports
  Rem: N/A (positive finding). Verify host operational + intentional hardening.
  Com: Verify not host down or transient fw state.
```

### Report Rules
1. ✅ Add EVERY open port to Network Enumeration
2. ✅ Dedicated finding for high-risk svcs (Telnet, FTP, RDP, etc.)
3. ✅ Finding for expired/invalid SSL certs
4. ✅ Mark `comply` for properly secured, `non-com` for insecure, `NA` for untested
5. ✅ ⟐ DB port found → flag for db-attack skill
6. ✅ ⟐ HTTP port found → flag for web-testing skill
7. ✅ ⟐ SMB port found → flag for smb-enum skill

## §9 xtra

### Limitations
- SYN needs root/cap → Connect ↩A loses OS detect
- UDP inherently unreliable
- OS fingerprint can be wrong → verify with secondary methods
- NSE false alarms possible → verify manually
- Large scans (/16+) → use masscan first, then targeted nmap

### Tuning
- Quick first → escalate only if needed
- `-oA` always — partial results still valuable
- `--min-hostgroup` + `--min-parallelism` for multi-target
- `--resume <logfile>` for interrupted scans

### Anti-Detection
- T0/T1: IDS evasion | T4/T5: speed
- `-f` or `-f -f`: fragment | `-D RND:N`: decoys
- `--source-port 53/20`: bypass stateless fws
- `--randomize-hosts`: avoid sequential patterns
- `-sI <zombie>`: idle scan (truly blind)

### Integration
- Chain: engagement-plan → scanner(quick) → scanner(standard found hosts) → svc-enum → attack
- Check `s:t_<ip>_ports` before re-scanning — avoid redundant
- Masscan+nmap pattern: masscan for discovery → nmap -p <found_ports> for detail

### Timing

| T | Name | Use | Speed |
|---|------|-----|-------|
| T0 | Paranoid | IDS evasion | ~1 port/5min |
| T1 | Sneaky | IDS evasion | ~1 port/15s |
| T2 | Polite | Less noisy | ~1 port/0.4s |
| T3 | Normal | Balanced | ~1 port/0.1s |
| T4 | Aggressive | Trusted | ~1 port/0.01s |
| T5 | Insane | Speed over accuracy | Very fast |

### Refs
- https://nmap.org/book/man.html
- https://nmap.org/nsedoc/
- https://attack.mitre.org/techniques/T1046/
- http://www.pentest-standard.org/

*End skill: port-scanner v1.0.0*
