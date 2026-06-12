# Configuration

The app is configured through two primary mechanisms: **feature flags** in `app-config.json` and **theme tokens** in `semantics.json`. Both are source files that drive code generation; the generated Swift files are committed and must be regenerated whenever the JSON changes.

## Feature Flags (`app-config.json`)

`VERA/Config/app-config.json` controls which optional feature modules are compiled into the app. When `tuist generate` runs, `Project.swift` reads this file and:

1. Adds the corresponding module targets as dependencies.
2. Sets Swift compilation conditions so conditional compilation blocks are respected.

### Flag Mapping

| `app-config.json` key | Swift condition | Module enabled |
|---|---|---|
| `meetingRoomSettings.allowChat` | `CHAT_ENABLED` | VERAChat + VERAVonageChatPlugin |
| `meetingRoomSettings.allowArchiving` | `ARCHIVING_ENABLED` | VERAArchiving + VERAVonageArchivingPlugin |
| `videoSettings.allowBackgroundEffects` | `BACKGROUND_EFFECTS_ENABLED` | VERABackgroundEffects |
| `meetingRoomSettings.allowCaptions` | `CAPTIONS_ENABLED` | VERACaptions + VERAVonageCaptionsPlugin |
| `meetingRoomSettings.allowEmojis` | `REACTIONS_ENABLED` | VERAReactions + VERAVonageReactionsPlugin |
| `meetingRoomSettings.allowSettings` | `SETTINGS_ENABLED` | VERASettings + VERAVonageSettingsPlugin |
| `meetingRoomSettings.allowScreenShare` | `SCREEN_SHARE_ENABLED` | VERAScreenShare + VERAVonageScreenSharePlugin |
| `audioSettings.allowAdvancedNoiseSuppression` | `AUDIOEFFECTS_ENABLED` | VERAAudioEffects |

Code guarded by `#if CHAT_ENABLED … #endif` is only compiled when that flag is active. `DependencyContainer.swift` follows the same pattern to conditionally instantiate feature objects.

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
