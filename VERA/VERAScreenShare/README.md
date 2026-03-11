# VERAScreenShare

Screen sharing feature for VERA, enabling participants to broadcast their device screen into a Vonage video call using Apple's ReplayKit framework.

## Overview

Screen sharing in VERA involves three modules working together:

| Module | Role |
|--------|------|
| **VERAScreenShare** | UI components and credential storage (this module) |
| **VERAVonageScreenSharePlugin** | Vonage plugin that saves/clears credentials on call lifecycle |
| **BroadcastExtension** | ReplayKit Broadcast Upload Extension that captures and publishes the screen |

### Credential flow

1. When a call connects, `VonageScreenSharePlugin.callDidStart(_:)` saves the `applicationId`, `sessionId`, and `token` to the shared App Group `UserDefaults`.
2. When the user taps the screen share button, iOS launches the Broadcast Upload Extension in a separate process.
3. `BroadcastSampleHandler.broadcastStarted(withSetupInfo:)` reads credentials from the same App Group via `UserDefaultsScreenShareCredentialsStore` and connects to the Vonage session.
4. When the call ends, `callDidEnd()` clears credentials and sends a Darwin notification to stop the extension.

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

When enabled, `Project.swift` sets `SCREEN_SHARE_ENABLED` as a Swift active compilation condition and includes `VERAScreenShare`, `VERAVonageScreenSharePlugin`, and `BroadcastExtension` as dependencies.
