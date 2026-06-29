//
//  Created by Vonage on 21/05/2026.
//

import Combine
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
        let sdkLoggingRepository: SDKLoggingRepository = UserDefaultsSDKLoggingRepository()
        let prefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .info, pendingLogCleanup: true)

        sdkLoggingRepository.savePreferencesSync(prefs)

        let loaded = sdkLoggingRepository.loadPreferencesSync()
        #expect(loaded == prefs)
    }

    @Test("savePreferencesSync clears pendingLogCleanup flag")
    func savePreferencesSyncClearsPendingCleanupFlag() throws {
        let sdkLoggingRepository: SDKLoggingRepository = UserDefaultsSDKLoggingRepository()
        var prefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug, pendingLogCleanup: true)

        sdkLoggingRepository.savePreferencesSync(prefs)

        var loaded = sdkLoggingRepository.loadPreferencesSync()
        #expect(loaded.pendingLogCleanup == true)

        prefs.pendingLogCleanup = false
        sdkLoggingRepository.savePreferencesSync(prefs)

        loaded = sdkLoggingRepository.loadPreferencesSync()
        #expect(loaded.pendingLogCleanup == false)
    }

    // MARK: - Publisher Tests

    @Test("preferencesPublisher emits current value on subscription")
    func preferencesPublisherEmitsCurrentValue() async throws {
        let (sut, _) = makeSUT()

        let received = try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = sut.preferencesPublisher
                .first()
                .sink { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
        }

        #expect(received == .default)
    }

    @Test("preferencesPublisher emits updated value after save")
    func preferencesPublisherEmitsAfterSave() async throws {
        let (sut, _) = makeSUT()
        let expected = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .error)

        await sut.save(expected)

        let received = try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = sut.preferencesPublisher
                .first()
                .sink { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
        }

        #expect(received == expected)
    }

    @Test("getPreferences syncs subject when UserDefaults has newer data")
    func getPreferencesSyncsSubjectFromUserDefaults() async {
        let userDefaults = UserDefaults.ephemeral()
        let sut = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)

        // Write directly to UserDefaults, bypassing the actor
        let external = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .warn)
        if let data = try? JSONEncoder().encode(external) {
            userDefaults.set(data, forKey: "com.vonage.vera.sdkLoggingPreferences")
        }

        let preferences = await sut.getPreferences()
        #expect(preferences == external)
    }

    @Test("loadPreferencesSync returns defaults when UserDefaults is empty")
    func loadPreferencesSyncReturnsDefaultsWhenEmpty() {
        let userDefaults = UserDefaults.ephemeral()
        let sdkLoggingRepository: SDKLoggingRepository = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)
        let loaded = sdkLoggingRepository.loadPreferencesSync()
        #expect(loaded == .default)
    }

    @Test("loadPreferencesSync returns defaults with corrupted data")
    func loadPreferencesSyncReturnsDefaultsWithCorruptedData() {
        let userDefaults = UserDefaults.ephemeral()
        let sdkLoggingRepository: SDKLoggingRepository = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)
        userDefaults.set(Data("not json".utf8), forKey: "com.vonage.vera.sdkLoggingPreferences")

        let loaded = sdkLoggingRepository.loadPreferencesSync()
        #expect(loaded == .default)
    }

    @Test("Multiple saves emit multiple publisher values")
    func multipleSavesEmitMultiplePublisherValues() async {
        let (sut, _) = makeSUT()

        let prefs1 = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let prefs2 = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .error)

        await sut.save(prefs1)
        let first = await sut.getPreferences()
        #expect(first == prefs1)

        await sut.save(prefs2)
        let second = await sut.getPreferences()
        #expect(second == prefs2)
    }
}
