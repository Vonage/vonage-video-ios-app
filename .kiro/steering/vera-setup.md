---
inclusion: manual
---

# VERA Environment Setup & Doctor

Reference with `#vera-setup` for first-time setup, onboarding, or when the workspace won't
generate or build.

Run checks first, report what's wrong, then fix — don't blindly re-run everything on a machine
that is already mostly set up.

All generation commands run **from `VERA/`**, not the repo root. The scripts use hardcoded
relative paths and fail (or write to the wrong place) from anywhere else.

## Step 1: Diagnose

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
# Generated artifacts — all four must exist before `tuist generate` succeeds
ls VERA/VERAApp/VERA/App/Generated/EnvironmentConstants.swift \
   VERA/Config/Signing.xcconfig \
   VERA/VERAConfiguration/VERAConfiguration/AppConfig.swift 2>&1
ls -d VERA/VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets 2>&1
```

```bash
# The #1 silent failure: regenerateSigningConfig.sh does NOT validate DEVELOPMENT_TEAM and
# happily writes "DEVELOPMENT_TEAM = " (blank). Always inspect the contents.
cat VERA/Config/Signing.xcconfig 2>/dev/null
```

```bash
# LFS: .lfsconfig sets skipSmudge = true, so snapshot references are pointer files until pulled
head -c 200 "$(find VERA -path '*__Snapshots__*' -name '*.png' | head -1)"
```

If that last one prints `version https://git-lfs...`, LFS content was never pulled and every
snapshot test will fail with bogus diffs — run `git lfs pull`.

## Step 2: Prerequisites

```bash
brew install swiftlint swift-format git-lfs
brew install --formula tuist
```

Java 17 is only needed for Maestro E2E tests (`scripts/install-maestro.sh` handles it) — skip it
for a basic setup.

## Step 3: Environment variables

| Var | Meaning | Notes |
|---|---|---|
| `BASE_API_URL` | Backend base URL from a running [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app) backend | **Mandatory** — `generateEnvironmentConstants.sh` exits 1 without it. Also derives the `applinks:` associated domain. |
| `DEVELOPMENT_TEAM` | Apple Developer team ID | **Not validated** — a missing value silently produces a blank team. |
| `MARKETING_VERSION` | CFBundleShortVersionString | Defaults to 1.3 if unset. |
| `CURRENT_PROJECT_VERSION` | CFBundleVersion (build number) | Defaults to 1 if unset. |

For a persistent local setup, copy `VERA/Scripts/setUpInfoPlist.example.sh` to
`VERA/Scripts/setUpInfoPlist.sh` (gitignored), fill it in, and `source` it before regenerating.
The template only carries `DEVELOPMENT_TEAM` and `CURRENT_PROJECT_VERSION`; `BASE_API_URL` still
has to be exported separately.

## Step 4: Generate

Order among the four scripts doesn't matter, but **all four must complete before
`tuist generate`** — `VERA/Project.swift` reads `Config/app-config.json` at manifest-evaluation
time and `fatalError`s if it is missing, and both the app and screen-share plugin projects
reference `Config/Signing.xcconfig` as an xcconfig.

```bash
cd VERA
./Scripts/generateEnvironmentConstants.sh
./Scripts/regenerateSigningConfig.sh
python3 ./Scripts/generate-app-config.py
python3 ./Scripts/generate-app-theme.py
tuist generate
```

Then re-check that `VERA/Config/Signing.xcconfig` actually contains a team ID.

## Common failures

- **Stale workspace after `Project.swift` changes** — `tuist clean && tuist generate`. If still
  broken, use CI's form: `tuist clean; rm -rf ~/.cache/tuist; tuist generate`.
- **`Could not read app-config.json` fatalError** — `generate-app-config.py` reads
  `./Config/app-config.json` relative to CWD; it was likely run from the wrong directory, or the
  JSON has a syntax error. A missing *key* raises a raw Python `KeyError`, meaning someone edited
  the config structure — compare against git.
- **Signing errors on the app target despite a correct `Signing.xcconfig`** —
  `VERA/VERAApp/Project.swift` hardcodes a `DEVELOPMENT_TEAM` in its base settings and does not
  read the xcconfig; a personal-team user may need to override it there (don't commit that).
- **All snapshot tests fail with garbage diffs** — LFS pointers, see Step 1.
- **`print()` lint errors** — expected; `print` is banned by a SwiftLint custom rule, use a logger.

## Cautions

- `VERA/Config/Signing.xcconfig` is untracked but **not gitignored** — never commit it, it
  carries a team ID.
- `generateEnvironmentConstants.sh` also rewrites `VERAApp/VERA/VERA.entitlements` (applinks
  domain, app group) — that file is generated, don't hand-edit it.
- CI skips both Python scripts because `AppConfig.swift` and `SemanticColors.xcassets` are
  committed. If `Config/app-config.json` or `Theme/semantics.json` changed, the regenerated
  outputs must be committed.
