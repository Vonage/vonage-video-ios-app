//
//  Created by Vonage on 6/3/26.
//

import Foundation
import Testing
import VERAScreenShare

@Suite("UserDefaults Screen Share Credentials Repository tests")
struct UserDefaultsScreenShareCredentialsRepositoryTests {

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
