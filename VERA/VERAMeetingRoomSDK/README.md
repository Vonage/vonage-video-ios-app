# VERAMeetingRoomSDK

A drop-in, fully composable meeting room SDK for iOS. `VERAMeetingRoomSDK` wraps the entire VERA video call experience — UI, plugins, dependency wiring, and feature overlays — behind a single fluent builder API.

## Overview

Rather than integrating individual feature modules, managing a dependency container, and wiring plugins manually, `VERAMeetingRoomSDK` does all of that for you. You configure a `MeetingRoomBuilder`, call `.build()`, and receive a `MeetingRoomPrebuilt` whose `view` you present directly.

Features (chat, captions, reactions, archiving, screen share, etc.) are enabled **at runtime** via a `Set<MeetingRoomFeature>` — no compile-time flags required.

## Requirements

- iOS 16.0+
- Xcode 26
- Swift 5.9

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Vonage/vonage-video-ios-app", from: "1.0.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "VERAMeetingRoomSDK", package: "vonage-video-ios-app")
    ]
)
```

Or in Xcode: **File → Add Package Dependencies…**, enter the repository URL, and select the `VERAMeetingRoomSDK` library product.

## Quick Start

```swift
import VERAMeetingRoomSDK

let prebuilt = MeetingRoomBuilder(
    baseURL: URL(string: "https://api.example.com/")!,
    roomName: "my-room"
)
.enabledFeatures([.chat, .captions, .reactions, .settings])
.onAction { action in
    switch action {
    case .callDidEnd:
        // Navigate to goodbye screen
    case .goBack(let roomName):
        // Return to waiting room
    }
}
.build()
```

## API Reference

### `MeetingRoomBuilder`

The main entry point. All methods return `self` for fluent chaining.

#### Initializer

```swift
MeetingRoomBuilder(baseURL: URL, roomName: String)
```

#### Configuration Methods

| Method | Description |
|---|---|
| `.enabledFeatures(_ features: Set<MeetingRoomFeature>)` | Defines which optional features are active at runtime. |
| `.onAction(_ handler: @escaping (MeetingRoomSDKAction) -> Void)` | Receives navigation callbacks from the SDK. |
| `.configuration(_ config: MeetingRoomConfiguration)` | Customises the meeting room UI (microphone, camera, participant list controls). |
| `.publisherSettings(_ settings: MeetingRoomPublisherSettings)` | Sets the initial publisher configuration (username, resolution, codec, audio/video flags). |
| `.appGroupIdentifier(_ identifier: String)` | App group for screen share credential storage. Required when `.screenShare` is enabled. |
| `.broadcastExtensionBundleId(_ bundleId: String)` | Bundle ID of the broadcast extension. Required when `.screenShare` is enabled. |
| `.theme(_ theme: MeetingRoomTheme)` | Applies a custom color theme. Defaults to `MeetingRoomTheme.vonage`. |
| `.sessionKeyHolder(_ holder: MeetingRoomSessionKeyHolder)` | Provides an external session key holder for JWT sharing. |

#### Build

```swift
@MainActor
func build() -> MeetingRoomPrebuilt
```

Constructs the full dependency graph, registers plugins, assembles the bottom bar, and returns a ready-to-present `MeetingRoomPrebuilt`.

---

### `MeetingRoomPrebuilt`

The result of `.build()`.

```swift
public struct MeetingRoomPrebuilt {
    public let view: AnyView                           // Fully composed view with all overlays applied
    public let callObserver: MeetingRoomCallObserving   // For observing call state from outside
    public let viewModel: MeetingRoomViewModel        // Internal compatibility API for VERAApp
}
```

Present `view` using a `fullScreenCover`, a `NavigationStack` push, or directly as a child view. Use `callObserver` to observe call state from the host app without importing any sub-modules.

```swift
let cancellable = prebuilt.callObserver.isArchivingPublisher
    .sink { isArchiving in
        print("Archiving changed:", isArchiving)
    }
