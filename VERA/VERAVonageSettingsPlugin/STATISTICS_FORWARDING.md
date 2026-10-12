# Statistics forwarding teardown

`VonageSettingsPlugin` uses an internal actor to order statistics source setup,
replacement, and final clear. This does not add actor isolation or Sendable
requirements to public plugin or writer protocols.

## Ordering

Each request returns a task after it has been submitted to the actor's queue.
The next operation awaits its predecessor even if a caller cancels that task.
Stopping cancels forwarding, awaits its completion, and then clears the writer.
Replacing a source follows the same drain/clear sequence before subscribing to
its replacement. Operations submitted while a clear is suspended wait for it.

Cancellation alone cannot abort an arbitrary already-awaited `updateStats`.
A custom writer must finish its awaited write (and clear) for teardown and
subsequent starts to finish. There is intentionally no timeout that would permit
an old write to complete after clear. The default repository performs finite
actor-isolated writes. A writer must not await the same plugin lifecycle
request from inside its write/clear, since that request waits for the writer;
independently queued callbacks are fine.

## Ownership and scope

The forwarding task captures the writer and source, not the lifecycle owner or
plugin. Owner deinitialization cancels idle forwarding; explicit call end is
still required for a final clear. An in-flight writer is retained until it
returns. This is independent of Domain Sendable readiness, the staged repository
relay, and publisher replacement/connection teardown PRs.

The actor orders requests as they reach it. Public lifecycle callbacks do not
carry call IDs; this does not identify an arbitrarily delayed end callback from
an older call arriving after a newer start. Nor does it serialize all settings
subscriptions/call-holder mutation or fix collector cache ownership. The existing
Combine `publisher.values` behavior is retained; this does not guarantee delivery
of every SDK event during a suspended write.

## Validation

Continuation barriers hold a cancellation-ignoring writer in an update. Tests
verify update-before-clear, new-source ordering behind a pending write and clear,
source replacement/unsubscription, repeated stop, cancelled stop handles, stop
without start, and idle owner release. A plugin-level test also verifies normal
end-then-rejoin use. None assumes MainActor lifecycle callbacks or sleeps.

The separate saved develop reproduction waits for end while keeping a write
suspended, then releases it. Develop records `clear, update`, demonstrating the
bug. The fixed teardown necessarily waits for that write, so fixed regressions
release it after cancellation and assert the final ordering instead.

Normal Swift 5, tools-5.9 minimum, SDK versions, platform floors, and public
signatures are unchanged. This behavior fix does not claim that the plugin or
its non-Sendable imported values/publishers are ready for Swift 6 mode.

An opt-in Swift 5 / complete-concurrency framework build succeeds both before and
after the fix. Affected-module diagnostics change from three to four: the old
forwarding-task transfer diagnostic is replaced by publisher transfer into the
actor and actor-to-detached-task transfer diagnostics. The existing two publisher
settings task diagnostics remain. `StatsWriter` is already Sendable and adds no
writer-transfer diagnostic. No suppressions or unchecked declarations were added;
this independent Swift 5 fix leaves those imported publisher/value boundaries for
subsequent readiness work.
