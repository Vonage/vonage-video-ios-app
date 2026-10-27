# iOS initial connection recovery

Prerequisites: open PR #263 (cancellable initial connection and idempotent terminal teardown).
The integration base also includes #259 (publisher error forwarding) and #260 (serialized publisher replacements)
for the subsequent publisher slice. These existing PRs must merge before retargeting/rebasing the recovery work
onto develop. Do not independently reimplement or merge their changes through this series.

Initial join failures in OTSessionErrorDomain with codes 1006, 1020, 1021, 1023 or 1503 are candidates for
three total attempts. The delay is 3 seconds then 6 seconds. Each failed native session is detached,
disconnected and replaced; credentials are resolved again. Authorization, configuration, capacity,
unknown errors and failures resolving credentials are not automatically retried.

SDK-managed reconnect of an established session is unchanged. A terminal failure after connection still
terminates the call. Cancellation, stale session callbacks and hangup may not start a later connection.
The caller-facing connect method retains its asynchronous-handshake semantics: returning means the SDK
attempt started, not that the session is connected. Exhausted asynchronous failures reach call events.

References:
- https://developer.vonage.com/en/opentok/sdks/ios/reference/constants/otsessionerrorcode
- SDK 2.35.1 OTError.h and OTSession.h

## Publisher recovery

Additional prerequisites: #259 (asynchronous publisher error delivery) and #260 (serialized,
cancellation-aware settings replacements). The publisher recovery slice also depends on the
connection slice for shared recovery scheduling and terminal cancellation.

The application allowlists only native publisher WebRTC failure 1610 in OTPublisherErrorDomain
for bounded recreation (three failed publish attempts, with 3/6 second backoff). Other errors,
including disconnected session, internal failure, encryption, invalid scalability and foreign
domains, are surfaced without automatic retry. No automatic publisher recreation runs during
SDK reconnect or while held. SDK error descriptions and physical-device behavior still need
verification in live acceptance; a WebRTC category is not proof every underlying failure is transient.

Recreation uses the existing serialized settings queue, checks the failed publisher identity
again after queued work, cancels on hangup, and reinstalls callbacks. Initial advanced settings,
mute state, camera position and transforms are retained. Runtime camera/transform state is restored
before publishing replacement media. Only the SDK stream-created callback resets the retry budget.

## Subscription recovery

Depends on the connection and publisher slices for terminal cancellation and shared scheduling.
Only timeout 1542 in OTSubscriberErrorDomain is retried, as recommended in SDK 2.35.1 OTError.h.
Every stream owns its own three-attempt budget and generation. A fresh subscriber is created after
the failed attempt has been cleaned up and unsubscribed. Stream availability is read from the native
session immediately before each attempt; destroyed streams, replaced generations, and terminal calls
cancel pending work. Duplicate stream events cannot start duplicate subscriptions. Permanent, missing
stream, encryption and unknown failures do not retry. Success is confirmed by the subscriber delegate.

SDK reconnect suppresses application subscription attempts; after reconnect, still-available streams
without an existing workflow may start a new workflow. Normal SDK-managed subscribers retain their
workflows. Synthetic lifetime tests exercise the scheduling coordinator; live stream negotiation,
media output and physical network migration are separate acceptance checks.

Reference: https://developer.vonage.com/en/opentok/sdks/ios/reference/constants/otsubscribererrorcode
