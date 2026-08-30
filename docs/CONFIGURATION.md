# Configuration

The app is configured through two primary mechanisms: **feature flags** in `app-config.json` and **theme tokens** in `semantics.json`. Both are source files that drive code generation; the generated outputs (for example `AppConfig.swift` and `SemanticColors.xcassets`) are committed where applicable and must be regenerated whenever the JSON changes.

## Feature Flags (`app-config.json`)

`VERA/Config/app-config.json` gates optional features through two mechanisms:

### Runtime gating (meeting-room features)

Chat, captions, reactions, screen share, and the other in-call features are always compiled — `VERAMeetingRoomSDK` links every feature module unconditionally — and are enabled at runtime. `DependencyContainer.meetingRoomEnabledFeatures` (in `VERAApp`) maps `AppConfig` keys to `MeetingRoomFeature` cases, and `MeetingRoomSDKContainer` gates plugin registration and UI on `enabledFeatures.contains(_:)`. The old `CHAT_ENABLED`, `CAPTIONS_ENABLED`, `REACTIONS_ENABLED`, and `SCREEN_SHARE_ENABLED` compilation conditions no longer exist.

### Compile-time flags (app-level features)

When `tuist generate` runs, `Project.swift` reads the JSON, adds the corresponding module targets as dependencies of the app, and sets Swift compilation conditions on the VERA app target only:

| `app-config.json` key | Swift condition | Module enabled |
|---|---|---|
| `meetingRoomSettings.allowArchiving` | `ARCHIVING_ENABLED` | VERAArchiving + VERAVonageArchivingPlugin |
| `videoSettings.allowBackgroundEffects` | `BACKGROUND_EFFECTS_ENABLED` | VERABackgroundEffects |
| `meetingRoomSettings.allowSettings` | `SETTINGS_ENABLED` | VERASettings + VERAVonageSettingsPlugin |
| `audioSettings.allowAdvancedNoiseSuppression` | `AUDIOEFFECTS_ENABLED` | VERAAudioEffects |
| `audioSettings.allowAudioDiagnostics` | `AUDIODIAGNOSTICS_ENABLED` | VERAAudioDiagnostics |
| `meetingRoomSettings.allowFeedback` | `FEEDBACK_ENABLED` | VERAFeedback |

Code guarded by `#if SETTINGS_ENABLED … #endif` is only compiled when that flag is active. `DependencyContainer.swift` and `VERAApp.swift` follow the same pattern to conditionally instantiate app-level feature objects.

### Regenerating AppConfig.swift

After editing `app-config.json`, run from the `VERA/` directory:

```bash
python3 ./Scripts/generate-app-config.py
```

This regenerates `VERAConfiguration/VERAConfiguration/AppConfig.swift`. Then re-run `tuist generate` to rebuild the workspace with the updated module graph.

## Theme (`semantics.json`)

`VERA/Theme/semantics.json` defines design tokens — colors, typography, and border radii — for the Vonage theme with separate light and dark variants. Running the theme generation script converts these tokens into Xcode color assets:

```bash
python3 ./Scripts/generate-app-theme.py
```

This regenerates `VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets`. The generated asset catalog is committed and used by all `VERACommonUI` consumers.

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

Adjust the version there and re-run `tuist generate`. This app has been tested with **Vonage Video SDK 2.32** and **2.33**; use the latest available version where possible.
