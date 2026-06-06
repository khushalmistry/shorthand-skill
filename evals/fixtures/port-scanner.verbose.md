---
name: "port-scanner-verbose-baseline"
description: >
  Verbose baseline used by the shorthand-skill evaluation suite. This file
  describes the same required port-scanner behavior in normal prose so the
  evaluator can verify whether the shorthand version preserves the important
  facts while using fewer words.
license: MIT
---

# Port Scanner Verbose Baseline

This document is the long-form baseline for the `port-scanner` skill. It is not
the version an agent should install by default. It exists so the evaluation
suite has a normal-language source of truth to compare against the compressed
shorthand skill at `skills/port-scanner/SKILL.md`.

The skill performs authorized network reconnaissance. It wraps `nmap` with a
clear scan strategy, fallback chain, result parsing workflow, evidence capture
rules, and compliance-aligned reporting. The compressed skill may use symbols,
short section names, compact tables, and abbreviated labels, but it must keep
the operational meaning described here.

## Skill Identity

The skill name is `port-scanner`. It is a tier 3 reconnaissance and tooling
skill. It depends on `tool-setup`, which is a tier 1.5 dependency resolver. The
skill produces port scan results, service fingerprints, operating system
fingerprints, and host discovery information. It consumes a target
specification and an engagement scope definition.

The skill conflicts with `masscan` when both are trying to own the same raw port
discovery workflow. `masscan` can be better for very large ranges, but this
skill remains responsible for targeted `nmap` detail, service identification,
and normalized evidence output.

## When To Use This Skill

Use this skill when the Recon/Enum phase starts, when a higher-tier skill needs
port or service information, when a new in-scope host has been discovered but
has not yet been scanned, or when the operator asks for a task such as "scan
the target", "enumerate services", or "what operating system is this host
running".

Before any command is executed, the authorization gate must pass. Explicit permission
for the target and scan type is required before RUN. The scope
document must include the target or target range. If permission or scope is
missing, the agent must ask the operator, log that the action is blocked, and
RET no-op. Stealth and evasion modes require explicit written authorization;
they are not implied by general permission to scan.

Do not use this skill when the target is out of scope, when authorization has
not been confirmed, when only web testing is needed and a web-specific tool is
more appropriate, or when the engagement already has a complete scan for the
same target and scan type. For very large networks such as /16+ ranges, prefer
`masscan` first for raw discovery and then use targeted `nmap` for detail.

## Prerequisites

The primary tool is `nmap`. Check for it with `which nmap && nmap --version`.
If nmap not found, call `tool-setup` with the parameters `name="nmap"`,
`method="auto"`, `verify=y`, and `post_install="setcap"`. The call is made
because `tool-setup` can install or locate the binary and then report whether
`nmap` is available. If `nmap` cannot be prepared, degrade to the `nc` fallback
instead of halting the engagement.

The primary SYN scan requires either root privileges or `cap_net_raw`. The
capability check is `getcap $(which nmap) | grep cap_net_raw`. A sudo check may
use `sudo -n true 2>/dev/null; echo $?`, but actual sudo actions are handled by
`tool-setup` and require explicit approval there. Disk space should be enough
for output artifacts, with 500MB as a conservative minimum.

Required input is `target`, which may be an IP address, CIDR block, hostname, or
range. Optional inputs include `scan_type`, `ports`, `timing`,
`output_format`, and `script`. The default scan type is `standard`, the default
timing for trusted targets is `T4`, and output should normally include all
formats so the engagement keeps human-readable output plus structured artifacts.

## Skill Calls

This skill calls `tool-setup` when `nmap` is not found. The call is:

```text
tool-setup(name="nmap", method="auto", verify=y, post_install="setcap")
```

On failure, record that `s:nmap_avail=false` and degrade to `nc` or `/dev/tcp`.
Other skills may call `port-scanner` when they need scan output. Example callers
include `recon-initial`, `service-enum`, `db-attack`, `web-testing`, and
`lateral-move`. Typical calls include a standard scan for a target, a custom
database-port scan for ports `1433,3306,5432`, and a web-port scan for
`80,443,8080,8443`.

## Approach 1: SYN Half-Open Primary Scan

The primary approach is SYN Half-Open scanning. Use it by default when root or
`cap_net_raw` is available. It is fast, reliable, and does not complete a full
TCP handshake. The command template is:

```text
nmap -sS -sV -O --top-ports <N> -T<time> --osscan-guess --max-os-tries 3
     -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
```

