# VERA Dynamic Configuration System

This system enables or disables VERA application features and design tokens through JSON configuration files, without touching Swift code by hand.

> Build flow lives in [`PREBUILTS_README.md`](PREBUILTS_README.md). After editing any config file, run `./Scripts/builder.sh --update`.

## Important Files

- `./Config/app-config.json` — feature flags and `baseApiUrl` (edit this).
- `./Config/theme.json` — design tokens: colors, typography, border radii (edit this).
- `Scripts/generate-app-config.py` — generates Swift from `app-config.json`.
- `Scripts/generate-app-theme.py` — generates theme assets from `theme.json`.
- `VERAConfiguration/VERAConfiguration/AppConfig.swift` — auto-generated (do not edit).

## How It Works

Code generation is owned by **`Scripts/builder.sh`**, not by `Project.swift`.

1. **Codegen** (`builder.sh`): the Python scripts read `app-config.json` / `theme.json` and generate `AppConfig.swift` and the theme assets.
2. **Project graph** (`tuist generate`, run by `builder.sh`): `Project.swift` reads `app-config.json` and, for the flag-gated features, adds the module dependencies and Swift compilation conditions.
3. **Runtime**: `AppConfig` values are read at runtime — most meeting-room features are enabled/disabled here (see below).

> A plain `tuist generate` does **not** regenerate `AppConfig.swift` or theme assets. Always use `./Scripts/builder.sh --update` after editing a JSON file.

## Runtime features vs. compile-time flags

Not all features work the same way:

- **Runtime (via `VERAMeetingRoomSDK`)** — `allowChat`, `allowCaptions`, `allowEmojis` (reactions), `allowScreenShare`, plus picture-in-picture. These modules are always linked; `DependencyContainer.meetingRoomEnabledFeatures` reads `AppConfig` and passes the enabled set to the meeting room SDK. Turning them off hides the feature at runtime.
- **Compile-time flags (in `Project.swift`)** — `allowArchiving` → `ARCHIVING_ENABLED`, `allowBackgroundEffects` → `BACKGROUND_EFFECTS_ENABLED`, `allowSettings` → `SETTINGS_ENABLED`, `allowAdvancedNoiseSuppression` → `AUDIOEFFECTS_ENABLED`, `allowAudioDiagnostics` → `AUDIODIAGNOSTICS_ENABLED`, `allowFeedback` → `FEEDBACK_ENABLED`. These add/remove `VERAApp` dependencies and guard code with `#if …_ENABLED`.

## Usage

### Enable / disable a feature

1. Edit the relevant flag in `Config/app-config.json`, e.g.:
   ```json
   {
     "meetingRoomSettings": { "allowChat": false }
   }
   ```
2. Regenerate:
   ```bash
   ./Scripts/builder.sh --update
   ```
3. Build in Xcode (Clean Build Folder if a toggled feature doesn't take effect).

## Accessing Configuration in Code

`AppConfig` exposes the parsed configuration:

```swift
let chatEnabled     = AppConfig().meetingRoomSettings.allowChat
let videoOnJoin     = AppConfig().videoSettings.allowVideoOnJoin
let defaultLayout   = AppConfig().meetingRoomSettings.defaultLayoutMode
let baseApiUrl      = AppConfig.baseApiUrl   // static
```

## Adding a new configurable feature

1. Add the key to `Config/app-config.json`.
2. Update `Scripts/generate-app-config.py` to read it into `AppConfig`.
3. Wire it either:
   - **at runtime** — add a `MeetingRoomFeature` case and insert it in `DependencyContainer.meetingRoomEnabledFeatures`, or
   - **at compile time** — add the flag in `Project.swift` (`createDependencies()` / `createBuildSettings()`) and guard code with `#if …_ENABLED`.
4. Run `./Scripts/builder.sh --update`.

## Troubleshooting

| Problem | Fix |
|---|---|
| JSON change not reflected | Run `./Scripts/builder.sh --update` (not a plain `tuist generate`) |
| `AppConfig.swift` not updated | Run the script directly: `python3 Scripts/generate-app-config.py` and check for JSON errors |
| Compile-time flag not applied | Confirm the flag appears in the target's **Active Compilation Conditions**, then `tuist clean` + `./Scripts/builder.sh --update` |

## Notes

- `VERAConfiguration/VERAConfiguration/AppConfig.swift` and the theme assets are generated — never edit them by hand.
- `.xcodeproj` / `.xcworkspace` are generated and not committed; never edit them directly.
