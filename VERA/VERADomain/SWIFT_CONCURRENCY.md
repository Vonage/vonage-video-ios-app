# VERADomain concurrency readiness

Tracks [proposal #274](https://github.com/Vonage/vonage-video-ios-app/issues/274). Validation is separated from the production conformances in [#275](https://github.com/Vonage/vonage-video-ios-app/pull/275), following maintainer review feedback. Normal Swift 5 defaults and the public package's Swift tools 5.9 minimum remain unchanged.

This validation contribution depends on #275. Its draft targets develop without duplicating the conformances; the Swift 6 tests are expected to fail until #275 merges and this branch is updated from develop. Run the reproduction below with those conformances present, then require both modes and normal CI to pass before merging the validation contribution.

The prerequisite adds checked Sendable conformances to the 11 immutable statistics structs and VideoEffect. Every stored value must remain Sendable as fields are added. This transfers snapshot values; it does not establish ownership of Combine subjects or SDK callback caches. VideoEffect's image-path string is transferable, but no guarantee about concurrent access to the referenced file is added.

The parameterized test transfers both empty and fully populated statistics graphs through 32 concurrent tasks into an actor and checks the values. Existing VideoEffect Codable tests also compile in Swift 6 after its value conformance.

## Reproduce the focused checks

Use installed **Xcode 26.6 / Apple Swift 6.3.3** and an iPhone 17 Simulator. The dedicated workflow selects Xcode 26.6 explicitly and fails clearly if the compiler differs. Generate only this dependency-free module, from the repository root:

```bash
xcodebuild -version
xcrun swiftc --version
tuist generate --path VERA/VERADomain --no-open

# Run once with 5 and once with 6; these are invocation-only overrides.
for language_mode in 5 6; do
  xcodebuild test \
    -workspace VERA/VERADomain/VERADomain.xcworkspace \
    -scheme VERADomainTests \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -derivedDataPath "/tmp/VERADomain-swift-$language_mode" \
    -parallel-testing-enabled NO \
    SWIFT_VERSION="$language_mode" SWIFT_STRICT_CONCURRENCY=complete \
    CODE_SIGNING_ALLOWED=NO RUN_SWIFTLINT=NO COMPILER_INDEX_STORE_ENABLE=NO
done
```

This scheme builds only VERADomain and its tests. It does not force unrelated app or package targets into Swift 6, and no opt-in Tuist helper change is required. Standard CI still checks normal package/app integration, other tests, snapshots and quality gates.

Fresh local verification on 12 October 2026 of the combined production and validation changes reported 57 tests passing in each mode. This is combined local evidence, not a successful Swift 6 run of the validation-only branch on unmodified develop. Current CI results are recorded in the PR description; do not substitute local results for checks of a different head. Current-compiler Swift 5 language mode does not verify an older Swift 5.9 compiler or binary distribution. These checks do not establish real-device media, background or SDK callback behavior. The existing always-true type-test warning is unrelated and remains.
