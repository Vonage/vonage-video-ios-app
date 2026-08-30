---
name: run-tests
description: Route "run the tests" to the right xcodebuild invocation for this repo — pick macOS vs iOS-simulator vs snapshot scheme for a given file or module, with the exact flags CI uses. Use whenever the user asks to run tests, verify a change, check whether tests pass, run a single suite, or after editing code in any VERA module and tests should be run.
---

# Running VERA Tests

Pick the cheapest destination that actually covers the change. macOS runs need no simulator and are much faster — prefer them whenever the module allows it.

Prerequisite: the workspace must exist (`cd VERA && tuist generate` after any Project.swift/config change). If `tuist generate` dies with a `fatalError` about app-config, a key referenced in `TestSchemes.swift` is missing from `Config/app-config.json` — that's a config problem, not a Tuist bug.

## Routing: source file → scheme + destination

Rule: sources in `VERA/VERA<X>/` → scheme `VERA<X>Tests` (unit) and `VERA<X>SnapshotTests` (snapshot, always iOS-simulator).

**macOS-capable unit schemes** (`-destination "platform=macOS"` — fast path):
`VERACoreTests`, `VERADomainTests`, `VERAMeetingRoomTests`, `VERAChatTests`, `VERAArchivingTests`, `VERACaptionsTests`, `VERAReactionsTests`, `VERASettingsTests`, `VERAScreenShareTests`, `VERAFeedbackTests`, `VERAAudioDiagnosticsTests`, `VERACommonUITests`, `VERALoggerTests`, `VERACocoaLumberjackLoggerTests`

**iOS-simulator-only unit schemes** (`-destination "platform=iOS Simulator,name=iPhone 17"`) — anything touching the Vonage SDK, UIKit, or VideoTransformers:
`VERAVonageTests`, `VERAMeetingRoomSDKTests`, `VERAAudioEffectsTests`, `VERABackgroundEffectsTests`, `VERATests` (app), and every `VERAVonage<X>PluginTests`

**Snapshot schemes** (iOS simulator + `-parallel-testing-enabled NO`, see the `record-snapshots` skill for failures):
`<Module>SnapshotTests` for Core, MeetingRoom, CommonUI, Chat, Archiving, Captions, Reactions, Settings, AudioEffects, BackgroundEffects, Feedback, AudioDiagnostics

If a change spans modules, remember tests also live downstream: a `VERADomain` protocol change should run `VERADomainTests` plus the consuming modules' suites — or just use the aggregates below.

## Invocations

Single module, macOS (fastest — default for most edits):
```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACoreTests \
  -destination "platform=macOS" \
  COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Single module, iOS simulator:
```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERAVonageTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Snapshot suite:
```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACoreSnapshotTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Everything CI runs, per destination (aggregate schemes from `TestSchemes.swift`):
- `VERAUnitTests-macOS` → `platform=macOS`
- `VERAUnitTests-iOS` → `platform=iOS Simulator,name=iPhone 17`
- `VERASnapshotTests-iOS` → same simulator + `-parallel-testing-enabled NO`

CI adds `-enableCodeCoverage YES -derivedDataPath DerivedData -resultBundlePath ...` and `CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES RUN_SWIFTLINT=NO` — only add these when reproducing CI exactly. Or run the entire suite with `cd VERA && tuist test`.

## Narrowing to one suite or test

Layer `-only-testing` on any scheme:
```
-only-testing:<TestTarget>/<SuiteTypeName>/<testFunctionName>
```
Use the Swift **type** name of the suite (e.g. `VERACoreTests/LandingViewModelTests`), not the `@Suite("...")` display string. Combining an aggregate scheme with `-only-testing:<TestTarget>` also works and avoids scheme-name guessing.

## Output handling

`xcpretty` is optional — if it's not installed, drop the pipe or filter raw output instead:
```bash
... 2>&1 | grep -E "✘|error:|TEST SUCCEEDED|TEST FAILED|Test run with" | tail -20
```
Always report the actual result line (`TEST SUCCEEDED` / `TEST FAILED` plus failing test names) — never infer success from exit-code-free filtered output alone.

## Gotchas

- The aggregate schemes' contents are feature-flag-gated: a module whose `allowX` key is `false` in `Config/app-config.json` silently drops out of them. Run its per-module scheme directly if you need it regardless.
- `VERACaptionsTests`, `VERALoggerTests`, `VERAVonageCaptionsPluginTests`, and `VERAVonageReactionsPluginTests` are covered by per-module schemes but **not** by any aggregate scheme (CI never runs them) — when a change touches those modules, run their schemes explicitly.
- Snapshot tests on a fresh clone fail en masse until `git lfs pull` (LFS smudge is skipped by default).
- Simulator name is `iPhone 17` with no OS pin; if the run fails with "unable to find destination", list devices with `xcrun simctl list devices available` and use an existing iPhone name.
