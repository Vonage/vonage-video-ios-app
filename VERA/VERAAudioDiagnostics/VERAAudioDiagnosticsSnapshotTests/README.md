# VERAAudioDiagnostics Snapshot Tests

Snapshot tests for the VERAAudioDiagnostics module, validating the visual appearance of audio diagnostic UI components.

## What is Tested

### AudioDiagnosticsDialog
- Device layouts (iPhone 13, iPhone 13 Pro Max, iPhone SE)
- Color schemes (Light and Dark mode)
- Playback states (Stopped, Playing with different audio levels)
- Localizations (English and Spanish)
- iPad layouts (iPad Pro 11", iPad Pro 12.9")
- Compact width and standard height variations

### AudioOutputControlPanel
- Playback states with various audio levels (0.0 to 1.0)
- Color schemes in both stopped and playing states
- English and Spanish localization
- Audio level step variations
- Compact width and wide layout

### AudioDiagnosticsWaitingRoomButton
- Color schemes (Light and Dark mode)
- Default size
- In horizontal stack layout
- Different background colors

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
1. Open `AudioDiagnosticsDialogSnapshotTests.swift`
2. Set `isRecording = true` in the test suite
3. Run the tests
4. Set `isRecording = false` back
5. Commit the generated snapshots

## Snapshot Storage

Snapshots are stored in `__Snapshots__/` subdirectories:
- `__Snapshots__/AudioDiagnosticsDialogSnapshotTests/`
- `__Snapshots__/AudioOutputControlPanelSnapshotTests/`
- `__Snapshots__/AudioDiagnosticsWaitingRoomButtonSnapshotTests/`

## Test Configuration

All snapshot tests use:
- **Precision**: 0.99 (allows for minor rendering differences)
- **Device configs**: iPhone 13, iPhone SE, iPad Pro 11", iPad Pro 12.9"
- **Fixed layouts**: Used for component-specific tests
- **Device layouts**: Used for full-screen dialog tests

## Mocks

`TestHelpers/MockSpeakerTestService.swift` provides a mock implementation of `SpeakerTestService` that:
- Tracks method calls (`playTestSound`, `stopTestSound`)
- Emits controllable audio levels for testing visual states
- Does not require actual audio hardware

## CI Integration

Snapshot tests should be run on CI with a fixed iOS Simulator version to ensure consistent snapshots across all environments. Any snapshot failures indicate visual regressions that must be reviewed.