```

---

### `MeetingRoomFeature`

```swift
public enum MeetingRoomFeature: String, Hashable, Sendable, CaseIterable {
    case chat             // In-call text chat
    case archiving        // Session recording
    case captions         // Live captions overlay
    case reactions        // Emoji reactions with floating animation
    case settings         // In-call settings panel (resolution, codecs, stats)
    case screenShare      // Screen sharing via ReplayKit
    case backgroundEffects // Background blur / virtual backgrounds
    case audioEffects     // Advanced noise suppression
    case callKit          // CallKit integration
}
```

Pass any subset to `.enabledFeatures(_:)`. Only enabled features create dependencies and render UI — disabled features have zero overhead.

---

### `MeetingRoomSDKAction`

Emitted by the SDK via the `onAction` closure. The host app must handle all cases.
Alerts (permission prompts, errors) are presented automatically by the SDK.

```swift
public enum MeetingRoomSDKAction {
    case callDidEnd               // Call ended — navigate to the goodbye screen
    case goBack(String)           // Return to the waiting room (room name)
}
```

---

### `AudioRoutePickerView`

A SwiftUI view that wraps the system `AVRoutePickerView`, allowing users to switch audio output (speaker, Bluetooth, etc.) during a call.

```swift
public struct AudioRoutePickerView: UIViewRepresentable {
    public init()
}
```

You can embed this view anywhere in your UI if you need a standalone audio route picker outside the meeting room.

---

## Screen Share Setup

Screen sharing requires two additional configuration steps:

1. Add an App Group to both your app target and the broadcast extension.
2. Provide the app group identifier and the broadcast extension bundle ID to the builder:

```swift
MeetingRoomBuilder(baseURL: baseURL, roomName: roomName)
    .enabledFeatures([.screenShare])
    .appGroupIdentifier("group.com.yourcompany.yourapp")
    .broadcastExtensionBundleId("com.yourcompany.yourapp.BroadcastExtension")
    .onAction { _ in }
    .build()
```

---

## Sharing State from the Waiting Room

If your app has a waiting room, you can carry user preferences into the call:

```swift
MeetingRoomBuilder(baseURL: baseURL, roomName: roomName)
    .enabledFeatures([.backgroundEffects, .audioEffects])
    .publisherSettings(
        MeetingRoomPublisherSettings(
            username: waitingRoom.username,
            publishAudio: waitingRoom.isMicEnabled,
            publishVideo: waitingRoom.isCameraEnabled
        )
    )
    .onAction { action in handleAction(action) }
    .build()
```

---

## Custom Theming

Override the Vonage color palette to match your brand:

```swift
var theme = MeetingRoomTheme.vonage   // start from defaults
theme.primary = .blue
theme.error = .red
theme.surface = Color(.systemGray6)

MeetingRoomBuilder(baseURL: baseURL, roomName: roomName)
    .theme(theme)
    .onAction { action in handleAction(action) }
    .build()
```

`MeetingRoomTheme` contains all semantic colors (primary, surface, error, accent, text…) plus legacy colors (vGray0–4, videoBackground). When no theme is set, the default Vonage theme is used.

---

## Demo App

`VERAMeetingRoomSDKApp` is a standalone iOS app target that demonstrates minimal SDK integration. It provides:

- A **landing screen** to enter a room name and backend URL.
- A root view that switches between the landing screen and the active `MeetingRoomPrebuilt.view`.
- Action handling that dismisses the meeting room on call end or back navigation.

Run it from the `VERAMeetingRoomSDKApp` scheme in Xcode.

---

## Architecture

`VERAMeetingRoomSDK` acts as a composition root for the following modules:

| Module | Role |
|---|---|
| `VERAMeetingRoom` | Core meeting room UI and business logic |
| `VERAVonage` | Vonage Video SDK adapter |
| `VERACore` | Landing page, waiting room, and common flows |
| `VERACommonUI` | Shared SwiftUI components and theming |
| `VERADomain` | Shared protocols and value types |
| `VERAVonageCallKitPlugin` | CallKit integration |
| `VERAChat` + `VERAVonageChatPlugin` | In-call chat |
| `VERAArchiving` + `VERAVonageArchivingPlugin` | Session recording |
| `VERACaptions` + `VERAVonageCaptionsPlugin` | Live captions |
| `VERAReactions` + `VERAVonageReactionsPlugin` | Emoji reactions |
| `VERASettings` + `VERAVonageSettingsPlugin` | In-call settings |
| `VERAScreenShare` + `VERAVonageScreenSharePlugin` | Screen sharing |
| `VERABackgroundEffects` | Background blur / virtual backgrounds |
| `VERAAudioEffects` | Advanced noise suppression |

The internal `MeetingRoomSDKContainer` lazily instantiates dependencies only for enabled features, and `BottomBarButtonsAssembler` dynamically composes the bottom bar based on the active feature set — all without any `#if` compile-time conditions.
