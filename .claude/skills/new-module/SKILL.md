---
name: new-module
description: Create a new VERA feature module (optionally with a Vonage plugin) using scripts/generate-module.sh plus all the manual integration the script doesn't do. Use whenever the user wants to add a new feature module, scaffold a module, create a plugin module, or add a new meeting-room feature — even if they just describe the feature ("add a polls feature") without saying "module".
---

# New VERA Feature Module

Scaffold a module with `scripts/generate-module.sh`, then do the integration work the script leaves undone. The script predates the `VERAMeetingRoomSDK` refactor, so several of its automated steps are stale — treat it as a scaffolder, not a full integrator.

## Before running the script — decide with the user

1. **Module name**: PascalCase, *without* the `VERA` prefix (script derives `VERA<Name>`, `VERAVonage<Name>Plugin`, config key `allow<Name>`, flag `<NAME>_ENABLED`).
2. **Does it need a Vonage plugin?** Yes if it sends/receives session signals or needs call lifecycle callbacks (`callDidStart`/`callDidEnd`) → `--with-plugin`.
3. **Where does the feature surface?** This determines the integration path after scaffolding:
   - **Meeting room** (a bottom-bar button, overlay, or in-call behavior) → runtime `MeetingRoomFeature` path. No compile flag is used at runtime even though the script adds one.
   - **App-level** (waiting room, goodbye screen, landing) → compile-flag path via `DependencyContainer`. See the `feature-flag` skill for that wiring.

## Running the script

```bash
./scripts/generate-module.sh <Name> --with-plugin --skip-build --no-run-app
```

Warn the user first about the script's side effects:
- It **force-quits Xcode** (`killall Xcode`) if running.
- It **unconditionally runs `git add -A` and `git commit --no-verify`** at the end — no flag disables this. Make sure the working tree is clean first so the auto-commit contains only scaffolding; if the user doesn't want the commit, plan to `git reset --soft HEAD~1` afterwards.
- Default behavior opens Xcode and hits ⌘R — pass `--no-run-app` to suppress.
- Its CI-edit step targets markers that were removed when CI was consolidated to aggregated schemes; most of those edits print `WARNING: marker not found` and no-op (fine), but check `.github/workflows/ci.yml` afterwards for a redundant per-module step it may still inject near "Preboot iOS Simulator" and remove it — the aggregated schemes already cover new test targets.

What the script does automate correctly: module + plugin directory scaffold with Clean Architecture layers, `Project.swift` per module, adds `meetingRoomSettings.allow<Name>` to `Config/app-config.json`, adds `are<Name>Enabled()` + dependency + build-flag blocks to `VERA/Project.swift`, runs `tuist generate` and `format.sh --fix`.

## Manual integration checklist (the script does none of this)

Work through all of these — a module that skips them compiles but never appears in the app or CI:

1. **Test schemes** — register the new test targets in [TestSchemes.swift](VERA/Tuist/ProjectDescriptionHelpers/TestSchemes.swift) (`VERATestSchemes`), gated with `isFeatureEnabled("meetingRoomSettings", "allow<Name>")`, in up to three places: macOS unit scheme, iOS unit scheme (plugin tests), snapshot scheme. Without this the tests never run in CI, and since `Workspace.swift` is `projects: ["."]`, scheme/dependency edges are what pull the module project into the workspace.
2. **AppConfig codegen** — `VERA/Scripts/generate-app-config.py` is hardcoded; add the new key in its three places for the section (property, defaulted init param, assignment), run `python3 ./Scripts/generate-app-config.py` from `VERA/`, and commit the regenerated `AppConfig.swift`.
3. **Fix the scaffold's known gaps**:
   - Generated module `Project.swift` omits the `VERADomain` dependency and `options: defaultProjectOptions()` — add both to match hand-written modules like `VERASettings/Project.swift`.
   - The generated plugin class is a bare `public final class` — make it conform to `VonagePlugin` (`VonagePluginCallLifeCycle & VonagePluginID`); adopt `VonageSignalEmitter`/`VonageSignalHandler` if it uses signals, `VonagePluginCallHolder` if it needs the call (see `VonageReactionsPlugin` for the full shape).
   - The generated `<Name>Factory` is an empty enum; build it out to the repo convention of returning `(view, viewModel)` pairs with dependencies injected through `init`.
4. **For a meeting-room feature**, wire the runtime path (all in `VERA/VERAMeetingRoomSDK/`):
   - Add a case to `MeetingRoomFeature` enum.
   - Add the module (+ plugin) to the SDK's `Project.swift` **unconditional** dependency list.
   - In `MeetingRoomSDKContainer.swift`: import, add a `// MARK: - <Name> Feature` block of lazy repos/plugin/use cases/factory, register the plugin in `pluginRegistry` behind `enabledFeatures.contains(.<name>)`. Cross-feature consumers use Null-object fallbacks, not `#if`.
   - In `BottomBarButtonsAssembler.swift`: append the button in `buildButtons()` behind the feature check, plus the `onShow<Name>` binding, `is<Name>Presented` + setter, and `cleanUp()`.
   - In `MeetingRoomComposedView.swift`: add a `<Name>OverlayModifier` (copy `SettingsOverlayModifier` — `isEnabled` + `if isEnabled { content.sheet(...) }`), `@State var show<Name>`, `.onAppear`/`.onChange` wiring; `MeetingRoomBuilder.build()` if a pre-created view model is needed.
   - In `VERAApp/VERA/App/DependencyContainer.swift`: one line in `meetingRoomEnabledFeatures` mapping `appConfig.meetingRoomSettings.allow<Name>` → `.insert(.<name>)`.
5. **For an app-level feature**, follow the `feature-flag` skill instead: keep the compile flag the script added to `VERA/Project.swift` and wire `#if <NAME>_ENABLED` blocks in `DependencyContainer.swift` and `VERAApp.swift`.
6. **Regenerate and verify** — `cd VERA && tuist generate`, then build and run the module's unit tests on macOS (fast, no simulator):
   ```bash
   xcodebuild test -workspace VERA/VERA.xcworkspace -scheme VERA<Name>Tests \
     -destination "platform=macOS" \
     COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
   ```

## Conventions to hold the line on

- Clean Architecture dependency rule: `Domain/` imports nothing from `Data/`/`UI/`/`Wireframe/`; `Data/` and `UI/` depend only on `Domain/`; `Wireframe/` composes all layers.
- Note the script always inserts the config key into `meetingRoomSettings` — if the feature logically belongs in `videoSettings`/`audioSettings`/`waitingRoomSettings`, move the key and update every place that references the section (Project.swift reader, TestSchemes gate, generate-app-config.py).
- Script-derived Project.swift helpers use the `are<Name>Enabled()` form to sidestep the repo's `is…`/`are…` inconsistency; keep whatever the script generated.
- Plugins are iOS-only; the module framework itself should stay multiplatform (iOS 16 + macOS 14.6) unless it imports the Vonage SDK or UIKit.
