---
inclusion: fileMatch
fileMatchPattern: 'VERA/Config/**'
---

# VERA Feature Flags, End-to-End

Pull this in manually with `#vera-feature-flags` when editing `VERA/Project.swift`,
`generate-app-config.py`, or `TestSchemes.swift` — those paths do not auto-match.

## Two mechanisms — pick the right one first

Several repo docs (`docs/CONFIGURATION.md`, `.github/copilot-instructions.md`,
`VERA/CONFIGURATION_README.md`) still describe a pre-refactor world. **Trust the code, not
those tables.**

- **Meeting-room features** (chat, captions, reactions, screen share, and anything surfacing
  inside the call UI) are **runtime-gated**. `CHAT_ENABLED`, `CAPTIONS_ENABLED`,
  `REACTIONS_ENABLED`, and `SCREEN_SHARE_ENABLED` no longer exist as live compile conditions.
- **App-level features** (waiting room, goodbye screen, things `VERAApp` links directly) still
  use compile flags. The live set is exactly `ARCHIVING_ENABLED`, `BACKGROUND_EFFECTS_ENABLED`,
  `SETTINGS_ENABLED`, `AUDIOEFFECTS_ENABLED`, `AUDIODIAGNOSTICS_ENABLED`, `FEEDBACK_ENABLED` —
  and they apply to the **VERA app target only**, never to module frameworks.

Verify the live set at any time with:
`grep -o '"[A-Z_]*_ENABLED"' VERA/Project.swift | sort -u`

## Checklist for a new key (both paths)

1. `VERA/Config/app-config.json` — add the key to the right section (`videoSettings`,
   `audioSettings`, `waitingRoomSettings`, `meetingRoomSettings`).
2. `VERA/Scripts/generate-app-config.py` — the generator is a hardcoded template; new keys do
   **not** flow through automatically. Add the key in three places for that section (a
   `public let`, a defaulted `init` parameter, an assignment), then run from `VERA/`:
   `python3 ./Scripts/generate-app-config.py`. Commit the regenerated `AppConfig.swift` — CI
   does not run this script, the output is checked in.
3. `VERA/Tuist/ProjectDescriptionHelpers/TestSchemes.swift` — gate the module's test targets
   with `isFeatureEnabled("<section>", "<key>")` in the relevant aggregate scheme lists. This
   helper `fatalError`s on a missing key: a `tuist generate` failure mentioning app-config
   usually means a key referenced here was renamed or removed.
4. `cd VERA && tuist generate` — required after any config or `Project.swift` change.

## Path A: meeting-room runtime feature

1. Add a case to `MeetingRoomFeature`
   (`VERA/VERAMeetingRoomSDK/VERAMeetingRoomSDK/MeetingRoomFeature.swift`).
2. Map config to feature in `DependencyContainer.meetingRoomEnabledFeatures`
   (`VERA/VERAApp/VERA/App/DependencyContainer.swift`):
   `if appConfig.meetingRoomSettings.allowX { features.insert(.x) }`
3. Gate behavior on `enabledFeatures.contains(.x)` — plugin registration in
   `MeetingRoomSDKContainer.pluginRegistry`, the button in
   `BottomBarButtonsAssembler.buildButtons()`, the overlay via an `XOverlayModifier` in
   `MeetingRoomComposedView`.
4. No dependency edit needed: the SDK's `Project.swift` links all feature modules
   unconditionally. Cross-feature consumers use **Null-object fallbacks**, never `#if`.

## Path B: app-level compile flag

All in `VERA/Project.swift`, which reads `./Config/app-config.json` at manifest-evaluation time:

1. Add a `private func areXEnabled() -> Bool` reader above the
   `// MARK: - Dynamic Dependencies` marker, matching the force-cast style of its neighbours.
2. In `createDependencies()`, append the module (+ plugin) inside `if areXEnabled() { ... }`
   before the final `return dependencies`.
3. In `createBuildSettings()`, add `baseSettings["X_ENABLED"] = "1"` and
   `flags.append("X_ENABLED")`; the existing `if !flags.isEmpty` block folds these into
   `SWIFT_ACTIVE_COMPILATION_CONDITIONS`.
4. Consume the flag in `VERAApp` only — `#if X_ENABLED` around imports and lazy properties in
   `DependencyContainer.swift`, and the surface wiring in `VERAApp.swift`
   (`makeWaitingRoomToolbarButtons()`, `makeWaitingRoomTrailingButtons()`,
   `makeGoodbyeAdditionalContentView(roomName:)`). Use the Null-object pattern when a
   dependency is needed regardless of the flag.
5. If the module pulls an extra SPM package, gate it in `createPackages()` too.

## Verify

Toggle the key to `false`, run `tuist generate`, confirm the module leaves the app's
dependencies, `#if` code compiles out, and gated test targets leave the aggregate schemes.
Toggle back and regenerate. A flag that "isn't working" is nearly always: forgot
`tuist generate`, hand-edited `AppConfig.swift` instead of the JSON + generator, or expected a
compile flag for what is now a runtime `MeetingRoomFeature`.
