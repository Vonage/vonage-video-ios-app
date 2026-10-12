# Collector state extraction

Related proposal: [#274](https://github.com/Vonage/vonage-video-ios-app/issues/274).

`NetworkStatsCollector` currently combines SDK delegate mapping, cached domain
values, RTC JSON parsing and synchronous snapshot publication. This contribution
extracts the cached values and snapshot construction into `NetworkStatsState`,
and RTC codec lookup into `NetworkStatsCodecReport`. Both are internal components;
public collector signatures remain unchanged.

The state tests use domain values without constructing SDK publishers or
subscribers. The existing SDK mapping tests remain intact. Separate delivery
tests exercise the real collector subject with reset and unknown removal.

## Preserved behavior

- SDK objects are read and RTC requests are made synchronously on the existing
  delegate callers. Subscriber creation and cached codec resolution precede an
  unresolved-codec request; receive-stat assignment and emission follow it.
- Reset immediately sends `.empty`; removal immediately emits the current
  snapshot. Repeated resets and unknown removals still emit. Subject callbacks
  may reenter the collector.
- Subscriber names are captured on first insertion. Dictionary keys, including
  empty IDs, preserve their existing collision behavior. Removal clears cached
  data; reinsertion appends to insertion order. RTC reports do not create unknown
  subscribers.
- Publisher name is still read only from nonempty video statistics callbacks.
  SDK video-layer mapping, sorting and deduplication remain in the collector.
  Publisher primary codec fallback continues to distinguish nil from empty.
- RTC lookup uses the last codec entry for a duplicate ID and visits matching RTP
  entries in report order. Publisher audio uses the last matching audio codec.
  Subscriber video keeps a nonempty existing codec ahead of an RTC fallback.
- Malformed JSON skips backpatching but the delegate still emits. Valid reports
  without matching codecs still backpatch from cached values. Existing backpatch
  field choices, including omission of receive `senderStats`, are unchanged.

## Scope and follow-up

This is a behavior-preserving extraction, not a synchronization or Swift 6 fix.
The cache remains unprotected, as on develop. No locks, emission queues, tasks,
source generations, actor annotations or diagnostic suppressions are introduced.
No SDK objects enter extracted state or move to another executor.

Publication/reset acknowledgement policy and source identity for late callbacks
need separate agreement and contributions. This branch has no dependency on
unmerged Domain, Logger, statistics teardown or repository-ownership changes.

## Validation

Run the settings plugin iOS test scheme, retaining `NetworkStatsCollectorTests`
alongside the new state, report and delivery suites. For a local run avoiding SDK
publisher construction, select `NetworkStatsStateTests`,
`NetworkStatsCodecReportTests`, `NetworkStatsEmissionTests` and
`VonageSettingsPluginTests`.

Build the iOS app/extension and public package, and compare Swift 5 complete
concurrency diagnostics against the unchanged develop collector. Passing these
checks does not establish a live SDK callback race guarantee or Swift 6 readiness.
