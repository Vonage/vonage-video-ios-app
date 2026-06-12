# Testing

This guide covers unit tests, integration tests, snapshot tests, and end-to-end (E2E) tests for the Vonage Video iOS Reference App.

## Unit, Integration & Snapshot Tests

### Framework

Tests are written with the [Swift Testing](https://developer.apple.com/documentation/testing/) framework using `@Suite`, `@Test`, and `#expect`. Tuist generates test schemes for all modules automatically.

### Running All Tests

```bash
cd VERA && tuist test
```

### Running a Single Module (macOS — no simulator required)

```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACoreTests \
  -destination "platform=macOS" \
  COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Replace `VERACoreTests` with any unit/integration scheme: `VERAMeetingRoomTests`, `VERAChatTests`, `VERADomainTests`, `VERAArchivingTests`, `VERAReactionsTests`, `VERASettingsTests`, `VERAScreenShareTests`, `VERAAudioEffectsTests`, `VERACommonUITests`, `VERAVonageTests`, `VERABackgroundEffectsTests`, `VERACaptionsTests`, `VERAVonageChatPluginTests`, `VERAVonageSettingsPluginTests`.

### Running Snapshot Tests (iOS Simulator required)

```bash
xcodebuild test \
  -workspace VERA/VERA.xcworkspace \
  -scheme VERACoreSnapshotTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

Replace `VERACoreSnapshotTests` with any snapshot scheme: `VERAMeetingRoomSnapshotTests`, `VERAChatSnapshotTests`, `VERASettingsSnapshotTests`, `VERAAudioEffectsSnapshotTests`, `VERACaptionsSnapshotTests`, `VERAReactionsSnapshotTests`.

Snapshot images live in `__Snapshots__` folders next to the test files. Record new reference images by setting `record: true` in the snapshot assertion.

### Test Helpers

`VERATestHelpers` (a framework target inside `VERACore`) provides shared mocks and spies (`MockCall`, `MockSessionRepository`, etc.) used across all test targets.

---

## E2E Testing (Maestro)

VERA uses [Maestro](https://maestro.mobile.dev) for end-to-end UI testing. Flows are YAML-based and interact with the app through accessibility identifiers.

### Installation

Use the provided install script (runs from the repo root). It installs Maestro CLI and Java 17:

```bash
./scripts/install-maestro.sh
```

### Folder Structure

```text
.maestro/
├── config.yaml
├── docs/
│   └── README.md    ← pointer to this file
└── flows/
    ├── captions.yaml
    ├── recording.yaml
    └── ...
```

Flows live in `.maestro/flows` and are named by feature or behavior (e.g., `recording.yaml`).

### E2E Architecture

The app can run Maestro flows in two modes:

- **Offline mocked mode** — deterministic E2E mocks are enabled with `VERA_E2E_MOCKS=1`. `VERAE2E` provides `E2EHTTPClient`, `E2ESessionRepository`, `E2ECallFacade`, and `E2EArchivingDataSource` to mock all network and SDK calls.
- **Online mode** — mocks are disabled with `VERA_E2E_MOCKS=0`; flows use real backend and SDK services.

`VERAApp` decides whether E2E is active and injects the E2E dependencies. `VERAMeetingRoomSDK` remains independent of `VERAE2E`.

Additional diagnostic support: set `VERA_E2E_FAIL_ENDPOINT` to force one mocked endpoint to fail for error-flow testing.

### Running Tests

The recommended entry point is `scripts/run-maestro-tests.sh`. It builds the app, boots the simulator, grants camera and microphone permissions, installs the app, runs Maestro, and collects failure logs.

#### Offline Mocked Mode (default)

```bash
# Run all flows
./scripts/run-maestro-tests.sh

# Run a single flow by name
./scripts/run-maestro-tests.sh recording.yaml

# Run a single flow by path
./scripts/run-maestro-tests.sh .maestro/flows/captions.yaml
```

#### Online Mode

```bash
# Run all flows against real services
./scripts/run-maestro-tests.sh --online-mode

# Run a single flow against real services
./scripts/run-maestro-tests.sh --online-mode recording.yaml
```

#### Simulator Selection

```bash
SIMULATOR_DEVICE="iPhone 17 Pro" ./scripts/run-maestro-tests.sh
```

#### Direct Maestro CLI

Direct Maestro runs skip the build/install setup. Pass env vars explicitly:

```bash
maestro test \
  --env APP_ID=com.vonage.VERA \
  --env VERA_E2E_MOCKS=1 \
  .maestro/flows/recording.yaml
```

### Logs and Artifacts

Maestro stores artifacts under `~/.maestro/tests/`. The run script also creates `test-reports/`. On failure, simulator logs are saved to `test-reports/os-simulator.log`. The CI workflow uploads both Maestro artifacts and `test-reports/`.

### Writing Flows With Accessibility IDs

Tests target elements using accessibility identifiers. Prefer IDs for actions; use visible text only when validating user-visible content.

#### Screen Anchors

For screen-level assertions, add a small invisible anchor inside the screen content:

```swift
public var body: some View {
    ZStack {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityElement()
            .accessibilityIdentifier("landing-screen")

        Group { ... }
    }
}
```

#### Buttons

```swift
FilledButton(
    text: Text("Join meeting"),
    accessibilityID: "join-meeting-button",
    onAction: onJoinRoom
)
```

#### Text Fields

```swift
TextField("", text: $userName)
    .accessibilityIdentifier("waiting-room-name-field")
```

#### Lists and Rows

Put the identifier on the row content, not just a parent container:

```swift
HStack {
    Image(systemName: "video")
    Text(archive.name)
}
.accessibilityIdentifier("archiving-archive-item")
```

> Avoid applying `.accessibilityIdentifier()` only to containers like `Group`, `VStack`, or `NavigationView`. Use the invisible anchor pattern for screens and direct IDs for controls.

#### Example: Landing Screen Validation

```yaml
appId: com.vonage.VERA
---
- launchApp:
    clearState: true
    arguments:
      VERA_E2E_MOCKS: "${VERA_E2E_MOCKS}"

- waitForAnimationToEnd:
    timeout: 5000

- assertVisible:
    id: "landing-screen"

- takeScreenshot: landing-screen
```

#### Example: Full Meeting Flow

```yaml
appId: com.vonage.VERA
---
- launchApp:
    clearState: true
    permissions:
      camera: allow
      microphone: allow
    arguments:
      VERA_E2E_MOCKS: "${VERA_E2E_MOCKS}"

- waitForAnimationToEnd:
    timeout: 5000

- assertVisible:
    id: "landing-screen"

- tapOn:
    id: "landing-create-room-button"

- assertVisible:
    id: "waiting-room-screen"

- tapOn:
    id: "waiting-room-name-field"
- inputText: "Test User"
- hideKeyboard

- tapOn:
    id: "join-meeting-button"

- extendedWaitUntil:
    visible:
      id: "meeting-room-screen"
    timeout: 15000

- tapOn:
    id: "meeting-room-end-call-button"

- assertVisible:
    id: "goodbye-screen"

- takeScreenshot: goodbye-screen
```

### Useful Links

- [Maestro Documentation](https://maestro.mobile.dev)
- [Maestro CLI Commands](https://maestro.mobile.dev/api-reference/commands)
- [Maestro Studio](https://maestro.mobile.dev/getting-started/maestro-studio)
