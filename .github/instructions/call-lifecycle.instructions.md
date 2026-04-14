---
applyTo: "VERA/**/VERAVonageCallKitPlugin/**/*,VERA/**/VERAVonage/**/*"
---

## Call lifecycle and media rules

### State machine
- `CallState` follows a strict linear flow: `idle → connecting → connected → disconnecting → disconnected`.
- Never skip states (e.g., do not go from `connecting` straight to `disconnected`).
- State is emitted via `_callState` (`CurrentValueSubject`). Consumers observe `callState: AnyPublisher<CallState, Never>`.
- Guard on the current state before mutating — `disconnect()` must verify `.connected` first.

### Cleanup ordering
- `VonageCall.disconnect()` performs cleanup in a specific sequence — preserve this order:
  1. `callStateManager.cleanUpParticipants()` — remove all subscribers
  2. `notifyCallDidEndToPlugins()` — async, via `withTaskGroup` (all plugins concurrently)
  3. `unassignPlugins()` — clear plugin call/channel references
  4. Cancel all Combine subscriptions (`cancellables`, `subscriberCancellables`, `publisherCancellables`)
  5. `session.disconnect()` — OTSession teardown
  6. `publisher.cleanUp()` / `session.cleanUp()` — release SDK objects and nil out callbacks
  7. Transition to `.disconnected`
- The same cleanup path (steps 5–7) must also execute in the `catch` block to avoid leaks on error.

### Subscriber lifecycle
- Cancel the keyed `subscriberCancellables[streamId]` **before** calling `callStateManager.removeSubscriber` — otherwise the `$participant` sink can re-add the participant during removal.
- `VonageSubscriber.cleanUp()` must nil out `onError`, `onCaption`, `onConnected` closures and cancel the visibility debounce task.

### Threading
- `CallStateManager` is an `actor` — all participant mutations are serialized there. Never bypass it with direct array access.
- `@Atomic` (concurrent queue + barrier) is used for `subscriberDidConnect` and `visibilityCount` on `VonageSubscriber`. Use `@Atomic` for any new subscriber-level mutable state.
- `@MainActor` is required for `doSubscribe(_:)` and `applyPublisherAdvancedSettings(_:)` — OTSubscriber/OTPublisher creation must happen on the main thread.

### Publisher republish cycle
- When applying advanced settings (`applyPublisherAdvancedSettings`), the publisher is destroyed and recreated:
  1. Capture runtime state (audio/video mute, camera position, transformers, stats delegate)
  2. Cancel observation sinks before cleanup
  3. Unpublish → `Task.yield()` → recreate → re-publish
  4. Restore all captured state
- If adding new publisher state, make sure it is captured and restored in this flow.

### Plugin protocol
- Plugins implement `VonagePlugin` (`VonagePluginCallLifeCycle & VonagePluginID`).
- `callDidStart(_:)` receives `userInfo` dict with `roomName` and `callID` keys (`VonageCallParams` enum).
- `callDidEnd()` must be idempotent — plugins may be called even if `callDidStart` was never reached.
- Plugins implementing `VonageSignalEmitter` get a `channel: VonageSignalChannel?` for emitting signals. The channel is set/cleared by `VonageCall` — plugins must not retain it beyond the call lifecycle.
- Plugins implementing `VonageSignalHandler` receive `handleSignal(_:)` for incoming signals routed from the session.

### Hold and interruptions
- Hold preserves audio/video subscription state in `wasSubscribedToAudio`/`wasSubscribedToVideo` on each subscriber and restores it on unhold. Do not reset these flags outside of the hold flow.
- `VonageCallKitPlugin` bridges CXCallController actions (`end`, `hold`, `mute`) to `CallFacade` methods. The `onEndCall` closure ignores end-call while on hold — do not remove this guard.

### Visibility-driven bandwidth
- `VonageSubscriber` uses `onAppear`/`onDisappear` callbacks with a 500ms debounce to toggle `subscribeToVideo`. Changes to this debounce or visibility logic affect bandwidth for all participants.

### Reconnection
- Reconnection events (`didBeginReconnecting`, `didReconnect`) are forwarded via `SessionEvent` enum through `_eventsPublisher`. Do not change state to `.disconnected` during reconnection — the session handles recovery internally.
