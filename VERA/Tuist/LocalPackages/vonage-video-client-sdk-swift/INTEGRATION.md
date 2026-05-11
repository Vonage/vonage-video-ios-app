# Local Vonage SDK wrapper — integration notes

This directory is a Swift Package wrapper that points `OpenTok` at a
locally-built `OpenTok.xcframework` instead of the upstream signed
binary distributed on S3.

## Why this exists

We need to consume an unreleased SDK build that ships:

1. **Phase 1**: transparent Mac camera support (expanded
   `AVCaptureDevice.DiscoverySession` device types, fallback to
   `.unspecified` position).
2. **Phase 2**: new `OTCameraDevice` enumeration API on `OTPublisher`
   (`availableCameraDevices`, `activeCameraDevice`,
   `setCameraDevice:error:`).

Both ship as additive, non-breaking changes — existing
`cameraPosition` API and KVO behavior are preserved.

Once these changes land in an upstream tagged release, this wrapper
goes away and `Package+Dependencies.swift` reverts to the remote
`.upToNextMinor(from: "2.xx")` form.

## What's checked in

| Path | In git? |
|---|---|
| `Package.swift` | yes |
| `INTEGRATION.md` (this file) | yes |
| `LICENSE`, `NOTICE`, `README.md`, `release-notes.md` | yes (upstream-derived) |
| `Sources/` | yes (upstream Swift overlay sources) |
| `Tests/` | yes |
| `OpenTok.xcframework/` | **no** — gitignored, see below |

The xcframework is large (~73 MB), unsigned, and reproduced from the
SDK source tree on demand. Keeping it out of git preserves repo size
and avoids accidentally shipping an unsigned binary.

## How to obtain the xcframework

Drop a freshly-built `OpenTok.xcframework` into this directory:

```
VERA/Tuist/LocalPackages/vonage-video-client-sdk-swift/OpenTok.xcframework/
```

Source-of-truth path on the SDK builder's machine:

```
/Users/CZoli/coding/native-sdk-src/project/otc-ios/OpenTok.xcframework
```

That tree should contain (verify before dropping):

* `OTSession.h`: `- (nullable id)initWithApplicationId:(nonnull NSString*)applicationId ...`
* `OTPublisher.h`: `@class OTCameraDevice;` plus
  `availableCameraDevices`, `activeCameraDevice`,
  `setCameraDevice:error:` declarations.

If the xcframework you have has the older `initWithApiKey:` only, it's
been built from a pre-rename source tree and won't link against current
VERA — ask the SDK team to rebuild.

## After dropping the xcframework

```bash
cd VERA
tuist clean
tuist install
tuist generate --no-open
```

Then build through Xcode or `xcodebuild build -workspace VERA.xcworkspace -scheme VERA …`.

## App Store note

This wrapper is for local development only. The dropped xcframework is
unsigned, so a release build with `CODE_SIGNING_ALLOWED=YES` and a real
identity will fail. Swap `Package+Dependencies.swift` back to the
remote URL form before cutting an App Store build.
