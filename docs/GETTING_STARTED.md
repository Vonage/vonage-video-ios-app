# Getting Started

This guide walks you through the prerequisites, environment setup, and first run of the Vonage Video iOS Reference App.

## Prerequisites

Install the following tools before cloning the repository:

```bash
brew install swiftlint
brew install swift-format
brew install --formula tuist
brew install git-lfs
```

> **Java 17** is also required for Maestro E2E testing. See [Testing](TESTING.md) for details.

## Backend Setup

The app requires a running backend. Follow the setup and deployment instructions in the [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app?tab=readme-ov-file#running-locally) repository. Once the backend is deployed, note its API base URL — you will need it in the next step.

## Environment Variables

Export the following environment variables before running any code-generation scripts. All commands in this section must be run from the `VERA/` directory.

```bash
export BASE_API_URL=https://api.example.net/
export DEVELOPMENT_TEAM=AB0C12DE34   # Find in Apple Developer portal → Certificates, Identifiers & Profiles
export MARKETING_VERSION=1.1
export CURRENT_PROJECT_VERSION=1
```

## Build (one command)

The simplest path is the builder script, which runs code generation and generates the workspace, then opens Xcode:

```bash
cd VERA
./Scripts/builder.sh
```

After editing `Config/app-config.json` or `Config/theme.json`, regenerate with:

```bash
./Scripts/builder.sh --update
```

See [Building the Starter Kit (Prebuilts)](../VERA/PREBUILTS_README.md) for the full flow.

> A plain `tuist generate` rebuilds the workspace but does **not** regenerate the JSON-driven files (`AppConfig.swift`, theme assets). Use `./Scripts/builder.sh --update` after changing a config file.

## Manual steps (equivalent to `builder.sh`)

If you prefer to run the steps yourself, from the `VERA/` directory:

```bash
# Code generation
./Scripts/generateEnvironmentConstants.sh   # → VERAApp/VERA/App/Generated/EnvironmentConstants.swift
./Scripts/regenerateSigningConfig.sh        # → Config/Signing.xcconfig
python3 ./Scripts/generate-app-config.py    # → VERAConfiguration/VERAConfiguration/AppConfig.swift
python3 ./Scripts/generate-app-theme.py     # → VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets

# Workspace
tuist generate
```

Tuist reads all `Project.swift` files and produces `VERA.xcworkspace`. Never edit `.xcodeproj` or `.xcworkspace` files directly — they are fully generated and are not committed.

Open the workspace in Xcode and run the **VERA** app target.

### Troubleshooting

| Problem | Fix |
|---|---|
| JSON config change not reflected | `./Scripts/builder.sh --update` |
| Stale workspace | `tuist clean` then `./Scripts/builder.sh --update` |
| Edit Tuist DSL files | `tuist edit` |

## Git LFS

After cloning, pull large files tracked by Git LFS:

```bash
git lfs pull
```

## Next Steps

| Topic | Guide |
|---|---|
| Feature flags and app-config | [Configuration](CONFIGURATION.md) |
| Module layout and architecture | [Architecture](ARCHITECTURE.md) |
| Running tests | [Testing](TESTING.md) |
| Localization | [Localization](LOCALIZATION.md) |
| Code style and linting | [Code Style](CODE_STYLE.md) |
| Contributing | [Contributing](CONTRIBUTING.md) |
