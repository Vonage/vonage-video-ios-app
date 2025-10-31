# Development Team Setup

Before running `tuist generate`, you must provide the Apple Development Team ID so code signing settings can be injected automatically.

## 1. Local Setup

Create the script `Scripts/exportDevelopmentTeam.sh` (do **not** commit your actual team ID if you prefer keeping it private):

```bash
export DEVELOPMENT_TEAM=YOUR_TEAM_ID   # Replace with your real team ID
```

(An example template exists: `Scripts/exportDevelopmentTeam.sh.example.sh`).

Then run:

```bash
source Scripts/exportDevelopmentTeam.sh
bash Scripts/regenerateSigningConfig.sh
```

This generates `Config/Signing.xcconfig` containing:

```text
DEVELOPMENT_TEAM = <your team id>
```

`Project.swift` reads this xcconfig during manifest evaluation so the correct `DEVELOPMENT_TEAM` propagates to all targets.

## 2. Regenerating the Project

After generating the signing config:

```bash
tuist generate
```

If you change the team ID later, just re-run the two commands and regenerate.

## 3. CI Configuration

In CI (e.g. GitHub Actions), define an environment variable `DEVELOPMENT_TEAM` and invoke the same flow before `tuist generate`:

```yaml
- name: Set up Development Team
  run: |
    export DEVELOPMENT_TEAM=${{ vars.DEVELOPMENT_TEAM }}
    ./Scripts/regenerateSigningConfig.sh

- name: Generate project
  run: tuist generate --no-open
```