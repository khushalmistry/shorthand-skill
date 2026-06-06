#!/usr/bin/env python3
"""Evaluate shorthand skill compression and preservation.

The evaluator is intentionally dependency-free. It checks:
- Skill folder/frontmatter structure.
- Compression metrics for each manifest case.
- Required fact preservation from verbose baseline to shorthand skill.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def count_words(text: str) -> int:
    return len(re.findall(r"\S+", text))


def metrics(text: str) -> dict[str, int]:
    return {
        "words": count_words(text),
        "bytes": len(text.encode("utf-8")),
        "lines": len(text.splitlines()),
    }


def compression(saved_from: int, shorthand: int) -> float:
    if saved_from == 0:
        return 0.0
    return (1 - (shorthand / saved_from)) * 100


def frontmatter(text: str) -> str | None:
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end == -1:
        return None
    return text[4:end]


def frontmatter_value(fm: str, key: str) -> str | None:
    match = re.search(rf"^{re.escape(key)}\s*:\s*(.+?)\s*$", fm, re.MULTILINE)
    if not match:
        return None
    return match.group(1).strip().strip('"').strip("'")


def validate_skills() -> dict[str, object]:
    skills_dir = ROOT / "skills"
    failures: list[str] = []
    warnings: list[str] = []
    skill_paths = sorted(
        path for path in skills_dir.iterdir()
        if path.is_dir() and (path / "SKILL.md").exists()
    )

    for skill_path in skill_paths:
        skill_md = skill_path / "SKILL.md"
        text = read_text(skill_md)
        fm = frontmatter(text)
        label = skill_path.name
        if fm is None:
            failures.append(f"{label}: missing YAML frontmatter")
            continue

        name = frontmatter_value(fm, "name")
        description = frontmatter_value(fm, "description")
        license_name = frontmatter_value(fm, "license")

        if not name:
            failures.append(f"{label}: missing required field name")
        elif name != label:
            failures.append(f"{label}: name field must match directory name")
        elif not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
            failures.append(f"{label}: invalid skill name {name!r}")

        if not description:
            failures.append(f"{label}: missing required field description")

        if not license_name:
            warnings.append(f"{label}: missing recommended field license")

    return {
        "skill_count": len(skill_paths),
        "failures": failures,
        "warnings": warnings,
        "passed": not failures,
    }


def contains_all(text: str, snippets: list[str]) -> bool:
    haystack = text.lower()
    return all(snippet.lower() in haystack for snippet in snippets)


def evaluate_case(manifest_path: Path) -> dict[str, object]:
    manifest = json.loads(read_text(manifest_path))
    verbose_path = ROOT / manifest["verbose"]
    shorthand_path = ROOT / manifest["shorthand"]
    verbose = read_text(verbose_path)
    shorthand = read_text(shorthand_path)
    verbose_metrics = metrics(verbose)
    shorthand_metrics = metrics(shorthand)

    lost: list[str] = []
    fixture_missing: list[str] = []
    facts = manifest["required_facts"]
    for fact in facts:
        snippets = fact["must_contain"]
        in_verbose = contains_all(verbose, snippets)
        in_shorthand = contains_all(shorthand, snippets)
        if not in_verbose:
            fixture_missing.append(fact["id"])
        elif not in_shorthand:
            lost.append(fact["id"])

    return {
        "name": manifest["name"],
        "verbose": str(verbose_path.relative_to(ROOT)),
        "shorthand": str(shorthand_path.relative_to(ROOT)),
        "required_facts": len(facts),
        "lost_facts": lost,
        "fixture_missing": fixture_missing,
        "data_loss_percent": 0.0 if not lost and not fixture_missing else round((len(lost) / len(facts)) * 100, 2),
        "verbose_metrics": verbose_metrics,
        "shorthand_metrics": shorthand_metrics,
        "compression": {
            "words": round(compression(verbose_metrics["words"], shorthand_metrics["words"]), 2),
            "bytes": round(compression(verbose_metrics["bytes"], shorthand_metrics["bytes"]), 2),
            "lines": round(compression(verbose_metrics["lines"], shorthand_metrics["lines"]), 2),
        },
    }


def run_evaluation() -> dict[str, object]:
    manifests = sorted((ROOT / "evals" / "manifests").glob("*.json"))
    cases = [evaluate_case(path) for path in manifests]
    skill_validation = validate_skills()
    passed = skill_validation["passed"] and all(
        not case["lost_facts"] and not case["fixture_missing"]
        for case in cases
    )
    return {
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "passed": passed,
        "skill_validation": skill_validation,
        "cases": cases,
    }


def render_markdown(result: dict[str, object]) -> str:
    lines: list[str] = []
    lines.append("# Shorthand Evaluation Results")
    lines.append("")
    lines.append(f"Generated: `{result['generated_at_utc']}`")
    lines.append(f"Status: `{'PASS' if result['passed'] else 'FAIL'}`")
    lines.append("")

    skill_validation = result["skill_validation"]
    lines.append("## Skill Validation")
    lines.append("")
    lines.append(f"- Skills checked: `{skill_validation['skill_count']}`")
    lines.append(f"- Failures: `{len(skill_validation['failures'])}`")
    lines.append(f"- Warnings: `{len(skill_validation['warnings'])}`")
    if skill_validation["failures"]:
        lines.extend(f"- {failure}" for failure in skill_validation["failures"])
    if skill_validation["warnings"]:
        lines.extend(f"- {warning}" for warning in skill_validation["warnings"])
    lines.append("")

    lines.append("## Preservation Cases")
    lines.append("")
    lines.append("| Case | Required facts | Lost facts | Data loss | Word saved | Byte saved | Line saved |")
    lines.append("|---|---:|---:|---:|---:|---:|---:|")
    for case in result["cases"]:
        lines.append(
            "| {name} | {facts} | {lost} | {loss:.2f}% | {word:.2f}% | {byte:.2f}% | {line:.2f}% |".format(
                name=case["name"],
                facts=case["required_facts"],
                lost=len(case["lost_facts"]),
                loss=case["data_loss_percent"],
                word=case["compression"]["words"],
                byte=case["compression"]["bytes"],
                line=case["compression"]["lines"],
            )
        )
    lines.append("")

    for case in result["cases"]:
        lines.append(f"### {case['name']}")
        lines.append("")
        lines.append(f"- Verbose baseline: `{case['verbose']}`")
        lines.append(f"- Shorthand skill: `{case['shorthand']}`")
        lines.append(f"- Verbose metrics: `{case['verbose_metrics']}`")
        lines.append(f"- Shorthand metrics: `{case['shorthand_metrics']}`")
        if case["lost_facts"]:
            lines.append(f"- Lost facts: `{', '.join(case['lost_facts'])}`")
        if case["fixture_missing"]:
            lines.append(f"- Fixture missing facts: `{', '.join(case['fixture_missing'])}`")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate shorthand-skill preservation and compression.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--write", type=Path, help="Write rendered output to a file.")
    args = parser.parse_args()

    result = run_evaluation()
    output = json.dumps(result, indent=2) if args.format == "json" else render_markdown(result)

    if args.write:
        out_path = args.write if args.write.is_absolute() else ROOT / args.write
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output + "\n", encoding="utf-8")
    print(output)
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
