# Swift 6 integration and language modes

This document accompanies the final activation change. Merge that change only
with the SDK/UI and authentication ownership prerequisites. A successful compiler
check does not replace device acceptance of a video call.

## Compiler versus language mode

The validation toolchain is Xcode 26.6 with Swift 6.3.3. Swift 6.4 has not been
validated by this migration. The package manifest requires Swift tools 6.0;
that minimum allows the manifest to select language modes, and is not a claim
that every older Swift 6 compiler or Xcode version has been tested.

The app and package default to Swift 6 language mode after activation. The same
owned source can also build in Swift 5 language mode on the validated compiler.
This does not establish support for Swift 5.x compilers or older Xcode releases.
Third-party packages retain their own language settings and compatibility limits.

## Customers already using Swift 6

Import `VERAMeetingRoomSDK` as a separate package module. Create the meeting UI
on `MainActor`, and preserve the documented ownership of custom factories,
participants and UI callbacks. A type being `Sendable` does not make a borrowed
SDK frame, view or arbitrary callback safe on any thread.

```swift
import Foundation
import VERAMeetingRoomSDK

@MainActor
func configureMeeting(baseURL: URL, roomName: String) -> MeetingRoomBuilder {
    MeetingRoomBuilder(baseURL: baseURL, roomName: roomName)
        .enabledFeatures([.chat, .captions, .reactions])
}
```

See [call and participant ownership](SWIFT6_OWNERSHIP.md) for explicit asynchronous
hops and custom implementation requirements. Authentication browser and credential
operations also belong to `MainActor`; asynchronous token requests and sign-out
can be awaited from outside that actor.

## Customers keeping their app in Swift 5 mode

With a supported compiler, keep your app target in Swift 5 mode and consume the
separate Swift 6 package module. Swift language modes are selected per module;
importing a Swift 6 module does not switch the app target into Swift 6.

The API's actor requirements still matter. Keep UI setup on `MainActor` and await
cross-actor operations. Copying VERA source into your own target uses that target's
language settings and dependencies, so validate the copied code in your project.
The dual-mode CI is compatibility evidence, not a promise that arbitrary existing
customer code needs no changes.

For a local Tuist build in Swift 5 mode:

```bash
cd VERA
TUIST_SWIFT_LANGUAGE_MODE=5.0 tuist generate --no-open
```

For Swift 6, omit the override or set it to `6.0`. Regenerate when changing modes;
both Debug and Release inherit the generated selection. The root Swift package
defaults to Swift 6 independently. In its disposable checkout, the package CI job
runs `python3 scripts/select-package-language-mode.py 5.0` to change only the
package's language-mode declaration; the two customer test targets retain their
explicit modes. This avoids counting a cached Xcode manifest as a fallback check.
Use `6.0` to restore the package default. Consumers normally keep VERA's default
and select the host app's own language mode instead.

## Validation and acceptance

CI compiles and tests owned Tuist modules in modes 5 and 6 with complete concurrency
checking, compiles the app and broadcast extension in both modes, and builds the
Swift package in both modes. Separate Swift 5 and Swift 6 public API consumer test
targets compile against the package. Snapshot tests run once in Swift 6 mode;
the existing Maestro workflow exercises the default app mode.

A green CI result establishes only the checks it actually ran. Before declaring
the migration complete, validate physical-device join/leave/reconnect, held-call
termination, publisher failure recovery, PiP/ReplayKit and multiparty/load behavior.
Track pending checks rather than claiming compiler success proves runtime safety.

Official background: [Swift migration guide](https://www.swift.org/migration/),
[version compatibility](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/compatibility/).
