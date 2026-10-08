import Testing

@testable import VERACore

@Suite("App version display tests")
struct AppVersionDisplayTests {
    @Test("Formats app and SDK versions like the web footer")
    func formatsVersions() {
        #expect(AppVersionDisplay.versionText(appVersion: "1.3", sdkVersion: "2.35.1") == "v1.3 (SDK 2.35.1)")
    }

    @Test("Uses a visible fallback when a version is unavailable")
    func formatsMissingVersions() {
        #expect(AppVersionDisplay.versionText(appVersion: nil, sdkVersion: nil) == "vUnknown (SDK Unknown)")
    }
}
