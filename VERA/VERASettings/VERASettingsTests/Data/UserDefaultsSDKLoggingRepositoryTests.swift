//
//  Created by Vonage on 21/05/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("UserDefaultsSDKLoggingRepository Tests")
struct UserDefaultsSDKLoggingRepositoryTests {

    @Test("Default preferences are loaded when nothing is persisted")
    func loadsDefaultPreferencesWhenStoreIsEmpty() async {
        let (sut, _) = makeSUT()

        let preferences = await sut.getPreferences()

        #expect(preferences == .default)
    }

    @Test("save() persists preferences and loads them back")
    func saveAndLoadRoundTrip() async throws {
        let (sut, userDefaults) = makeSUT()
        let preferences = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .error)

        await sut.save(preferences)

        let storedData = try #require(userDefaults.data(forKey: "com.vonage.vera.sdkLoggingPreferences"))
        let storedPreferences = try JSONDecoder().decode(SDKLoggingPreferences.self, from: storedData)
        let loadedPreferences = await sut.getPreferences()

        #expect(storedPreferences == preferences)
        #expect(loadedPreferences == preferences)
    }

    @Test("reset() clears persisted preferences to defaults")
    func resetClearsPreferencesToDefaults() async {
        let (sut, userDefaults) = makeSUT()

        await sut.save(SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .error))
        await sut.reset()

        let preferences = await sut.getPreferences()

        #expect(userDefaults.data(forKey: "com.vonage.vera.sdkLoggingPreferences") == nil)
        #expect(preferences == .default)
    }

    @Test("Corrupted persisted data falls back to defaults")
    func corruptedDataFallsBackToDefaults() async {
        let userDefaults = UserDefaults.ephemeral()
        userDefaults.set(Data("corrupted".utf8), forKey: "com.vonage.vera.sdkLoggingPreferences")
        let sut = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)

        let preferences = await sut.getPreferences()

        #expect(preferences == .default)
    }

    private func makeSUT() -> (sut: UserDefaultsSDKLoggingRepository, userDefaults: UserDefaults) {
        let userDefaults = UserDefaults.ephemeral()
        let sut = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)
        return (sut, userDefaults)
    }

    @Test("savePreferencesSync persists preferences synchronously")
    func savePreferencesSyncPersistsPreferences() throws {
        let userDefaults = UserDefaults.ephemeral()
        let prefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .info, pendingLogCleanup: true)

        UserDefaultsSDKLoggingRepository.savePreferencesSync(prefs, to: userDefaults)

        let loaded = UserDefaultsSDKLoggingRepository.loadPreferencesSync(from: userDefaults)
        #expect(loaded == prefs)
    }

    @Test("savePreferencesSync clears pendingLogCleanup flag")
    func savePreferencesSyncClearsPendingCleanupFlag() throws {
        let userDefaults = UserDefaults.ephemeral()
        var prefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug, pendingLogCleanup: true)

        UserDefaultsSDKLoggingRepository.savePreferencesSync(prefs, to: userDefaults)

        var loaded = UserDefaultsSDKLoggingRepository.loadPreferencesSync(from: userDefaults)
        #expect(loaded.pendingLogCleanup == true)

        prefs.pendingLogCleanup = false
        UserDefaultsSDKLoggingRepository.savePreferencesSync(prefs, to: userDefaults)

        loaded = UserDefaultsSDKLoggingRepository.loadPreferencesSync(from: userDefaults)
        #expect(loaded.pendingLogCleanup == false)
    }
}
