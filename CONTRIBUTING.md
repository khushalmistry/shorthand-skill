# Contributing to shorthand-skill

Thanks for considering a contribution! This project compresses AI agent skill definitions using shorthand notation inspired by court stenography.

## Quick Orientation

| I want to change... | Edit this file |
|---|---|
| Shorthand behavior (symbols, rules, intensity) | `skills/shorthand/SKILL.md` |
| Shorthand dictionary (symbols, abbreviations) | `skills/shorthand-dict/SKILL.md` |
| Commit message format | `skills/shorthand-commit/SKILL.md` |
| Compression logic | `skills/shorthand-compress/SKILL.md` |
| Example skill definitions | `skills/<name>/SKILL.md` |
| Evaluation manifests / fixtures | `evals/` |
| Installer | `install.sh` |
| README / docs | `README.md`, `docs/` |

## Shorthand Writing Rules

When writing or editing shorthand skills:

1. **Zero evaluated data loss** — Every required approach, finding, command, and compliance mapping must be preserved
2. **Dictionary reference** — All symbols must be defined in `skills/shorthand/references/DICTIONARY.md` and `skills/shorthand-dict/SKILL.md`
3. **At least 2 approaches** — Every skill needs `⚡` (primary) + at least `↩A` (fallback)
4. **Compliance mappings** — Every skill producing findings MUST map to OWASP + at least one other standard
5. **No hardcoded values** — Everything parameterized
6. **Test before PR** — Run `python3 evals/evaluate.py` and `gh skill publish --dry-run .`

## Adding a New Example Skill

1. Create `skills/<name>/SKILL.md`
2. Use shorthand notation throughout (⚡, ↩, ⊕, §, etc.)
3. Include YAML frontmatter with `name`, `description`, and `license`
4. All 9 sections: §2 tri through §9 xtra
5. Add an eval manifest when making a preservation claim
6. Add to README.md "What You Get" when it should be advertised
7. Test with your agent

## PR Process

1. Fork → Branch → Commit → Push → PR
2. Use shorthand-commit format for commit messages
3. One skill per PR keeps review manageable
4. Verify: `python3 evals/evaluate.py` — required facts should show 0 lost facts

## License

MIT — same as the project.
