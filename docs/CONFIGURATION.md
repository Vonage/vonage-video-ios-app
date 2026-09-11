# Configuration

The app is configured through two primary mechanisms: **feature flags** in `Config/app-config.json` and **theme tokens** in `Config/theme.json`. Both are source files that drive code generation; the generated outputs (for example `AppConfig.swift` and `SemanticColors.xcassets`) are committed where applicable and must be regenerated whenever the JSON changes.

> Code generation is owned by `Scripts/builder.sh`. After editing any JSON below, run `./Scripts/builder.sh --update` — a plain `tuist generate` does **not** regenerate these files. See [Building the Starter Kit](../VERA/PREBUILTS_README.md).

## Feature Flags (`app-config.json`)

`VERA/Config/app-config.json` controls which optional features are enabled. Features are wired in two different ways:

- **Runtime (via `VERAMeetingRoomSDK`)** — chat, captions, reactions, screen share and picture-in-picture. These modules are always linked; `DependencyContainer.meetingRoomEnabledFeatures` reads `AppConfig` and passes the enabled set to the meeting room SDK. Toggling them hides/shows the feature at runtime.
- **Compile-time flags (in `Project.swift`)** — when `tuist generate` runs, `Project.swift` reads `app-config.json`, adds the corresponding module dependencies, and sets Swift compilation conditions.

### Compile-time flag mapping

| `app-config.json` key | Swift condition | Module enabled |
|---|---|---|
| `meetingRoomSettings.allowArchiving` | `ARCHIVING_ENABLED` | VERAArchiving + VERAVonageArchivingPlugin |
| `videoSettings.allowBackgroundEffects` | `BACKGROUND_EFFECTS_ENABLED` | VERABackgroundEffects |
| `meetingRoomSettings.allowSettings` | `SETTINGS_ENABLED` | VERASettings + VERAVonageSettingsPlugin |
| `audioSettings.allowAdvancedNoiseSuppression` | `AUDIOEFFECTS_ENABLED` | VERAAudioEffects |
| `audioSettings.allowAudioDiagnostics` | `AUDIODIAGNOSTICS_ENABLED` | VERAAudioDiagnostics |
| `meetingRoomSettings.allowFeedback` | `FEEDBACK_ENABLED` | VERAFeedback |

Code guarded by `#if BACKGROUND_EFFECTS_ENABLED … #endif` is only compiled when that flag is active. `DependencyContainer.swift` follows the same pattern to conditionally instantiate feature objects.

### Regenerating AppConfig.swift

After editing `app-config.json`, from the `VERA/` directory run:

```bash
./Scripts/builder.sh --update
```

This regenerates `VERAConfiguration/VERAConfiguration/AppConfig.swift` and the workspace. (Under the hood it runs `generate-app-config.py` then `tuist generate`.)

## Theme (`theme.json`)

`VERA/Config/theme.json` defines design tokens — colors, typography, and border radii — for the Vonage theme with separate light and dark variants. The generation step converts these tokens into Xcode assets and Swift files:

```bash
./Scripts/builder.sh --update
```

This regenerates `VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets` (plus `BorderRadius.swift` and `TypographyStyle.swift`). The generated outputs are committed and used by all `VERACommonUI` consumers.

## Signing Configuration

Signing is controlled by `VERA/Config/Signing.xcconfig` (generated, not committed). Regenerate it by exporting the required environment variables and running:

```bash
export DEVELOPMENT_TEAM=AB0C12DE34
./Scripts/regenerateSigningConfig.sh
```

See [Getting Started](GETTING_STARTED.md) for the full list of required environment variables.

## Environment Constants

The `BASE_API_URL` and other environment values are written into a generated Swift file:

```bash
./Scripts/generateEnvironmentConstants.sh
```

This produces `VERAApp/VERA/App/Generated/EnvironmentConstants.swift`.

## Vonage Video SDK Version

The SDK version is declared in:

```
VERA/Tuist/ProjectDescriptionHelpers/Package+Dependencies.swift
```

Adjust the version there and re-run `./Scripts/builder.sh --update` (or `tuist generate`, since this file is not JSON-driven). This app has been tested with **Vonage Video SDK 2.32** and **2.33**; use the latest available version where possible.
