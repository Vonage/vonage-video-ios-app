# Call and participant ownership

VERA separates UI-owned call controls and renderable participant state from immutable metadata and actor-managed storage. This source preparation retains Swift 5 language defaults. It does not enable Swift 6 for the whole application or establish support for older compilers.

## Integrating call controls

`CallFacade`, publisher/session factories and repositories, native wrappers, and plugin lifecycle operations belong to `MainActor`. Custom implementations and synchronous callers must preserve that owner in both Swift 5 and Swift 6 language modes.

```swift
import VERADomain

@MainActor
final class MeetingController {
    private let call: any CallFacade

    init(call: any CallFacade) {
        self.call = call
    }

    func toggleMicrophone() {
        call.toggleLocalAudio()
    }
}
```

Asynchronous code outside the UI actor can explicitly await a hop:

```swift
func toggleMicrophone(call: any CallFacade) async {
    await MainActor.run {
        call.toggleLocalAudio()
    }
}
```

Do not replace the hop with an unchecked actor assertion. A callback arriving from an SDK or Combine publisher is not guaranteed to run on the UI actor solely because its subscription was created there.

## Integrating participants

Create `Participant` values, access their renderable views, and invoke visibility callbacks on `MainActor`. Immutable metadata, equality, hashing, and aspect-ratio calculations remain accessible without a UI hop. For example, this function reads names without accessing views:

```swift
func participantNames(_ participants: [Participant]) -> [String] {
    participants.map(\.name)
}
```

Custom participant builders and UI actions must retain their declared actor ownership when stored as closures. Metadata transfer does not make native SDK objects, SwiftUI views, or borrowed video frames safe to use on arbitrary threads.

## Runtime boundaries and validation

Session delegate delivery is configured before use. Publisher/subscriber adapters copy callback values into an ordered UI drain; high-frequency updates can be coalesced. Participant and statistics work retains lifetime guards and waits for admitted writes before removal or reset. Native video frames are handled synchronously within their borrowed lifetime.

An app using Swift 6 mode can consume these explicit ownership contracts. An app remaining in Swift 5 mode can also consume them with a supported compiler, but custom implementations or synchronous callers may need actor annotations or explicit asynchronous hops. Language-mode compatibility is separate from support for an older Xcode/Swift compiler.

Compiler checks and simulator tests do not establish real calling behavior. Physical join/leave/reconnect, held-call termination, publisher failure recovery, PiP/ReplayKit, and multiparty/load acceptance remain required before claiming the migration is complete.
