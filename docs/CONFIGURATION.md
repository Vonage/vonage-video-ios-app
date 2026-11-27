# Configuration

The app is configured through two primary mechanisms: **feature flags** in `app-config.json` and **theme tokens** in `theme.json`. Both are source files that drive code generation; the generated outputs (for example `AppConfig.swift` and `SemanticColors.xcassets`) are committed where applicable and must be regenerated whenever the JSON changes.

Regenerating after any config or theme change is a single command from the `VERA/` directory: `./Scripts/builder.sh --update`. It covers both sections below plus the environment constants.

## Feature Flags (`app-config.json`)

`VERA/Config/app-config.json` controls which optional feature modules are compiled into the app. When `tuist generate` runs, `Project.swift` reads this file and:

1. Adds the corresponding module targets as dependencies.
2. Sets Swift compilation conditions so conditional compilation blocks are respected.

Meeting-room features (chat, captions, reactions, screen share) are **not** in this table — they are always compiled via `VERAMeetingRoomSDK` and gated at runtime by `MeetingRoomFeature` / `DependencyContainer.meetingRoomEnabledFeatures`.

### Flag Mapping

| `app-config.json` key | Swift condition | Module enabled |
|---|---|---|
| `meetingRoomSettings.allowArchiving` | `ARCHIVING_ENABLED` | VERAArchiving + VERAVonageArchivingPlugin |
| `videoSettings.allowBackgroundEffects` | `BACKGROUND_EFFECTS_ENABLED` | VERABackgroundEffects |
| `waitingRoomSettings.allowSettings` | `SETTINGS_ENABLED` | VERASettings + VERAVonageSettingsPlugin |
| `audioSettings.allowAdvancedNoiseSuppression` | `AUDIOEFFECTS_ENABLED` | VERAAudioEffects |
| `audioSettings.allowAudioDiagnostics` | `AUDIODIAGNOSTICS_ENABLED` | VERAAudioDiagnostics |
| `meetingRoomSettings.allowFeedback` | `FEEDBACK_ENABLED` | VERAFeedback |

Code guarded by `#if ARCHIVING_ENABLED … #endif` is only compiled when that flag is active. `DependencyContainer.swift` follows the same pattern to conditionally instantiate feature objects.

`meetingRoomSettings.allowCaptionTranslation` has no compilation condition. It is a runtime flag that enables `MeetingRoomFeature.captionsTranslation`, which adds a Captions section to Settings where each user picks the language their captions are translated into, including their own. It only takes effect together with `allowCaptions`, and it defaults to `false` when the key is missing. Translation is a private beta feature of the Vonage Video API, so it must be enabled for your project.

`meetingRoomSettings.allowPostCallTranscription` has no compilation condition. It is a runtime flag that enables `MeetingRoomFeature.postCallTranscription` in the meeting room SDK, which adds a Start/Stop transcription button next to the Record button. Transcription runs as a separate archive from the recording, so both can run at the same time. It requires a backend whose `startArchive` endpoint supports `withTranscription`.

When the meeting ends, the goodbye page lists the transcript under **Download session content** as a "Transcription N" row next to any "Recording N" rows. Transcription archives are the individual-stream archives with `hasTranscription` set; their download comes from the nested `transcription` object returned by `searchArchives`, not from the archive's own `url`. The list keeps polling until every archive and transcript has left the `requested`/`started`/`paused`/`stopped` statuses, so a transcript still processing after its parent archive is `uploaded` or `available` keeps the row in its loading state. Tapping **Download** on a transcription saves the zip to a temporary file and opens the share sheet, instead of opening the recording URL.

### Accessing Configuration in Code

The generated `AppConfig` type exposes each setting as a static property:

```swift
let chatEnabled = AppConfig.MeetingRoomSettings.allowChat
let videoOnJoin = AppConfig.VideoSettings.allowVideoOnJoin
let defaultLayout = AppConfig.MeetingRoomSettings.defaultLayoutMode
```

All properties are static; there is no instance to construct.

### Adding a New Feature Flag

