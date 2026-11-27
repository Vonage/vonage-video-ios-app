# VERAScreenShare

Screen sharing feature for VERA. iOS 27 presents Apple's system content picker and captures with ScreenCaptureKit inside the app. Earlier iOS versions use a ReplayKit Broadcast Upload Extension.

## Overview

Screen sharing in VERA involves three modules working together:

| Module | Role |
|--------|------|
| **VERAScreenShare** | UI components and credential storage (this module) |
| **VERAVonageScreenSharePlugin** | Vonage plugin that saves/clears credentials on call lifecycle |
| **BroadcastExtension** | ReplayKit Broadcast Upload Extension that captures and publishes the screen on iOS 17–26 |

### Credential flow

1. When a call connects, `VonageScreenSharePlugin.callDidStart(_:)` saves the `applicationId`, `sessionId`, and `token` to the shared App Group `UserDefaults`.
2. When the user taps the screen share button, iOS launches the Broadcast Upload Extension in a separate process.
3. `BroadcastSampleHandler.broadcastStarted(withSetupInfo:)` reads credentials from the same App Group via `UserDefaultsScreenShareCredentialsStore` and connects to the Vonage session.
4. When the call ends, `callDidEnd()` clears credentials and sends a Darwin notification to stop the extension.

### iOS 27

When ScreenCaptureKit is available, the same toolbar button presents `SCContentSharingPicker` instead of the ReplayKit picker. The plugin publishes the picked frames with `OTPublisherKit` on a second Vonage session. Credentials are still saved so a ReplayKit extension can run on older systems. The app's Info.plist includes `NSScreenCaptureUsageDescription` and the `screen-capture` background mode.

## BroadcastExtension (Broadcast Upload Extension)

Located in `VERAApp/BroadcastExtension/`, the extension runs as a separate process with a ~50 MB memory ceiling.

### Key files

| File | Description |
|------|-------------|
| `BroadcastSampleHandler.swift` | `RPBroadcastSampleHandler` entry point — reads credentials, connects `OTSession`, publishes via `OTPublisherKit` |
| `ScreenShareVideoCapturer.swift` | Custom `OTVideoCapture` that feeds ReplayKit frames to the Vonage SDK |

## Tests

### Schemes and targets

| Scheme | Target | Platform | Contents |
|--------|--------|----------|----------|
| `VERAScreenShareTests` | `VERAScreenShareTests` | macOS, iOS | Tests for `UserDefaultsScreenShareCredentialsRepository` and `UserDefaultsScreenShareCredentialsStore` |
| `BroadcastExtensionTests` | `BroadcastExtensionTests` | macOS, iOS | Tests for `UserDefaultsScreenShareCredentialsStore` (includes source directly since app extensions can't be `@testable import`ed) |
| `VERAVonageScreenSharePluginTests` | `VERAVonageScreenSharePluginTests` | iOS | Tests for `VonageScreenSharePlugin` |

## Feature flag

Screen sharing is enabled via `app-config.json`:

```json
{
  "meetingRoomSettings": {
    "allowScreenShare": true
  }
}
```

When enabled, the `.screenShare` case is added to the app's `MeetingRoomFeature` set at runtime (`DependencyContainer.meetingRoomEnabledFeatures`), and `Project.swift` adds the `BroadcastExtension` app-extension target as a dependency at `tuist generate` time. `VERAScreenShare` and `VERAVonageScreenSharePlugin` are always linked via `VERAMeetingRoomSDK`.
