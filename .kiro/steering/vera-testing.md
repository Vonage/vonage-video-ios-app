---
inclusion: fileMatch
fileMatchPattern: '**/*Tests/**'
---

# Running VERA Tests

Pick the cheapest destination that covers the change. macOS runs need no simulator and are much
faster — prefer them whenever the module allows it.

Prerequisite: the workspace must exist (`cd VERA && tuist generate` after any `Project.swift` or
config change). If `tuist generate` dies with a `fatalError` about app-config, a key referenced
in `TestSchemes.swift` is missing from `Config/app-config.json` — a config problem, not a Tuist bug.

## Routing: source file to scheme + destination

Rule: sources in `VERA/VERA<X>/` map to scheme `VERA<X>Tests` (unit) and `VERA<X>SnapshotTests`
(snapshot, always iOS simulator).

**macOS-capable unit schemes** (`-destination "platform=macOS"` — fast path):
`VERACoreTests`, `VERADomainTests`, `VERAMeetingRoomTests`, `VERAChatTests`,
`VERAArchivingTests`, `VERACaptionsTests`, `VERAReactionsTests`, `VERASettingsTests`,
`VERAScreenShareTests`, `VERAFeedbackTests`, `VERAAudioDiagnosticsTests`, `VERACommonUITests`,
`VERALoggerTests`, `VERACocoaLumberjackLoggerTests`

**iOS-simulator-only unit schemes** (`-destination "platform=iOS Simulator,name=iPhone 17"`) —
anything touching the Vonage SDK, UIKit, or VideoTransformers:
`VERAVonageTests`, `VERAMeetingRoomSDKTests`, `VERAAudioEffectsTests`,
`VERABackgroundEffectsTests`, `VERATests` (app), and every `VERAVonage<X>PluginTests`

**Snapshot schemes** (iOS simulator + `-parallel-testing-enabled NO`): `<Module>SnapshotTests`
for Core, MeetingRoom, CommonUI, Chat, Archiving, Captions, Reactions, Settings, AudioEffects,
BackgroundEffects, Feedback, AudioDiagnostics. For failures see `#vera-snapshot-tests`.

A change spanning modules has downstream tests too: a `VERADomain` protocol change should run
`VERADomainTests` plus the consuming modules' suites, or just use the aggregates below.

## Invocations

Single module, macOS (fastest — default for most edits):

```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACoreTests \
  -destination "platform=macOS" \
  COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Single module, iOS simulator — same, with
`-scheme VERAVonageTests -destination "platform=iOS Simulator,name=iPhone 17"`.

Everything CI runs, per destination (aggregate schemes from `TestSchemes.swift`):

- `VERAUnitTests-macOS` — `platform=macOS`
- `VERAUnitTests-iOS` — `platform=iOS Simulator,name=iPhone 17`
- `VERASnapshotTests-iOS` — same simulator plus `-parallel-testing-enabled NO`

CI adds `-enableCodeCoverage YES -derivedDataPath DerivedData -resultBundlePath ...` and
`CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES RUN_SWIFTLINT=NO`; add those only when
reproducing CI exactly. `cd VERA && tuist test` runs the whole suite.

## Narrowing to one suite or test

Layer `-only-testing:<TestTarget>/<SuiteTypeName>/<testFunctionName>` on any scheme. Use the
Swift **type** name of the suite (e.g. `VERACoreTests/LandingViewModelTests`), not the
`@Suite("...")` display string. Combining an aggregate scheme with `-only-testing:<TestTarget>`
also works and avoids scheme-name guessing.

## Output handling

`xcpretty` is optional — drop the pipe if it is not installed, or filter raw output:

```bash
... 2>&1 | grep -E "✘|error:|TEST SUCCEEDED|TEST FAILED|Test run with" | tail -20
```

Report the actual result line (`TEST SUCCEEDED` / `TEST FAILED` plus failing test names); never
infer success from filtered output alone.

## Gotchas

- Aggregate scheme contents are feature-flag-gated: a module whose `allowX` key is `false` in
  `Config/app-config.json` silently drops out. Run its per-module scheme directly if needed.
- `VERACaptionsTests`, `VERALoggerTests`, `VERAVonageCaptionsPluginTests`, and
  `VERAVonageReactionsPluginTests` have per-module schemes but are in **no** aggregate scheme —
  CI never runs them. Run them explicitly when touching those modules.
- Snapshot tests fail en masse on a fresh clone until `git lfs pull` (LFS smudge is skipped).
- Simulator is `iPhone 17`, no OS pin. On "unable to find destination", list what exists with
  `xcrun simctl list devices available`.