This approach gives open, closed, and filtered port states, service versions,
and an operating system guess. A strong success signal is an OS guess
confidence above 80%. The failure indicators are a "requires root" error, a
hang longer than twice the expected duration, or a result where every port is
filtered. The downside is that the method needs root or `cap_net_raw`.

## Approach 2: TCP Connect Fallback

The first fallback is TCP Connect scanning. Use it when there is no root and no
capability support. This approach performs a full TCP handshake. The command
template is:

```text
nmap -sT -sV --top-ports <N> -T<time>
     -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
```

TCP Connect still gives service version information and works without elevated
privileges. Its limitations are that there is no OS detect, it is slower, it is
noisier, and it is more likely to be logged by the target. It succeeds when it
returns port results with service versions. It fails when every port is filtered
or when the run is extremely slow.

## Approach 3: Fragmented SYN Fallback

The second fallback is Fragmented SYN. Use it only when standard SYN scanning is
blocked by IDS or IPS behavior and authorization explicitly allows evasion.
Fragmented packets can bypass simple rules, but the technique is slower and can
still be detected by modern systems. The command template is:

```text
nmap -sS -f -sV --top-ports <N> -T2 --data-length 24
     -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
```

This approach is useful when the normal SYN scan returns all filtered results
but the engagement allows testing with evasive behavior. It succeeds if it
returns more open ports than the standard SYN result. It fails if all ports are
still filtered or the scan times out.

## Approach 4: Decoy Scan Fallback

The third fallback is Decoy Scan. Use it only when fragmented and slow scans are
still detected and authorization explicitly allows decoys. The technique hides
the source among decoys and can make attribution harder, but it is slow and can
create extra traffic. The command template is:

```text
nmap -sS -D RND:<N> --source-port 53 -sV --top-ports <N> -T2
     -oA ~/output/scanner/<tgt>_<type>_<ts> <tgt>
```

This approach succeeds if it returns any useful unfiltered result. It fails when
the probes are completely blocked or all probes time out. Because decoys may
alert the target, this is not a default option and must remain behind the
authorization gate.

## Approach 5: nc / /dev/tcp Last Resort

The last resort is the `nc / /dev/tcp` fallback. Use it when `nmap` is
unavailable or all scan types are blocked. First check whether `nc` is
available. If it is, run `nc -zv -w3 <tgt> <port>` for each selected port. If
`nc` is unavailable, use a Bash `/dev/tcp` probe. Iterate over top-100 ports
only so the fallback stays bounded. This produces open or closed information
only. There is No svc/OS detection in this path. It is safe because it allows
the engagement to continue without installing anything, but it is slow and
minimal.

## Scan Type Matrix

For `quick`, scan 100 ports with timing `T4`, no scripts, no OS detection, and
approach priority 1 to 2 to Z. For `standard`, scan 1000 ports with timing `T4`,
default scripts, OS detection enabled, and approach priority 1 to 2 to 3 to Z.
For `full`, scan 65535 ports with timing `T3`, default scripts, OS detection
enabled, and approach priority 1 to 2 to Z. For `stealth`, scan 100 ports with
timing `T2`, no scripts, no OS detection, and approach priority 3→4→1→2. For
`udp`, scan top100 UDP ports with timing `T3`, default scripts, no OS detection,
and approach priority 1 to 2 to Z. For `comprehensive`, scan 65535 ports with
timing `T3`, scripts `vuln,auth,default,discovery`, OS detection enabled, and
approach priority 1 to 2 to Z. For `custom`, use the user-provided ports,
timing, scripts, and OS setting.

## Instructions

Pre-flight begins with `VERIFY authorization + scope`. Confirm that the target
is in the scope configuration and that the requested scan type is allowed. If
the check fails, ask the operator for written permission or a scope update, log
`REJECTED: out of scope/unauthorized`, and return failure without probing the
target.

Next verify `nmap` by calling `tool-setup(name="nmap", method="auto", verify=y,
post_install="setcap")`. If `s:nmap_avail=y`, check root or capability and set
`s:scan_cap` to either `syn` or `connect`. If `nmap` is not available, set
`s:scan_cap` to `nc_fb`. Then DETERMINE params from the scan type table and
MKDIR ~/output/scanner/.

Execution builds a command from the scan type table and the scan capability.
Run the command only after the authorization gate passes. The timeout is
calculated as `(topN/100)*60s` with a reasonable minimum and a maximum of 3600s.
Monitor for hangs, host-down indications, and 100% filtered results. If the host
seems down, add `-Pn`. If every port is filtered, try the authorized fallback
path. Capture exit codes: 0 means okay, 1 means partial, and 2 means error.

