# Localization

The app is fully prepared for internationalization using Xcode's **String Catalogs** (`.xcstrings`). All user-facing strings are localized through this mechanism.

## How It Works

The `SWIFT_EMIT_LOC_STRINGS` build flag is enabled across all modules. During compilation, Xcode automatically scans Swift source files for localizable strings and keeps the `.xcstrings` catalog in sync. You do not need to manually register new strings — the build system detects them.

## Adding a New Language

1. Open the root `Project.swift` and add the desired locale code to the `defaultKnownRegions` property:

    ```swift
    defaultKnownRegions: ["en", "es", /* add new locale here */]
    ```

2. Build the project. The `SWIFT_EMIT_LOC_STRINGS` flag causes each String Catalog to be updated automatically with any new localizable strings discovered during compilation.

3. Open the generated `.xcstrings` catalog and provide translations for the new locale.

## Adding Localizable Strings

Use `String(localized:)` or `LocalizedStringKey` in Swift/SwiftUI. The build system picks these up automatically during the next build:

```swift
// Swift
let title = String(localized: "welcome.title")

// SwiftUI
Text("welcome.title")
```

String keys should be descriptive and scoped to their screen or feature to avoid collisions (e.g., `waitingRoom.joinButton`, `meetingRoom.endCallButton`).

## Notes

- Localized strings live in `.xcstrings` files alongside their module source.
- Never hard-code user-visible strings outside of string catalogs.
- Since `SWIFT_EMIT_LOC_STRINGS` is active, stale or missing keys are surfaced at build time.
