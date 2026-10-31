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
