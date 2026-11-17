# VERA steering files

Repo-specific context that kiro loads into a session.

**These files are symlinks.** Each one points at its twin under `.claude/skills/`, so kiro and
Claude Code read the *same* file — there is only ever one copy to edit, and the two assistants
cannot drift apart.

| Steering file (symlink) | Real file | Inclusion | Loads when |
|---|---|---|---|
| `vera-feature-flags.md` | `.claude/skills/feature-flag/SKILL.md` | `fileMatch` — `VERA/Config/**` | Editing `app-config.json`; pull in with `#vera-feature-flags` for `Project.swift`, `generate-app-config.py`, or `TestSchemes.swift` |
| `vera-testing.md` | `.claude/skills/run-tests/SKILL.md` | `fileMatch` — `**/*Tests/**` | Any test file is in context |
| `vera-snapshot-tests.md` | `.claude/skills/record-snapshots/SKILL.md` | `fileMatch` — `**/*SnapshotTests/**` | Snapshot tests — the re-record procedure |
| `vera-new-module.md` | `.claude/skills/new-module/SKILL.md` | `manual` | `#vera-new-module` |
| `vera-setup.md` | `.claude/skills/setup/SKILL.md` | `manual` | `#vera-setup` |

## How the shared front-matter works

Each file carries the keys both tools need. Every key is documented by at least one of them, and
each tool reads only its own and ignores the rest:

```yaml
---
name: feature-flag                      # Claude Code (also a valid kiro field)
description: …                          # Claude Code trigger (also a valid kiro field)
inclusion: fileMatch                    # kiro trigger
fileMatchPattern: 'VERA/Config/**'      # kiro trigger
---
```

## Editing

Edit the real file under `.claude/skills/`, or edit through the symlink — same thing. Because both
assistants read the file, keep cross-references tool-neutral, naming both invocations
(`/feature-flag` in Claude Code, `#vera-feature-flags` in kiro).

Two things to know:

- **Adding a new pair:** create `.claude/skills/<name>/SKILL.md` with all four front-matter keys,
  then `ln -s ../../.claude/skills/<name>/SKILL.md .kiro/steering/vera-<name>.md`.
- **Packaging:** `inclusion` and `fileMatchPattern` are not in the Agent Skills spec, so uploading
  these to claude.ai or the Skills API would fail on the unexpected keys. Strip them first
  (`yq 'del(.inclusion, .fileMatchPattern)'`). This does not affect local use in either tool.
