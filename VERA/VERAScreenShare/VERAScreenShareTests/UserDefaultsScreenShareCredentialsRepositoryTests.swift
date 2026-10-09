//
//  Created by Vonage on 6/3/26.
//

import Foundation
import Testing
import VERAScreenShare

@Suite("UserDefaults Screen Share Credentials Repository tests")
struct UserDefaultsScreenShareCredentialsRepositoryTests {

    @Test("Screen sharing video policy survives transfer between app and extension")
    func videoPolicyRoundTrip() throws {
        let settings = ScreenShareVideoSettings(
            contentHint: 3, preferredCodecs: [2, 3, 1], frameRate: 7,
            maxWidth: 1920, maxHeight: 1080, bitratePreset: 3, maxVideoBitrate: 2_000_000, scalableScreenshare: true)
        let decoded = try JSONDecoder().decode(ScreenShareVideoSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    @Test("Content resolution honors independent bounds, orientation and default memory limit")
    func contentOutputDimensions() {
        let normal = ScreenShareVideoSettings()
        #expect(normal.outputDimensions(width: 1920, height: 1080).width == 1280)
        let hd = ScreenShareVideoSettings(maxWidth: 1280, maxHeight: 720)
        let landscape = hd.outputDimensions(width: 1920, height: 1080)
        #expect(landscape.width == 1280 && landscape.height == 720)
        let portrait = hd.outputDimensions(width: 1080, height: 1920)
        #expect(portrait.width == 720 && portrait.height == 1280)
        let fullHD = ScreenShareVideoSettings(maxWidth: 1920, maxHeight: 1080)
        let full = fullHD.outputDimensions(width: 3840, height: 2160)
        #expect(full.width == 1920 && full.height == 1072)
        let wide = hd.outputDimensions(width: 2400, height: 1080)
        #expect(wide.width <= 1280 && wide.height <= 720)
        #expect(wide.width % 16 == 0 && wide.height % 16 == 0)
    }

    @Test("Content frame rate imposes a capture interval independently of camera FPS", arguments: [1, 7, 15, 30])
    func contentFrameRate(rate: Int) {
        #expect(ScreenShareVideoSettings(frameRate: rate).minimumFrameInterval == 1 / Double(rate))
        #expect(ScreenShareVideoSettings().minimumFrameInterval == 0)
    }

    @Test("Save then load returns matching credentials")
    func saveAndLoadReturnsCredentials() {
        let (sut, suiteName) = makeSUT()
        let credentials = makeCredentials()

        sut.save(credentials)
        let loaded = sut.load()

        #expect(loaded == credentials)
        cleanUp(suiteName: suiteName)
    }

    @Test("Load returns nil when nothing has been saved")
    func loadReturnsNilWhenEmpty() {
        let (sut, suiteName) = makeSUT()

        #expect(sut.load() == nil)
        cleanUp(suiteName: suiteName)
    }

    @Test("Clear removes previously saved credentials")
    func clearRemovesCredentials() {
        let (sut, suiteName) = makeSUT()

        sut.save(makeCredentials())
        sut.clear()

        #expect(sut.load() == nil)
        cleanUp(suiteName: suiteName)
    }

    @Test("Save overwrites previous credentials")
    func saveOverwritesPrevious() {
        let (sut, suiteName) = makeSUT()
        let first = makeCredentials(applicationId: "app-1", sessionId: "session-1", token: "token-1")
        let second = makeCredentials(applicationId: "app-2", sessionId: "session-2", token: "token-2")

        sut.save(first)
        sut.save(second)

        #expect(sut.load() == second)
        cleanUp(suiteName: suiteName)
    }

    @Test(
        "Load returns nil when only some keys are stored",
        arguments: [
            ["screenshare_applicationId"],
            ["screenshare_sessionId"],
            ["screenshare_token"],
            ["screenshare_applicationId", "screenshare_sessionId"],
            ["screenshare_username"],
        ]
    )
    func loadReturnsNilWithPartialKeys(keysToSet: [String]) {
        let suiteName = "test.partial.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        for key in keysToSet {
            defaults.set("value", forKey: key)
        }

        let sut = UserDefaultsScreenShareCredentialsRepository(userDefaults: defaults)

        #expect(sut.load() == nil)
        cleanUp(suiteName: suiteName)
    }

    // MARK: - Helpers

    private func makeSUT() -> (UserDefaultsScreenShareCredentialsRepository, String) {
        let suiteName = "test.credentials.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let sut = UserDefaultsScreenShareCredentialsRepository(userDefaults: defaults)
        return (sut, suiteName)
    }

    private func makeCredentials(
        applicationId: String = "app-id",
        sessionId: String = "session-id",
        token: String = "token",
        username: String = "username"
    ) -> ScreenShareCredentials {
        ScreenShareCredentials(
            applicationId: applicationId,
            sessionId: sessionId,
            token: token,
            username: username)
    }

    private func cleanUp(suiteName: String) {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}
