# VERA steering files

Repo-specific context that kiro loads into a session. These mirror the Claude Code skills in
`.claude/skills/` — same content, kiro's inclusion model instead of skill descriptions. When you
change one, change its twin so the two assistants don't drift apart.

| File | Inclusion | Loads when |
|---|---|---|
| `vera-feature-flags.md` | `fileMatch` — `VERA/Config/**` | Editing `app-config.json`; pull in manually with `#vera-feature-flags` when touching `Project.swift`, `generate-app-config.py`, or `TestSchemes.swift` |
| `vera-testing.md` | `fileMatch` — `**/*Tests/**` | Any test file is in context |
| `vera-snapshot-tests.md` | `fileMatch` — `**/*SnapshotTests/**` | Snapshot tests specifically — the re-record procedure |
| `vera-new-module.md` | `manual` | `#vera-new-module` |
| `vera-setup.md` | `manual` | `#vera-setup` |

No file uses `inclusion: always`, so none of them costs context on unrelated work.

## Note on the docs

`docs/CONFIGURATION.md`, `.github/copilot-instructions.md`, and `VERA/CONFIGURATION_README.md`
still document `CHAT_ENABLED`, `CAPTIONS_ENABLED`, `REACTIONS_ENABLED`, and
`SCREEN_SHARE_ENABLED` as live compilation conditions. They were removed in the
`VERAMeetingRoomSDK` refactor — those features are now gated at runtime through
`MeetingRoomFeature`. `vera-feature-flags.md` documents the current behaviour and says to trust
the code over those tables. Verify the live set any time with:

```bash
grep -o '"[A-Z_]*_ENABLED"' VERA/Project.swift | sort -u
```
