# VERA E2E Testing

VERA uses [Maestro](https://maestro.mobile.dev) for end-to-end UI testing. Flows are YAML-based and interact with the app through accessibility identifiers.

This guide is the source of truth for Maestro flows, `VERAE2E`, offline mocked runs, online runs, logs, and accessibility ID conventions.

## E2E Architecture

The [`.maestro/flows`](../flows) directory contains the UI flows executed by Maestro. The app can run those flows in two modes:

- Offline mocked mode: deterministic E2E mocks are enabled with `VERA_E2E_MOCKS=1`.
- Online mode: mocks are disabled with `VERA_E2E_MOCKS=0`, so flows use real backend and SDK services.

`VERAE2E` provides deterministic support for offline runs:

- `E2EHTTPClient` mocks app/backend HTTP calls such as `createSession`, `joinSession`, `startArchive`, `stopArchive`, `searchArchives`, and captions enablement.
- `E2ESessionRepository` and `E2ECallFacade` mock the meeting call lifecycle without using the real video SDK session.
- `E2EArchivingDataSource` coordinates mocked archiving state so recording flows can show archives in goodbye.
- Captions use a deterministic caption item: `E2E captions are enabled`.
- `VERA_E2E_FAIL_ENDPOINT` can force one mocked endpoint to fail for diagnostic/error flows.

`VERAApp` decides whether E2E is active and injects the E2E dependencies. The `VERAMeetingRoomSDK` remains independent of `VERAE2E`.

## Installation

Use the provided [install script](../../scripts/install-maestro.sh). It installs Maestro CLI and Java 17:

```bash
./scripts/install-maestro.sh
```

## Folder Structure

```text
.maestro/
├── config.yaml
├── docs/
│   └── README.md
└── flows/
    ├── captions.yaml
    ├── recording.yaml
    └── ...
```

Flows live in `.maestro/flows` and should be named by feature or behavior, for example `recording.yaml` or `captions.yaml`.

## Running Tests

The recommended entrypoint is [`scripts/run-maestro-tests.sh`](../../scripts/run-maestro-tests.sh). It builds the app, boots the simulator, grants camera and microphone permissions, installs the app, runs Maestro, and collects failure logs.

### Offline Mocked Mode

Offline mocked mode is the default. The script passes `VERA_E2E_MOCKS=1` to Maestro.

```bash
# Run all flows with deterministic E2E mocks
./scripts/run-maestro-tests.sh

# Run a single mocked flow by name
./scripts/run-maestro-tests.sh recording.yaml

# Run a single mocked flow by path
./scripts/run-maestro-tests.sh .maestro/flows/captions.yaml
```

### Online Mode

Online mode disables E2E mocks and uses real backend/services. The script passes `VERA_E2E_MOCKS=0`.

```bash
# Run all flows against real services
./scripts/run-maestro-tests.sh --online-mode

# Run a single flow against real services
./scripts/run-maestro-tests.sh --online-mode recording.yaml

# The flag can be passed before or after the flow name
./scripts/run-maestro-tests.sh recording.yaml --online-mode
```

### Simulator Selection

```bash
SIMULATOR_DEVICE="iPhone 17 Pro" ./scripts/run-maestro-tests.sh
```

### Direct Maestro CLI

Direct Maestro runs skip the build/install setup from the script. Pass the required env vars explicitly when flows use `${VERA_E2E_MOCKS}`.

```bash
maestro test \
  --env APP_ID=com.vonage.VERA \
  --env VERA_E2E_MOCKS=1 \
  .maestro/flows/recording.yaml
```

Use `VERA_E2E_MOCKS=0` for direct online mode.

## Logs And Artifacts

Maestro stores flow artifacts under:

```text
~/.maestro/tests/
```

The run script also creates `test-reports/`. If Maestro fails, the script saves simulator logs to:

```text
test-reports/os-simulator.log
```

The CI workflow uploads both Maestro artifacts and `test-reports/`.

## Writing Tests With Accessibility IDs

Tests should target elements using accessibility identifiers. Prefer IDs for actions and use text only when validating user-visible content.

### Example: Validate The Landing Screen

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

### Example: Complete Meeting Flow

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

## Adding Accessibility IDs In SwiftUI

Maestro can miss identifiers applied only to layout wrappers. Apply IDs to visible or interactable nodes whenever possible.

### Screen Anchors

For screen-level assertions, add a tiny invisible anchor inside the screen content.

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

### Buttons

Apply identifiers to the real `Button` or to the component that renders it.

```swift
FilledButton(
    text: Text("Join meeting"),
    accessibilityID: "join-meeting-button",
    onAction: onJoinRoom
)
```

### Text Fields

Apply identifiers directly to the `TextField`.

```swift
TextField("", text: $userName)
    .accessibilityIdentifier("waiting-room-name-field")
```

### Lists And Rows

For list items, put the identifier on the row content that Maestro can see, not only on a parent container. This is important for rows such as archives, where an icon or button may be visible but hidden from the accessibility hierarchy if the ID is too high in the view tree.

```swift
HStack {
    Image(systemName: "video")
    Text(archive.name)
}
.accessibilityIdentifier("archiving-archive-item")
```

> Important: avoid applying `.accessibilityIdentifier()` only to container views such as `Group`, outer `VStack`, or `NavigationView` when Maestro needs to find a concrete element. Use the invisible anchor pattern for screens and direct IDs for controls/items.

## Useful Links

- [Maestro Documentation](https://maestro.mobile.dev)
- [Maestro CLI Commands](https://maestro.mobile.dev/api-reference/commands)
- [Maestro Studio](https://maestro.mobile.dev/getting-started/maestro-studio)