Parsing and normalization begins by reading the XML output from
`~/output/scanner/<tgt>_<type>_<ts>.xml`. PARSE XML into host, port, service,
OS, and script data. NORMALIZE to structured JSON containing metadata, hosts,
ports, services, OS guesses, and script results. Write the normalized output to
`~/output/scanner/<tgt>_<type>_<ts>_normalized.json`. Then set state variables
that other skills can consume.

The assessment phase flags high-interest ports such as 21/FTP, 22/SSH,
23/Telnet, 53/DNS, 80/443/HTTP(S), 445/SMB, 1433/3306/5432 database services,
3389/RDP, and 8080 alternative HTTP. Create preliminary findings for NSE script
results containing "VULNERABLE". Cross-reference the scope document before
reporting.

## Errors

`E_HOST_DOWN` means the host seems down. The action is Add `-Pn`, retry, and
retry only once. `E_NO_ROOT` means SYN needs root. The action is Switch -sT and
do not retry the SYN path. `E_TIMEOUT` means the scan exceeded the timeout; the
action is to reduce timing or ports and retry once. `E_ALL_FILTERED` means all
ports are filtered; the action is Try ↩B/↩C once if authorization allows those
fallbacks. `E_BAD_PORTS` means the port specification is invalid; use default
top ports. `E_NSE_ERR` means an NSE script failed; remove the failing script and
retry once. `E_DNS_FAIL` means DNS failed; use `-n` and scan by IP.

## State

Persist `s:nmap_avail` for the engagement to indicate whether `nmap` is
installed. Persist `s:scan_cap` with a default of `nc_fb` and values such as
`syn`, `connect`, or `nc_fb`. Keep `s:last_scan` for the session timestamp.
Persist `s:t_<ip>_ports` as the list of Open ports. Persist `s:t_<ip>_svc` as
the discovered services and `s:t_<ip>_os` as the operating system fingerprint.

## Artifacts

The raw output is retained at
`~/output/scanner/\<tgt\>_\<type\>_\<ts\>.nmap`. The XML artifact is retained at
`~/output/scanner/\<tgt\>_\<type\>_\<ts\>.xml`. The grepable output is retained
at `~/output/scanner/\<tgt\>_\<type\>_\<ts\>.gnmap`. The normalized JSON is
retained at `~/output/scanner/\<tgt\>_\<type\>_\<ts\>_normalized.json`.

## Identification Patterns

An open port has the pattern `STATE: open` and is informational with high
confidence. A filtered port has `STATE: filtered` and is low severity with
medium confidence. A service version has `VERSION: <prod> <ver>` and feeds
vulnerability correlation. An OS fingerprint has `OS: <name> <ver> acc <N>%`
and should be used cautiously if confidence is low. NSE scripts containing
"VULNERABLE" create findings with context-dependent severity. Expired SSL
certificates are medium severity. Anon FTP is detected by `ftp-anon:
"Anonymous FTP login allowed"` and is medium severity. SMB signing off is
detected by `smb-security-mode: "signing: disabled"` and is medium severity.

False positives include all-filtered results that actually mean the host is
down, unknown services that `nmap` could not fingerprint, weak OS guesses below
80%, and aggressive NSE scripts that need manual verification. Negative results
are also useful: all ports closed or filtered with a host confirmed up should
be logged as "no ports found" and treated as an engagement finding.

## Compliance

Map network enumeration and exposed service findings to these controls:

- OWASP-T10: A05 — Security Misconfiguration → Direct
- OWASP-T10: A07 — Identification & Auth Failures → Direct
- ASVS: V1.2 — Architecture → Direct
- ASVS: V9.1 — Communications Security → Direct
- NIST53: CM-7 — Least Functionality → Direct
- NIST53: SC-7 — Boundary Protection → Direct
- MITRE: T1046 — Network Service Discovery → Direct
- PTES: 02 — Intelligence Gathering → Direct
- CIS: 4.1 — Secure Configuration → Direct
- OSSTMM: 4.1 — Network Services → Direct

## Finding Templates

For a baseline open service port, use this template:

```text
F: Open Service Port — <svc>(<port>/<proto>)
  Cls: non-com
  Sev: I (upgrade for risky services)
  Ref: CIS 4.1 — Secure Config; NIST53 CM-7
  Desc: <svc> on <port>/<proto>. Product: <prod> <ver> (conf:<N>/10).
  Evi: nmap -sV output showing "<port>/tcp open <svc> <prod> <ver>"
  Rem: Disable if not required. Harden if required with strong auth, patches, and network restriction.
  Com: Severity upgraded per context.
```

