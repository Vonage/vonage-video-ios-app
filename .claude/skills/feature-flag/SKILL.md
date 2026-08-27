---
name: feature-flag
description: Add, remove, or wire a feature flag end-to-end in this repo — app-config.json key, Tuist Project.swift mapping, compile conditions, DependencyContainer, AppConfig codegen, test-scheme gating. Use whenever the user wants to feature-gate something, add a config toggle, make a feature optional, ask why a flag isn't taking effect, or mentions allowX keys, XXX_ENABLED conditions, or app-config.json.
---

# VERA Feature Flags, End-to-End

**First, pick the right mechanism.** Since the `VERAMeetingRoomSDK` refactor there are two distinct paths, and several docs (including parts of CLAUDE.md, `docs/CONFIGURATION.md`, and copilot instructions) still describe the old one — trust the code, not the flag tables in docs:

- **Meeting-room features** (chat, captions, reactions, screen share, and anything surfacing inside the call UI) are **runtime-gated**, not compile-gated. `CHAT_ENABLED`, `CAPTIONS_ENABLED`, `REACTIONS_ENABLED`, `SCREEN_SHARE_ENABLED` no longer exist as live compile conditions.
- **App-level features** (waiting room, goodbye screen, things `VERAApp` itself links) still use compile flags. The live set is exactly: `ARCHIVING_ENABLED`, `BACKGROUND_EFFECTS_ENABLED`, `SETTINGS_ENABLED`, `AUDIOEFFECTS_ENABLED`, `AUDIODIAGNOSTICS_ENABLED`, `FEEDBACK_ENABLED`. These apply **only to the VERA app target** — module frameworks never see them.

## The config source

`VERA/Config/app-config.json` has four sections — `videoSettings`, `audioSettings`, `waitingRoomSettings`, `meetingRoomSettings` — mostly `allowX: Bool` keys plus `defaultResolution` and `defaultLayoutMode` strings. Put a new key in the section it logically belongs to.

## Checklist for a new key (both paths)

1. **`VERA/Config/app-config.json`** — add the key.
2. **`VERA/Scripts/generate-app-config.py`** — the generator is a hardcoded template; new keys do *not* flow through. Add the key in its three places for the section (a `public let`, a defaulted `init` parameter, an assignment), then from `VERA/`:
   ```bash
   python3 ./Scripts/generate-app-config.py
   ```
   Commit the regenerated `VERAConfiguration/VERAConfiguration/AppConfig.swift` — CI does not run this script; the output is checked in.
3. **`VERA/Tuist/ProjectDescriptionHelpers/TestSchemes.swift`** — if the flag gates a module with test targets, gate those targets with `isFeatureEnabled("<section>", "<key>")` in the relevant aggregate scheme lists (macOS unit / iOS unit / snapshot). Note this helper `fatalError`s on a missing key — if `tuist generate` dies with a config fatalError, a key referenced here was renamed or removed.
4. **`cd VERA && tuist generate`** — required after any config or Project.swift change.

## Path A: meeting-room runtime feature

1. Add a case to the `MeetingRoomFeature` enum in `VERA/VERAMeetingRoomSDK/VERAMeetingRoomSDK/MeetingRoomFeature.swift`.
2. Map config → feature in `DependencyContainer.meetingRoomEnabledFeatures` ([DependencyContainer.swift](VERA/VERAApp/VERA/App/DependencyContainer.swift)):
   ```swift
   if appConfig.meetingRoomSettings.allowX { features.insert(.x) }
   ```
3. Gate behavior inside the SDK with `enabledFeatures.contains(.x)` — plugin registration in `MeetingRoomSDKContainer.pluginRegistry`, button in `BottomBarButtonsAssembler.buildButtons()`, overlay via an `XOverlayModifier` with `isEnabled:` in `MeetingRoomComposedView`. Cross-feature consumers get **Null-object fallbacks** (`NullStatsCollector()` style), never `#if`.
4. The SDK's `Project.swift` links all feature modules unconditionally — no dependency edit needed for the flag itself.

## Path B: app-level compile flag

All edits in `VERA/Project.swift`, which reads `./Config/app-config.json` at manifest-evaluation time:

1. **Reader** — add a `private func areXEnabled() -> Bool` (force-cast style matching neighbors) above the `// MARK: - Dynamic Dependencies` marker.
2. **Dependencies** — in `createDependencies()`, append the module (+ plugin) inside `if areXEnabled() { ... }` before the final `return dependencies`.
3. **Compile condition** — in `createBuildSettings()`:
   ```swift
   if areXEnabled() {
       baseSettings["X_ENABLED"] = "1"
       flags.append("X_ENABLED")
   }
   ```
   The existing `if !flags.isEmpty` block folds these into `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.
4. **Consume the flag** — in `VERAApp` only:
   - `DependencyContainer.swift`: `#if X_ENABLED` around the `import`s and the lazy factory/repository properties. When another component needs the dependency regardless of the flag, use the Null-object pattern (`#if` inside the lazy var choosing real vs `NullXUseCase()`).
   - `VERAApp.swift`: the surface wiring — `makeWaitingRoomToolbarButtons()`, `makeWaitingRoomTrailingButtons()`, `makeGoodbyeAdditionalContentView(roomName:)`, and flagged computed factory accessors follow the existing `#if` blocks there.
5. If the module pulls an extra SPM package (like background effects → VonageVideoTransformers), also gate it in `createPackages()`.

## Verify

Toggle the key to `false`, run `tuist generate`, and confirm: the module drops out of the app's dependencies, `#if` code compiles out (build the app), and the gated test targets leave the aggregate schemes. Toggle back, regenerate, and build again. A flag that "isn't working" is almost always one of: forgot `tuist generate`, edited `AppConfig.swift` by hand instead of the JSON + generator, or expected a compile flag for what is now a runtime `MeetingRoomFeature`.
