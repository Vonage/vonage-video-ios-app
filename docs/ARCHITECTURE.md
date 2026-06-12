# Architecture

The Vonage Video iOS Reference App is organized as a multi-module Xcode workspace managed entirely by [Tuist](https://tuist.dev). This document describes the module graph, the Clean Architecture layers used within each module, and the key design patterns.

## Module Graph

```
VERAApp              – Composition root; DependencyContainer wires all modules together
VERADomain           – Shared protocols, entities, and value types (no SDK imports)
VERACore             – Main UI + business logic (Landing, WaitingRoom, GoodBye flows)
VERAMeetingRoom      – Meeting room feature; depends on VERADomain + VERACommonUI
VERAVonage           – Vonage Video SDK adapter layer + ActiveSpeakerTracker
VERACommonUI         – Shared SwiftUI components and theme assets
VERAConfiguration    – AppConfig model generated from app-config.json
```

### Optional Feature Modules

These modules are compiled only when the corresponding feature flag is enabled in `app-config.json` (see [Configuration](CONFIGURATION.md)):

| Module | Plugin |
|---|---|
| VERAChat | VERAVonageChatPlugin |
| VERAArchiving | VERAVonageArchivingPlugin |
| VERABackgroundEffects | — |
| VERACaptions | VERAVonageCaptionsPlugin |
| VERAReactions | VERAVonageReactionsPlugin |
| VERASettings | VERAVonageSettingsPlugin |
| VERAScreenShare | VERAVonageScreenSharePlugin |
| VERAAudioEffects | — |
| VERAVonageCallKitPlugin | — (always included) |

## Layer Structure within Modules

Feature modules follow Clean Architecture with a strict dependency rule — inner layers never depend on outer layers.

```
Domain/              ← Innermost layer (pure business logic, no framework imports)
  Entities/          – Value types, domain models
  Repositories/      – Protocol definitions (interfaces only)
  DataSources/       – Protocol definitions for data access
  Services/          – Domain service protocols
  Use cases/         – Application-specific business rules

Data/                ← Outer layer (implements Domain protocols)
  Repositories/      – Concrete repository implementations
  DataSources/       – HTTP, UserDefaults, or in-memory data sources
  Mappers/           – DTO ↔ domain model mapping

UI/                  ← Outer layer (presentation)
  View/              – SwiftUI views (*Screen coordinator + *View stateless)
  View models/       – @MainActor ObservableObject classes
  Components/        – Screen-specific reusable UI components

Utils/               – Helper extensions and utilities (optional)
Wireframe/           – Factory classes that wire Domain + Data + UI together
```

**Dependency rule:**
- `Domain/` must **not** import anything from `Data/`, `UI/`, or `Wireframe/`.
- `Data/` depends on `Domain/` but never on `UI/`.
- `UI/` depends on `Domain/` but never on `Data/` directly.
- `Wireframe/` is the composition point — it knows all layers and wires concrete `Data/` implementations into `Domain/` protocol slots consumed by `UI/` view models.

## Dependency Injection

`DependencyContainer` in `VERAApp` is the single composition root. All repositories, use cases, and plugins are lazy properties instantiated here. No other module creates concrete dependencies — all inter-module communication goes through protocols defined in `VERADomain`.

## Plugin Pattern

Optional features integrate with the Vonage session through the `VonagePlugin` protocol (`VonagePluginCallLifeCycle & VonagePluginID`). Plugins are registered on `VonagePluginRegistry` inside `DependencyContainer` and are passed to `VonageSessionRepository`. They receive `callDidStart(_:)` / `callDidEnd()` lifecycle callbacks and can hold a `VonageSignalChannel` to emit signals.

## Screen Construction (Factory / Wireframe Pattern)

Each flow uses a `XxxFactory` class (in a `Wireframe/` folder) that constructs the `ViewModel` and the SwiftUI `View` as a pair:

```swift
let (view, viewModel) = meetingRoomFactory.make(roomName:getExternalButtons:onActionHandler:)
```

Factories receive all dependencies through their initializer from `DependencyContainer`.

## Multi-Platform Targets

Core framework modules (`VERACore`, `VERAMeetingRoom`, `VERADomain`, `VERACommonUI`, `VERAConfiguration`, `VERASettings`, `VERAScreenShare`) target both **iOS 16+** and **macOS 14.6+**, enabling fast unit-test runs on macOS without a simulator.

iOS-only modules include anything using the Vonage SDK, UIKit, or VonageVideoTransformers (e.g., `VERAVonage`, `VERAAudioEffects`, all plugin modules).

## BroadcastExtension (Screen Sharing)

`VERAVonageScreenSharePlugin` includes a `BroadcastExtension` app extension target that uses ReplayKit's Broadcast Upload Extension API. The extension source lives in `VERAApp/BroadcastExtension/`.

## Backend Integration

The app requires a running backend for session management. The backend communicates with the Vonage Video platform using the Vonage Server SDK and generates session IDs and tokens. See [vonage-video-react-app](https://github.com/Vonage/vonage-video-react-app) for backend deployment instructions.
