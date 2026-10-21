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
| Xcode 26 | iOS 17.0+ deployment target |
| Homebrew | `builder.sh` can install the rest for you |
| Python 3 | Runs the code-generation scripts |
| Tuist | Generates the Xcode workspace |
| Git LFS | `git lfs pull` after cloning |

`./Scripts/builder.sh` (setup mode) checks for these and offers to install Homebrew, Python 3 and Tuist if missing.

## The two modes of `builder.sh`

### `./Scripts/builder.sh` — full setup (default)

Use this the first time, after extracting the Starter Kit ZIP. It runs, in phases:

1. **Check prerequisites** — Xcode, Homebrew, Python 3, Tuist.
2. **Validate configuration** — `Config/app-config.json` and `Config/theme.json` must exist. If an `app-config.json`/`theme.json` is present at the repository root, it is moved into `Config/` (overriding the default) first.
3. **Resolve base URL & environment constants** — reads a **valid** `baseApiUrl` from `app-config.json` (required; the build errors out if it is missing or not a valid `http`/`https` URL) and injects it into `EnvironmentConstants.swift`.
4. **Generate code from config and theme** (preceded by a [save reminder](#before-codegen-save-your-config-edits)):
   - `generate-app-config.py` → `VERAConfiguration/VERAConfiguration/AppConfig.swift`
   - `generateEnvironmentConstants.sh` → `VERAApp/VERA/App/Generated/EnvironmentConstants.swift`
   - `generate-app-theme.py` → `VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets` (+ `BorderRadius.swift`, `TypographyStyle.swift`)
5. **Configure code signing** — if `Config/Signing.xcconfig` is missing it is created via `regenerateSigningConfig.sh`, prompting for your Apple **Development Team** (blank is allowed; see [Code signing](#code-signing)). `tuist generate` requires this file to exist.
6. **Generate workspace** — `tuist install` (fetches Tuist-managed SPM dependencies) then `tuist generate`.
7. **Generate SPM asset accessors** — `generate-spm-assets.py` → `VERACommonUI/VERACommonUI/Generated/SPMAssets+VERACommonUI.swift`, derived from the Tuist-generated `Derived/Sources/TuistAssets+VERACommonUI.swift` (must run after `tuist generate`). Keeps the SPM build in sync with the asset catalog.

Then it **launches the app** (optionally [builds and runs](#launching-the-app) on a simulator or connected device), prints the completion banner, and finally asks whether to **open Xcode**.

### `./Scripts/builder.sh --update` — fast path

Use this after editing `Config/app-config.json` or `Config/theme.json`. It:

1. Validates `app-config.json` (applying any root-level override first).
2. Shows a [save reminder](#before-codegen-save-your-config-edits), then regenerates the JSON-driven files (`AppConfig.swift` + theme assets). Also resolves the base URL from `app-config.json` and regenerates `EnvironmentConstants.swift`, so URL changes are picked up too.
3. **Configure code signing** — creates `Config/Signing.xcconfig` if missing (see [Code signing](#code-signing)).
4. Runs `tuist install` then `tuist generate --no-open`.
5. Regenerates `SPMAssets+VERACommonUI.swift` from the Tuist assets.

Then it [launches the app](#launching-the-app), prints the completion banner, and finally asks whether to open Xcode.

It **skips** only the prerequisite checks (those matter just for first-time setup).

## Before codegen: save your config edits

Code generation reads `Config/app-config.json` and `Config/theme.json` **from disk**. Edits still unsaved in your editor are invisible to the script and won't be picked up, and that can't be detected from a shell. So right before generating, `builder.sh` prints a reminder to save. When run interactively it pauses with a short countdown (press Enter to continue, Ctrl-C to abort); in non-interactive runs (CI / piped) it just prints the reminder and continues.

## Launching the app

Once the workspace is generated, `builder.sh` offers to build and run the app — only when running interactively. You pick, via arrow-key menus:

- **Simulator** — lists booted/available simulators (selected directly if there's only one). No signing/team required.
- **Physical device** — lists connected devices; the menu label notes it requires Xcode sign-in and a valid Development Team. If no team is configured, it prompts for one; if you still skip it, it offers to run on the Simulator instead.
- **Don't launch** — skip.

During the build a spinner shows progress, and any already-running instance of the app is terminated before the new build is installed and relaunched. If a device build fails (usually signing), it prints guidance and continues — you can open Xcode from the prompt at the end. On a non-TTY run the launch step is skipped entirely.

## Code signing

`Config/Signing.xcconfig` holds `DEVELOPMENT_TEAM`, `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`. It is **not** committed (git-ignored) and is generated by `regenerateSigningConfig.sh`. `builder.sh` ensures it exists (the **Configure code signing** phase) and prompts for the Development Team when it's missing.

**Where to find your Team ID:** sign in at [developer.apple.com/account](https://developer.apple.com/account) → **Membership details** → **Team ID** (a 10-character string like `A1B2C3D4E5`). In Xcode it's the value behind *Signing & Capabilities → Team*. This is your **Apple Developer** team, not your Vonage account.

Set the team persistently — editing it in Xcode's *Signing & Capabilities* writes it into the generated project, which is overwritten on every `tuist generate`. Options:

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID
./Scripts/regenerateSigningConfig.sh      # → Config/Signing.xcconfig
```

or just answer the `builder.sh` prompt (it persists the value for you).

To **install on a physical device** you also need to be signed in to that team in **Xcode → Settings → Accounts**, so Xcode can download the development provisioning profiles automatically (Debug uses automatic signing + `-allowProvisioningUpdates`). The Simulator needs neither a team nor sign-in.

## Important: `tuist generate` alone does NOT regenerate code

Code generation is owned by `builder.sh`, **not** by `Project.swift`. A plain `tuist generate` only rebuilds the workspace from the already-generated files; it will not pick up changes made to `Config/app-config.json` or `Config/theme.json`.

**After editing either JSON, always run `./Scripts/builder.sh --update`.**

## What each file drives

| Source (edit this) | Generated (do not edit) | Effect |
|---|---|---|
| `Config/app-config.json` | `VERAConfiguration/.../AppConfig.swift` | Enables/disables features |
| `Config/app-config.json` (`baseApiUrl`) | `VERAApp/.../EnvironmentConstants.swift` | Sets the required API base URL (single source of truth) |
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
| SPM build fails on a missing asset (e.g. `SemanticColors.accent`) | `SPMAssets+VERACommonUI.swift` drifted from the catalog. Run `tuist generate` then `python3 Scripts/generate-spm-assets.py` (or `./Scripts/builder.sh --update`). Do not edit the file by hand. |
| Signing / entitlements issues | Confirm `DEVELOPMENT_TEAM` is set in `Config/Signing.xcconfig` and that you're signed in to that team in Xcode → Settings → Accounts (see [Code signing](#code-signing)) |

Never edit `.xcodeproj`/`.xcworkspace` (generated, not committed) or files marked `DO NOT EDIT MANUALLY`.