For an insecure protocol, use this template:

```text
F: Insecure Protocol Exposed — <svc> on <port>
  Cls: non-com
  Sev: H
  Ref: ASVS V9.1.1; OWASP-T10 A05; NIST53 SC-8
  Desc: Cleartext or unencrypted service <svc> on <port>.
  Evi: nmap -sV identified <prod> <ver> on <port>
  Rem: Disable <svc>. Replace with secure alternative such as SSH instead of Telnet or SFTP instead of FTP.
  Com: Direct compliance violation for encrypted communications standards.
```

For no open ports, use this template:

```text
F: No Open Ports — Possible Hardened Configuration
  Cls: comply
  Sev: I
  Ref: CIS 4; NIST53 CM-7
  Desc: Zero open ports on <target> via <approach>.
  Evi: nmap shows 0 open ports across <N> scanned ports
  Rem: N/A because this is a positive finding.
  Com: Verify host operational and verify host operational hardening is intentional.
```

Report every open port in the Network Enumeration section. Create dedicated
findings for high-risk services such as Telnet, FTP, and RDP. Create findings
for expired or invalid SSL certificates. Mark `comply` for properly secured
services, `non-com` for insecure services, and `NA` for untested areas. If a DB
port is found, cross-reference the database attack skill. If an HTTP port is
found, cross-reference web testing. If an SMB port is found, cross-reference SMB
enumeration.

## Limitations And Tuning

SYN scans need root or `cap_net_raw`; TCP Connect loses OS detection. UDP is
inherently unreliable. OS fingerprints can be wrong and should be verified by a
secondary method. NSE false alarms are possible and must be verified before
reporting. Large scans (/16+) should use masscan first, then targeted nmap for
detail.

Run quick scans before escalating. Always use `-oA` so partial results remain
valuable. For multi-target scans, tune `--min-hostgroup` and
`--min-parallelism`. For interrupted scans, resume from the log file when
possible. Timing templates are: T0 paranoid for IDS evasion, T1 sneaky, T2
polite, T3 normal, T4 aggressive on trusted targets, and T5 speed over accuracy.

Relevant references include the Nmap manual, Nmap NSE documentation, MITRE
ATT&CK T1046, and PTES intelligence gathering guidance.

## Verbose Rationale Appendix

This appendix intentionally repeats the same required operational meaning in a
more explanatory style. It is present so the evaluation compares a realistic
verbose authoring style against the compressed shorthand representation. The
appendix does not add a new approach or a new compliance requirement; it expands
why each preserved item matters.

The authorization gate is first because a port scan is an active network action.
A scan may be technically simple, but it still sends traffic to another system.
For that reason, the agent should treat scope and permission as hard
preconditions rather than soft warnings. The short skill can express this as a
compact gate, but the longer baseline spells out the behavioral contract: check
scope, check the allowed scan type, ask when anything is missing, log the block,
and return without probing.

The `tool-setup` dependency is also deliberately explicit. A scanning skill
should not duplicate package installation logic. If `nmap` is already present,
the scanner can proceed after verification. If it is missing, responsibility
moves to the dependency resolver. That resolver owns approval, package-manager
selection, user-local fallback paths, and post-install operations such as
`setcap`. Keeping this dependency in both the verbose baseline and shorthand
skill proves that compression did not hide an important setup handoff.

The SYN Half-Open approach is the primary path because it is the normal `nmap`
strategy for accurate TCP reconnaissance when privileges allow it. The
important facts are the `-sS` scan mode, service detection with `-sV`, OS
detection with `-O`, top-port selection, timing control, output through `-oA`,
and the use of `--osscan-guess` with limited OS retries. The compressed version
does not need a paragraph to describe these ideas, but it must keep every
command flag that changes behavior.

The TCP Connect fallback exists because many operator environments do not have
root privileges or `cap_net_raw`. The important tradeoff is unchanged by
compression: `-sT` works without elevated privileges and still supports service
version detection, but it loses OS detection and creates a fuller connection
pattern. The shorthand version says this in fewer tokens; the baseline explains
why it is the first fallback rather than a last resort.

The fragmented SYN fallback and decoy fallback are intentionally restricted.
They are part of the original technique set, so removing them would change the
skill's personality and coverage. The fix is not to erase them; the fix is to
make authorization explicit. In both versions, fragmented SYN requires explicit
authorization for evasion, and decoy scanning requires explicit authorization
for decoys. This keeps the original capability while making the safety boundary
machine-checkable in the preservation manifest.

