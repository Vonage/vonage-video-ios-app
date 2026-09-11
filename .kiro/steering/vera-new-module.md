---
inclusion: manual
---

# New VERA Feature Module

Reference with `#vera-new-module` when scaffolding a feature module or a Vonage plugin.

Scaffold with `scripts/generate-module.sh`, then do the integration work the script leaves
undone. The script predates the `VERAMeetingRoomSDK` refactor, so several of its automated steps
are stale — treat it as a scaffolder, not a full integrator.

## Decide before running

1. **Module name** — PascalCase, *without* the `VERA` prefix. The script derives `VERA<Name>`,
   `VERAVonage<Name>Plugin`, config key `allow<Name>`, flag `<NAME>_ENABLED`.
2. **Does it need a Vonage plugin?** Yes if it sends/receives session signals or needs call
   lifecycle callbacks (`callDidStart` / `callDidEnd`) — pass `--with-plugin`.
3. **Where does the feature surface?** This decides the integration path:
   - **Meeting room** (bottom-bar button, overlay, in-call behavior) — runtime
     `MeetingRoomFeature` path; no compile flag is used at runtime even though the script adds one.
   - **App-level** (waiting room, goodbye, landing) — compile-flag path via `DependencyContainer`;
     see `#vera-feature-flags`.

## Running the script

```bash
./scripts/generate-module.sh <Name> --with-plugin --skip-build --no-run-app
```

Side effects to warn about first:

- It **force-quits Xcode** (`killall Xcode`) if running.
- It **unconditionally runs `git add -A` and `git commit --no-verify`** at the end — no flag
  disables this. Make sure the working tree is clean first so the auto-commit contains only
  scaffolding.
- The default opens Xcode and sends Cmd-R; `--no-run-app` suppresses it.
- Its CI-edit step targets markers removed when CI was consolidated to aggregate schemes. Most
  of those edits print `WARNING: marker not found` and no-op, but check
  `.github/workflows/ci.yml` afterwards for a redundant per-module step injected near
  "Preboot iOS Simulator" and remove it — the aggregate schemes already cover new test targets.

Correctly automated: module + plugin scaffold with Clean Architecture layers, per-module
`Project.swift`, `meetingRoomSettings.allow<Name>` added to `Config/app-config.json`,
`are<Name>Enabled()` + dependency + build-flag blocks in `VERA/Project.swift`, then
`tuist generate` and `format.sh --fix`.

## Manual integration checklist (none of this is automated)

A module that skips these compiles but never appears in the app or CI.

1. **Test schemes** — register the new test targets in
   `VERA/Tuist/ProjectDescriptionHelpers/TestSchemes.swift`, gated with
   `isFeatureEnabled("meetingRoomSettings", "allow<Name>")`, in up to three places: macOS unit,
   iOS unit (plugin tests), snapshot. Without this the tests never run in CI, and since
   `Workspace.swift` is `projects: ["."]`, scheme/dependency edges are what pull the module
   project into the workspace.
2. **AppConfig codegen** — `VERA/Scripts/generate-app-config.py` is a hardcoded template; add the
   key in its three places for the section, run `python3 ./Scripts/generate-app-config.py` from
   `VERA/`, and commit the regenerated `AppConfig.swift`.
3. **Fix the scaffold's known gaps**:
   - The generated `Project.swift` omits the `VERADomain` dependency and
     `options: defaultProjectOptions()` — add both to match hand-written modules such as
     `VERASettings/Project.swift`.
   - The generated plugin class is a bare `public final class` — make it conform to
     `VonagePlugin` (`VonagePluginCallLifeCycle & VonagePluginID`); adopt `VonageSignalEmitter` /
     `VonageSignalHandler` for signals and `VonagePluginCallHolder` when it needs the call. See
     `VonageReactionsPlugin` for the full shape.
   - The generated `<Name>Factory` is an empty enum; build it out to the repo convention of
     returning `(view, viewModel)` pairs with dependencies injected through `init`.
4. **Meeting-room feature** — all under `VERA/VERAMeetingRoomSDK/`: add a `MeetingRoomFeature`
   case; add the module (+ plugin) to the SDK's **unconditional** dependency list; in
   `MeetingRoomSDKContainer.swift` add a `// MARK: - <Name> Feature` block of lazy
   repos/plugin/use cases/factory and register the plugin behind
   `enabledFeatures.contains(.<name>)`; in `BottomBarButtonsAssembler.swift` append the button
   behind the same check plus the `onShow<Name>` binding, `is<Name>Presented` + setter, and
   `cleanUp()`; in `MeetingRoomComposedView.swift` add a `<Name>OverlayModifier` (copy
   `SettingsOverlayModifier`), `@State var show<Name>`, and the `.onAppear` / `.onChange`
   wiring; finally map the config key in `DependencyContainer.meetingRoomEnabledFeatures`.
   Cross-feature consumers use Null-object fallbacks, not `#if`.
5. **App-level feature** — keep the compile flag the script added and wire `#if <NAME>_ENABLED`
   blocks in `DependencyContainer.swift` and `VERAApp.swift`. See `#vera-feature-flags`.
6. **Regenerate and verify** — `cd VERA && tuist generate`, then run the module's unit tests on
   macOS (fast, no simulator):
   ```bash
   xcodebuild test -workspace VERA/VERA.xcworkspace -scheme VERA<Name>Tests \
     -destination "platform=macOS" \
     COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
   ```

## Conventions to hold

- Clean Architecture dependency rule: `Domain/` imports nothing from `Data/` / `UI/` /
  `Wireframe/`; `Data/` and `UI/` depend only on `Domain/`; `Wireframe/` composes all layers.
- The script always inserts the config key into `meetingRoomSettings`. If the feature belongs in
  `videoSettings` / `audioSettings` / `waitingRoomSettings`, move the key and update every
  reference to the section (`Project.swift` reader, `TestSchemes.swift` gate,
  `generate-app-config.py`).
- Plugins are iOS-only; the module framework stays multiplatform (iOS 16 + macOS 14.6) unless it
  imports the Vonage SDK or UIKit.
