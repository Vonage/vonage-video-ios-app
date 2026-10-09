# Localization

The app is fully prepared for internationalization using Xcode's **String Catalogs** (`.xcstrings`). User-facing translations are stored in this mechanism.

## How It Works

The `SWIFT_EMIT_LOC_STRINGS` build flag is enabled across all modules. During compilation, Xcode automatically scans Swift source files for localizable strings and keeps the `.xcstrings` catalog in sync. You do not need to manually register new strings — the build system detects them.

## Adding a New Language

1. Update `supportedLanguages` in `VERA/Tuist/ProjectDescriptionHelpers/BuildSettingsConfig.swift` and the corresponding catalogs:

    ```swift
    supportedLanguages: ["en", "en-US", "de", "it", "es", "es-MX", "ja"]
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

## Language selection and translation sources

VERA iOS offers System Default, English, English (US), Deutsch, Italiano,
Español, Español (México), and 日本語. Country flags, choices and ordering match the web
app's language selector. English (US) reuses English wording, as on the web;
regional choices retain their own locale for formatting.

System Default checks the device's preferred languages in order, first matching
an available regional variant, then its base language. If none match, it uses
English. The explicit choice is stored separately from publisher preferences.
Reset to Defaults returns it to System Default.

Matching translations come from
[the web app's develop resources](https://github.com/Vonage/vonage-video-react-app/tree/77c9b91e844fbd76acca1fb22d31bccda56f9510/frontend/src/locales).
Catalog comments identify the corresponding web key. Copying is limited to
wording that has the same meaning on iOS; descriptions of browser-specific
behavior are not reused for native controls. Web placeholders are adapted to
the native printf argument types and order.

New translations for iOS-only wording are drafts marked `needs_review` in the
catalogs and should receive linguistic review. Spanish translations already
present are retained where applicable, with mismatched formatting arguments
corrected. Future languages or strings must be added consistently to every
module's catalog, the Tuist language declaration and `AppLanguage`.

Run `python3 scripts/validate-localizations.py` to check full catalog coverage,
format argument compatibility and language declarations. Common UI language
tests cover persistence, reset, regional matching, English fallback, observation,
and resource selection for each shipped language.

Runtime code uses `AppLanguageStore` for resource selection and sets the SwiftUI
locale at the app root. Foundation `String(localized:)` callers must pass
`localizedBundle(in:)`; passing `locale:` alone only changes formatting and does
not select the requested language's resources. Do not use translated strings as
model identifiers or cache translated titles in static constants.
