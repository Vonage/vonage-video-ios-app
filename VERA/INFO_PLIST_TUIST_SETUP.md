# Info.plist Setup

Before running `tuist generate`, you must provide the Apple Development Team ID so code signing settings can be injected automatically.

## 1. Local Setup

Create the script `Scripts/setUpInfoPlist.sh` (do **not** commit your real team ID if you prefer keeping it private):

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID      # Replace with your real team ID
export CURRENT_PROJECT_VERSION=1          # Numeric build number
export MARKETING_VERSION=1.0              # Human-readable version (semantic)
```

(Template example: `Scripts/setUpInfoPlist.sh.example`)

Then run:

```bash
source Scripts/setUpInfoPlist.sh
bash Scripts/regenerateSigningConfig.sh
```

This generates `Config/Signing.xcconfig` containing:

```text
DEVELOPMENT_TEAM = <your team id>
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
```

`Project.swift` reads this xcconfig during manifest evaluation so `DEVELOPMENT_TEAM`, `MARKETING_VERSION`, and `CURRENT_PROJECT_VERSION` propagate to the necessary targets.

To update `MARKETING_VERSION` or `CURRENT_PROJECT_VERSION`, change the values in `setUpInfoPlist.sh` and re-run the script.

## 2. Regenerating the Project

After generating the signing config:

```bash
tuist generate
```

If you change the team ID later, re-run the setup and regenerate.

## 3. CI Configuration

In CI (e.g. GitHub Actions), define environment variables (`DEVELOPMENT_TEAM`, optionally `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) and run the same flow before `tuist generate`:

```yaml
- name: Set up signing config
  run: |
    export DEVELOPMENT_TEAM=${{ vars.DEVELOPMENT_TEAM }}
    export CURRENT_PROJECT_VERSION=${{ github.run_number }}
    ./Scripts/regenerateSigningConfig.sh

- name: Generate project
  run: tuist generate --no-open
```