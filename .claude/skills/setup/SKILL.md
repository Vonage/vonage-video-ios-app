---
name: setup
description: First-time environment setup and environment doctor for this repo. Use whenever the user wants to set up the project, bootstrap their machine, can't build or generate the workspace, hits tuist/signing/env-var errors, asks "why won't this build", or mentions onboarding a new developer. Also use to verify an environment before a release or after an Xcode/tuist upgrade.
---

# VERA Environment Setup & Doctor

Set up (or diagnose) a local development environment for this repo. Run checks first, report what's wrong, then fix — don't blindly re-run everything on a machine that's already mostly set up.

All generation commands run **from `VERA/`**, not the repo root. The scripts use hardcoded relative paths and fail (or worse, write to the wrong place) from anywhere else.

## Step 1: Diagnose

Check each of these and collect the results before fixing anything:

```bash
# Tools (docs pin nothing — "latest" is the policy; Xcode 26 is required)
xcodebuild -version
tuist version
swiftlint version
swift-format --version
git lfs version
python3 --version   # stdlib only; any python3 works
```

```bash
# Generated artifacts — all four must exist before `tuist generate` will succeed
ls VERA/VERAApp/VERA/App/Generated/EnvironmentConstants.swift \
   VERA/Config/Signing.xcconfig \
   VERA/VERAConfiguration/VERAConfiguration/AppConfig.swift 2>&1
ls -d VERA/VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets 2>&1
```

```bash
# The #1 silent failure: regenerateSigningConfig.sh does NOT validate DEVELOPMENT_TEAM
# and happily writes "DEVELOPMENT_TEAM = " (blank). Always inspect the file contents.
cat VERA/Config/Signing.xcconfig 2>/dev/null
```

```bash
# LFS: .lfsconfig sets skipSmudge = true, so snapshot reference images are
# pointer files until `git lfs pull` runs. Check one:
head -c 200 "$(find VERA -path '*__Snapshots__*' -name '*.png' | head -1)"
```
If that prints `version https://git-lfs...`, LFS content was never pulled — snapshot tests will all fail with bogus diffs.

## Step 2: Prerequisites (install what's missing)

```bash
brew install swiftlint swift-format git-lfs
brew install --formula tuist
```

Java 17 is only needed for Maestro E2E tests — `scripts/install-maestro.sh` handles that; don't install it for a basic setup.

## Step 3: Environment variables

Four env vars drive code generation:

| Var | Meaning | Notes |
|---|---|---|
| `BASE_API_URL` | Backend base URL (from a running [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app) backend) | **Mandatory** — `generateEnvironmentConstants.sh` exits 1 without it. Also derives the `applinks:` associated domain in the entitlements. |
| `DEVELOPMENT_TEAM` | Apple Developer team ID | **Not validated** — missing value silently produces a blank team in Signing.xcconfig. |
| `MARKETING_VERSION` | CFBundleShortVersionString | Defaults to 1.3 if unset. |
| `CURRENT_PROJECT_VERSION` | CFBundleVersion (build number) | Defaults to 1 if unset. |

For a persistent local setup, point the user at the gitignored personal script: copy `VERA/Scripts/setUpInfoPlist.example.sh` to `VERA/Scripts/setUpInfoPlist.sh`, fill it in, and `source` it before regenerating. Note the example template only contains `DEVELOPMENT_TEAM` and `CURRENT_PROJECT_VERSION` — `BASE_API_URL` still has to be exported separately.

## Step 4: Generate

Order among the four scripts doesn't matter, but **all four must complete before `tuist generate`** — `VERA/Project.swift` reads `Config/app-config.json` at manifest-evaluation time and `fatalError`s if it's missing, and both the app and screen-share plugin projects reference `Config/Signing.xcconfig` as an xcconfig.

```bash
cd VERA
./Scripts/generateEnvironmentConstants.sh
./Scripts/regenerateSigningConfig.sh
python3 ./Scripts/generate-app-config.py
python3 ./Scripts/generate-app-theme.py
tuist generate
```

`git lfs pull` from the repo root if the LFS check in Step 1 failed.

After generating, re-check `VERA/Config/Signing.xcconfig` actually contains a team ID (Step 1's silent-failure check).

## Common failures

- **Stale/weird workspace after Project.swift changes** — `tuist clean && tuist generate`. If still broken, use CI's nuclear form: `tuist clean; rm -rf ~/.cache/tuist; tuist generate`.
- **`Could not read app-config.json` fatalError from tuist** — `generate-app-config.py` reads `./Config/app-config.json` relative to CWD; it was probably run from the wrong directory, or the file has a JSON syntax error (the script exits 1 on parse errors, but a missing *key* raises a raw Python `KeyError` traceback — that means someone edited the config structure, compare against git).
- **Signing errors on the VERA app target despite a correct Signing.xcconfig** — `VERA/VERAApp/Project.swift` hardcodes a `DEVELOPMENT_TEAM` in its base settings and does not read `Config/Signing.xcconfig`; a personal-team user may need to override it there (don't commit that change).
- **All snapshot tests fail with garbage diffs** — LFS pointers, see Step 1.
- **`print()` lint errors on first build** — expected; `print` is banned by a SwiftLint custom rule, use a logger.

## Cautions

- `VERA/Config/Signing.xcconfig` is untracked but **not gitignored** — warn the user never to commit it (it carries their team ID). Same for any local edit hardcoding a team.
- `generateEnvironmentConstants.sh` also rewrites `VERAApp/VERA/VERA.entitlements` (applinks domain, app group) — that file is generated, don't hand-edit it.
- CI (`.github/workflows/ci.yml`) skips both Python scripts because `AppConfig.swift` and `SemanticColors.xcassets` are committed. If the user changed `Config/app-config.json` or `Theme/semantics.json`, the regenerated outputs must be committed.
