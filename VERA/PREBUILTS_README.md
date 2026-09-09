# Building the Starter Kit (Prebuilts)

This guide explains how to build the app from the Starter Kit / Prebuilts distribution. The whole flow is driven by a single script — **`Scripts/builder.sh`** — which runs code generation and generates the Xcode workspace.

> All commands are run from the `VERA/` directory unless noted otherwise.

## TL;DR

```bash
cd VERA

# First-time setup (prerequisites, full code generation, workspace, opens Xcode)
./Scripts/builder.sh

# After editing Config/app-config.json or Config/theme.json
./Scripts/builder.sh --update
```

## Prerequisites

| Tool | Notes |
|---|---|
| Xcode 26 | iOS 16.0+ deployment target |
| Homebrew | `builder.sh` can install the rest for you |
| Python 3 | Runs the code-generation scripts |
| Tuist | Generates the Xcode workspace |
| Git LFS | `git lfs pull` after cloning |

`./Scripts/builder.sh` (setup mode) checks for these and offers to install Homebrew, Python 3 and Tuist if missing.

## The two modes of `builder.sh`

### `./Scripts/builder.sh` — full setup (default)

Use this the first time, after extracting the Starter Kit ZIP. It runs, in phases:

1. **Check prerequisites** — Xcode, Homebrew, Python 3, Tuist.
2. **Validate configuration** — `Config/app-config.json` and `Config/theme.json` must exist.
3. **Resolve `BASE_API_URL`** — from `baseApiUrl` in `app-config.json`, or the `BASE_API_URL` env var.
4. **Generate code from config and theme**:
   - `generate-app-config.py` → `VERAConfiguration/VERAConfiguration/AppConfig.swift`
   - `generateEnvironmentConstants.sh` → `VERAApp/VERA/App/Generated/EnvironmentConstants.swift`
   - `generate-app-theme.py` → `VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets` (+ `BorderRadius.swift`, `TypographyStyle.swift`)
5. **Generate workspace** — `tuist generate`.
6. **Open Xcode** automatically.

### `./Scripts/builder.sh --update` — fast path

Use this after editing `Config/app-config.json` or `Config/theme.json`. It:

1. Validates `app-config.json`.
2. Regenerates the JSON-driven files (`AppConfig.swift` + theme assets).
3. Runs `tuist generate --no-open`.
4. Asks whether to open Xcode.

It **skips** prerequisite checks, `BASE_API_URL` resolution and `EnvironmentConstants.swift` (those only matter for first-time setup).

## Important: `tuist generate` alone does NOT regenerate code

Code generation is owned by `builder.sh`, **not** by `Project.swift`. A plain `tuist generate` only rebuilds the workspace from the already-generated files; it will not pick up changes made to `Config/app-config.json` or `Config/theme.json`.

**After editing either JSON, always run `./Scripts/builder.sh --update`.**

## What each file drives

| Source (edit this) | Generated (do not edit) | Effect |
|---|---|---|
| `Config/app-config.json` | `VERAConfiguration/.../AppConfig.swift` | Enables/disables features and sets `baseApiUrl` |
| `Config/theme.json` | `SemanticColors.xcassets`, `BorderRadius.swift`, `TypographyStyle.swift` | Design tokens (colors, typography, radii) |

See [`CONFIGURATION_README.md`](CONFIGURATION_README.md) for the full feature-flag reference and how features are wired at runtime vs. compile time.

## Working with Xcode already open

`tuist generate` rewrites the `.xcodeproj`/`.xcworkspace`. If Xcode is open when you run `--update`:

- Let Xcode reload the project if it prompts.
- **Build** again to pick up the regenerated `AppConfig.swift` / theme assets.
- If a toggled feature doesn't seem to take effect, do **Product → Clean Build Folder** and rebuild.

## Troubleshooting

| Problem | Fix |
|---|---|
| Changes to `app-config.json` not reflected | Run `./Scripts/builder.sh --update` (a plain `tuist generate` won't regenerate) |
| Stale workspace | `tuist clean` then `./Scripts/builder.sh --update` |
| `builder.sh` fails on codegen | Run the failing script directly to see the error, e.g. `python3 Scripts/generate-app-config.py` |
| Signing / entitlements issues | Confirm `DEVELOPMENT_TEAM` is set and `Config/Signing.xcconfig` was generated |

Never edit `.xcodeproj`/`.xcworkspace` (generated, not committed) or files marked `DO NOT EDIT MANUALLY`.