The `nc` and `/dev/tcp` fallback is the safe continuity path. It proves the
skill can still produce minimal signal when the preferred scanner is unavailable
or blocked. It is intentionally bounded to top-100 ports because an unbounded
manual TCP loop would be slow and noisy. It also explicitly gives up service and
OS identification. The shorthand phrase "No svc/OS" is shorter, but it has the
same operational consequence as the verbose warning.

The scan type matrix is important because compression can otherwise hide
defaults. A quick scan, standard scan, full scan, stealth scan, UDP scan,
comprehensive scan, and custom scan each encode different port counts, timing,
script choices, OS detection settings, and fallback priorities. The evaluator
checks representative rows such as standard and stealth, and the full skill
keeps the rest of the matrix visible for the agent.

The pre-flight phase is intentionally ordered. Authorization and scope come
before tool setup. Tool setup comes before command construction. Parameter
selection comes before output directory creation. If this order changes, the
agent might install tools for an unauthorized target or build a command before
knowing whether the scan type is allowed. The shorthand version preserves this
order with fewer words and compact state notation.

The parsing and normalization phase matters because raw `nmap` output is not
enough for a multi-skill system. Higher-tier skills need structured state, not
just terminal output. That is why XML parsing, normalized JSON, service lists,
OS guesses, and state variables must survive compression. The output path with
`_normalized.json` is a required fact because other skills may look for it.

The error table also needs preservation because it controls graceful
degradation. `E_HOST_DOWN` maps to `-Pn`. `E_NO_ROOT` maps to `-sT`.
`E_ALL_FILTERED` maps to the authorized evasion fallback path. Those are not
decorative labels; they are decision points. The shorthand version can encode
them as a compact table, but it cannot drop the code, trigger, action, or retry
meaning.

The state variables are part of the skill contract. `s:nmap_avail` tells later
steps whether the scanner exists. `s:scan_cap` tells the executor whether SYN,
connect, or fallback mode is available. `s:t_<ip>_ports` carries open ports to
service enumeration and attack-specific skills. `s:t_<ip>_svc` and
`s:t_<ip>_os` carry service and OS details. These compact state names are a
natural use of shorthand because the same variables may appear many times.

The artifact paths are also part of the contract. The `.nmap`, `.xml`, `.gnmap`,
and normalized JSON files let an engagement preserve evidence, rerun parsing,
and support reporting. A shorter file can still preserve those paths exactly.
That is why code blocks and command templates are not aggressively rewritten by
the compression rules.

The finding patterns show how raw scan output becomes reportable evidence.
Open ports, filtered states, service versions, OS fingerprints, NSE vulnerable
results, expired SSL certificates, anonymous FTP, and SMB signing disabled all
have different severities and confidence levels. The baseline is verbose so a
human can understand the logic; the shorthand version is concise so an agent can
carry the same logic with less context cost.

The compliance section is a preservation hotspot. A compressed skill must not
quietly remove OWASP, ASVS, NIST, MITRE, PTES, CIS, or OSSTMM mappings. These
mappings are not just explanatory prose; they control report structure and
finding classification. The manifest therefore checks several representative
controls and relies on the full skill to keep the complete list.

The finding templates are another preservation hotspot. A report template is
allowed to use shorthand labels such as `F`, `Cls`, `Sev`, `Ref`, `Desc`, `Evi`,
`Rem`, and `Com`, but the required fields must remain present. The open service
template, insecure protocol template, and no-open-ports template represent three
different classes: non-compliant baseline exposure, high-severity cleartext
exposure, and compliant hardening evidence.

The limitations section protects against overclaiming scan results. SYN may not
be available. UDP is unreliable. OS fingerprints can be wrong. NSE can produce
false positives. Large ranges need a different discovery tool before targeted
detail. The shorthand file keeps those limitations because "shorter" should not
mean "more confident than the evidence allows."

The reason this evaluation can report 0% data loss is specific. It means zero
required facts from the manifest are present in the verbose baseline and absent
from the shorthand skill. It does not mean the files use identical words, lines,
or byte sequences. The whole point of shorthand is that two representations can
carry the same operational data while using different language. The manifest is
the contract that says which facts must remain identical in meaning.

Future evaluations can add more manifests. A web-testing skill could define
required facts for request handling, authentication boundaries, artifacts, and
findings. A tool-installation skill could define required facts for approval,
fallbacks, logs, and version checks. The structure is reusable: write a verbose
baseline, write a shorthand skill, list required facts, and run the evaluator.
