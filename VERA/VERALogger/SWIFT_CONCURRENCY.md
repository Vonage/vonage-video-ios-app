# VERALogger concurrency readiness

Tracks [proposal #274](https://github.com/Vonage/vonage-video-ios-app/issues/274). Maintainer discussion is pending; this contribution preserves the normal Swift 5 defaults and the public package's Swift tools 5.9 minimum.

The private formatter configuration is fixed after initialization. File existence, rotation and append are protected by one FileLogStrategy instance's lock. Use one instance per output URL: different instances writing the same URL do not share that lock.

The regression tests exercise 256 concurrent formatter calls and 256 appends, checking complete distinct lines. Existing unchecked contracts are documented rather than treated as compiler-verified safety; no unchecked declaration or new dependency is added.

## Reproduce the focused checks

Use installed **Xcode 26.6 / Apple Swift 6.3.3** and an iPhone 17 Simulator. The dedicated workflow selects Xcode 26.6 explicitly and fails clearly if the compiler differs. Generate only this dependency-free module, from the repository root:

```bash
xcodebuild -version
xcrun swiftc --version
tuist generate --path VERA/VERALogger --no-open

# Run once with 5 and once with 6; these are invocation-only overrides.
for language_mode in 5 6; do
  xcodebuild test \
    -workspace VERA/VERALogger/VERALogger.xcworkspace \
    -scheme VERALoggerTests \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -derivedDataPath "/tmp/VERALogger-swift-$language_mode" \
    -parallel-testing-enabled NO \
    SWIFT_VERSION="$language_mode" SWIFT_STRICT_CONCURRENCY=complete \
    CODE_SIGNING_ALLOWED=NO RUN_SWIFTLINT=NO COMPILER_INDEX_STORE_ENABLE=NO
done
```

This scheme builds only VERALogger and its tests. It does not force unrelated app or package targets into Swift 6, and no opt-in Tuist helper change is required. Standard CI still checks normal package/app integration, other tests, snapshots and quality gates.

The completed local pilot reported 40 tests passing in each mode. Extracted-branch evidence and current CI results are recorded in the PR description; do not substitute pilot results for checks of a different head. Current-compiler Swift 5 language mode does not verify an older Swift 5.9 compiler or binary distribution. These checks do not establish real-device media, background or SDK callback behavior. Thread Sanitizer and multiple file-strategy instances sharing a URL have not been validated.
