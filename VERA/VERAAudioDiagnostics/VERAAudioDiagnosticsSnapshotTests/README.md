# VERAAudioDiagnostics Snapshot Tests

Snapshot tests for the VERAAudioDiagnostics module, validating the visual appearance of audio diagnostic UI components.

## What is Tested

### AudioDiagnosticsDialog (10 snapshots)
- iPhone color schemes (Light, Dark)
- iPad color schemes (Light, Dark)
- Playback states (Stopped, Playing)
- Localizations: English and Spanish in both stopped and playing states

### AudioOutputControlPanel (8 snapshots)
- Playback states (Stopped, Playing)
- Color schemes (Light, Dark)
- Localizations: English and Spanish in both stopped and playing states

### AudioDiagnosticsWaitingRoomButton (2 snapshots)
- Color schemes (Light, Dark)

## Running Snapshot Tests

### Run all snapshot tests
```bash
cd VERA
xcodebuild test \
  -workspace VERA.xcworkspace \
  -scheme VERAAudioDiagnosticsSnapshotTests \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -parallel-testing-enabled NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty
```

### Recording new snapshots
1. Open the test file you want to update
2. Set `isRecording = true` in the test suite
3. Run the tests
4. Set `isRecording = false` back
5. Commit the generated snapshots

## Snapshot Storage

Snapshots are stored in `__Snapshots__/` subdirectories:
- `__Snapshots__/AudioDiagnosticsDialogSnapshotTests/` (10 PNGs)
- `__Snapshots__/AudioOutputControlPanelSnapshotTests/` (8 PNGs)
- `__Snapshots__/AudioDiagnosticsWaitingRoomButtonSnapshotTests/` (2 PNGs)

## Test Configuration

All snapshot tests use:
- **Precision**: 0.99 (allows for minor rendering differences)
- **iPhone device**: iPhone 13 (following project convention)
- **iPad device**: iPad Pro 12.9" (following project convention)
- **Fixed layouts**: Used for AudioOutputControlPanel and button tests

## Mocks

`TestHelpers/MockSpeakerTestService.swift` provides a mock implementation of `SpeakerTestService` that:
- Tracks method calls (`playTestSound`, `stopTestSound`)
- Emits controllable audio levels for testing visual states
- Does not require actual audio hardware

## CI Integration

Snapshot tests should be run on CI with a fixed iOS Simulator version (iPhone 17) to ensure consistent snapshots across all environments. Any snapshot failures indicate visual regressions that must be reviewed.
