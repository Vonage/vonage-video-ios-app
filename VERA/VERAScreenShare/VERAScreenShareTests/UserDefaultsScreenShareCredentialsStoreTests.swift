//
//  Created by Vonage on 6/3/26.
//

import Foundation
import Testing
import VERAScreenShare

@Suite("UserDefaultsScreenShareCredentialsStore Tests")
struct UserDefaultsScreenShareCredentialsStoreTests {

    // MARK: - init

    @Test("init succeeds with a valid UserDefaults instance")
    func initSucceedsWithValidUserDefaults() {
        let defaults = UserDefaults(suiteName: "com.vonage.VERA.tests.init")!
        let store = UserDefaultsScreenShareCredentialsStore(userDefaults: defaults)
        #expect(store != nil)
    }

    // MARK: - load

    @Test("load returns nil when UserDefaults is empty")
    func loadReturnsNilWhenEmpty() {
        let (store, _) = makeSUT()
        #expect(store.load() == nil)
    }

    @Test("load returns credentials when all keys are present")
    func loadReturnsCredentialsWhenAllKeysPresent() {
        let (store, defaults) = makeSUT()
        defaults.set("app-123", forKey: "screenshare_applicationId")
        defaults.set("session-abc", forKey: "screenshare_sessionId")
        defaults.set("token-xyz", forKey: "screenshare_token")

        let result = store.load()

        #expect(result?.applicationId == "app-123")
        #expect(result?.sessionId == "session-abc")
        #expect(result?.token == "token-xyz")
    }

    @Test("load returns nil when applicationId is missing")
    func loadReturnsNilWhenApplicationIdMissing() {
        let (store, defaults) = makeSUT()
        defaults.set("session-abc", forKey: "screenshare_sessionId")
        defaults.set("token-xyz", forKey: "screenshare_token")

        #expect(store.load() == nil)
    }

    @Test("load returns nil when sessionId is missing")
    func loadReturnsNilWhenSessionIdMissing() {
        let (store, defaults) = makeSUT()
        defaults.set("app-123", forKey: "screenshare_applicationId")
        defaults.set("token-xyz", forKey: "screenshare_token")

        #expect(store.load() == nil)
    }

    @Test("load returns nil when token is missing")
    func loadReturnsNilWhenTokenMissing() {
        let (store, defaults) = makeSUT()
        defaults.set("app-123", forKey: "screenshare_applicationId")
        defaults.set("session-abc", forKey: "screenshare_sessionId")

        #expect(store.load() == nil)
    }

    // MARK: - Helpers

    private func makeSUT() -> (store: UserDefaultsScreenShareCredentialsStore, defaults: UserDefaults) {
        let suiteName = "com.vonage.VERA.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let store = UserDefaultsScreenShareCredentialsStore(userDefaults: defaults)
        return (store, defaults)
    }
}