1. Add the key to `app-config.json`.
2. Update `Scripts/generate-app-config.py` to read it and emit the matching `AppConfig` property.
3. If it needs a compile-time module dependency, add it to the flag mapping in `Project.swift` (see [Flag Mapping](#flag-mapping) above) and guard the code with `#if YOUR_FLAG_ENABLED`.
4. Run `./Scripts/builder.sh --update` and confirm the flag appears under **Swift Compiler - Custom Flags → Active Compilation Conditions** in the target's build settings.

### Regenerating AppConfig.swift

After editing `app-config.json`, run from the `VERA/` directory:

```bash
./Scripts/builder.sh --update
```

This regenerates `VERAConfiguration/VERAConfiguration/AppConfig.swift` and rebuilds the workspace with the updated module graph.

> **Debugging fallback:** to run just the config codegen step and see its output directly, use `python3 ./Scripts/generate-app-config.py`, then re-run `tuist generate` to rebuild the workspace. If a flag still doesn't seem to apply, confirm `app-config.json` is valid JSON, check that the generation script's output confirms the flag's value, and try `tuist clean && tuist generate`.

## Theme (`theme.json`)

`VERA/Config/theme.json` defines design tokens — colors, typography, and border radii — for the Vonage theme with separate light and dark variants. Running from the `VERA/` directory converts these tokens into Xcode color assets:

```bash
./Scripts/builder.sh --update
```

This regenerates `VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets`. The generated asset catalog is committed and used by all `VERACommonUI` consumers.

> **Debugging fallback:** to run just the theme codegen step and see its output directly, use `python3 ./Scripts/generate-app-theme.py`.

## Signing Configuration

Signing is controlled by `VERA/Config/Signing.xcconfig` (generated, not committed). Regenerate it by exporting the required environment variables and running:

```bash
export DEVELOPMENT_TEAM=AB0C12DE34
export MARKETING_VERSION=1.0
export CURRENT_PROJECT_VERSION=1
./Scripts/regenerateSigningConfig.sh
```

**Where to find your Team ID:** sign in at [developer.apple.com/account](https://developer.apple.com/account) → **Membership details** → **Team ID** (a 10-character string like `A1B2C3D4E5`). This is your **Apple Developer** team, not your Vonage account.

To install on a physical device you also need to be signed in to that team in **Xcode → Settings → Accounts**. The Simulator needs neither a team nor sign-in.

See [Getting Started](GETTING_STARTED.md) for the full list of required environment variables.

## Environment Constants

The `BASE_API_URL` and other environment values are written into a generated Swift file:

```bash
./Scripts/builder.sh --update
```

`./Scripts/builder.sh --update` always resolves the API base URL from `baseApiUrl` in `Config/app-config.json` — a valid, absolute `http`/`https` URL is required there, and it always overrides any `BASE_API_URL` already exported in your shell. To base the URL on an environment variable instead of a literal, set `baseApiUrl` to a `${VAR}` placeholder (for example `"${BASE_API_URL}"`); the script expands it from the environment before validating and injecting it.

This produces `VERAApp/VERA/App/Generated/EnvironmentConstants.swift`.

> **Debugging fallback:** to run just this codegen step and see its output directly, export `BASE_API_URL` yourself and use `./Scripts/generateEnvironmentConstants.sh` — unlike `builder.sh --update`, it reads `BASE_API_URL` directly from the environment and does not consult `app-config.json`.

## Updating a Dependency Version

All external dependency versions live in one file: `VERA/Dependencies.json`. Both the root `Package.swift` and the Tuist helper `VERA/Tuist/ProjectDescriptionHelpers/DependencyVersions.swift` read it directly — never inline a version literal in `Package.swift` or any `Package+*.swift`.

1. Edit the version in `VERA/Dependencies.json`.
2. Vonage SDKs live under the `vonage` key (`videoSDK`, `videoTransformersSDK`). If you change `videoSDK`, also change `videoTransformersSDK` to the same version — the Client SDK team requires the two to always match. Other dependencies live under `thirdParty`.
3. Run `tuist generate` from `VERA/` and verify the project builds and tests pass. If Xcode/SPM keeps resolving the old version, reset the package cache (File ▸ Packages ▸ Reset Package Caches), since manifest caching only tracks `Package.swift` itself.

This app has been tested with **Vonage Video SDK 2.32** and **2.33**; use the latest available version where possible.
