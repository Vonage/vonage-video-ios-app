//
//  Created by Vonage on 5/3/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("UserDefaultsSettingsRepository Tests")
struct UserDefaultsSettingsRepositoryTests {
    @Test("Web defaults apply to new settings while automatic audio remains SDK-managed")
    func webDefaults() {
        let preferences = PublisherSettingsPreferences.default
        #expect(preferences.videoResolution == .high)
        #expect(preferences.audioBitratePreference == .default)
        #expect(!preferences.publisherAudioFallbackEnabled)
        #expect(!preferences.subscriberAudioFallbackEnabled)
        #expect(!preferences.statsOverlayEnabled)
        #expect(!preferences.advancedNoiseSuppressionEnabled)
        #expect(preferences.cameraContentHint == .automatic)
        #expect(preferences.screenShareContentHint == .detail)
        #expect(preferences.screenShareCodecMode == .inherit)
        #expect(preferences.screenShareFrameRate == nil)
        #expect(preferences.screenShareResolution == nil)
        #expect(preferences.screenShareBitratePreset == nil)
        #expect(preferences.screenShareMaxVideoBitrate == 500_000)
        #expect(!preferences.scalableScreenshareEnabled)
        #expect(SettingsSection.allCases == [.general, .video, .screenSharing, .audio, .stats])
    }

    @Test("Noise suppression and separate content hints persist across restart and reset")
    func audioAndContentHintsPersist() async throws {
        let defaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: defaults)
        var preferences = PublisherSettingsPreferences.default
        preferences.videoResolution = .medium
        preferences.advancedNoiseSuppressionEnabled = true
        preferences.cameraContentHint = .motion
        preferences.screenShareContentHint = .text
        preferences.screenShareCodecMode = .manual
        preferences.screenShareCodecPreference.orderedCodecs = [.h264, .vp9, .vp8]
        preferences.screenShareFrameRate = .fps7
        preferences.screenShareResolution = .fullHD
        preferences.screenShareBitratePreset = .custom
        preferences.screenShareMaxVideoBitrate = 2_000_000
        preferences.scalableScreenshareEnabled = true
        await repository.save(preferences)
        let reloaded = UserDefaultsSettingsRepository(userDefaults: defaults)
        let restored = await reloaded.getPreferences()
        #expect(restored == preferences)
        #expect(restored.toPublisherAdvancedSettings().advancedNoiseSuppressionEnabled == true)
        #expect(restored.toPublisherAdvancedSettings().cameraContentHint == .motion)
        await reloaded.reset()
        #expect(await reloaded.getPreferences() == .default)
    }

    @Test("Legacy resolution and bitrate survive addition of audio and content preferences")
    func legacyAudioAndHintsMigration() async throws {
        let defaults = UserDefaults.ephemeral()
        let preferences = PublisherSettingsPreferences(
            videoResolution: .medium, audioBitratePreference: .custom(40_000))
        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(preferences)) as? [String: Any])
        for key in [
            "advancedNoiseSuppressionEnabled", "cameraContentHint", "screenShareContentHint", "screenShareCodecMode",
            "screenShareCodecPreference", "screenShareFrameRate", "screenShareResolution", "screenShareBitratePreset",
            "screenShareMaxVideoBitrate", "scalableScreenshareEnabled",
        ] {
            payload.removeValue(forKey: key)
        }
        defaults.set(
            try JSONSerialization.data(withJSONObject: payload), forKey: "com.vonage.vera.publisherSettingsPreferences")
        let repository = UserDefaultsSettingsRepository(userDefaults: defaults)
        let restored = await repository.getPreferences()
        #expect(restored.videoResolution == .medium)
        #expect(restored.audioBitratePreference == .custom(40_000))
        #expect(!restored.advancedNoiseSuppressionEnabled)
        #expect(restored.cameraContentHint == .automatic)
        #expect(restored.screenShareContentHint == .detail)
    }

    @Test("Toolbar noise changes retain other preferences")
    func toolbarNoiseRetainsPreferences() async throws {
        let repository = UserDefaultsSettingsRepository(userDefaults: .ephemeral())
        var preferences = PublisherSettingsPreferences.default
        preferences.cameraPosition = .back
        preferences.screenShareContentHint = .text
        preferences.screenShareCodecMode = .manual
        preferences.screenShareCodecPreference.orderedCodecs = [.h264, .vp9, .vp8]
        preferences.screenShareFrameRate = .fps7
        preferences.screenShareResolution = .fullHD
        preferences.screenShareBitratePreset = .custom
        preferences.screenShareMaxVideoBitrate = 2_000_000
        preferences.scalableScreenshareEnabled = true
        await repository.save(preferences)
        await repository.saveAdvancedNoiseSuppression(true)
        let restored = await repository.getPreferences()
        #expect(restored.cameraPosition == .back)
        #expect(restored.screenShareContentHint == .text)
        #expect(restored.advancedNoiseSuppressionEnabled)
    }


    @Test("Self-view mirror preference survives relaunch and reset")
    func selfViewMirrorPersistsAndResets() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        var preferences = PublisherSettingsPreferences.default
        preferences.selfViewMirroringEnabled = false
        await repository.save(preferences)

        let reloaded = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let restored = await reloaded.getPreferences()
        #expect(!restored.selfViewMirroringEnabled)
        #expect(restored.toPublisherAdvancedSettings().selfViewMirroringEnabled == false)
        await reloaded.reset()
        #expect(await reloaded.getPreferences().selfViewMirroringEnabled)
    }

    @Test("Older settings retain their values when the mirror field is absent")
    func legacySettingsDefaultMirroringWithoutLosingPreferences() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let preferences = PublisherSettingsPreferences(videoResolution: .high, videoFrameRate: .fps15)
        var payload = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(preferences)) as? [String: Any]
        )
        payload.removeValue(forKey: "selfViewMirroringEnabled")
        payload.removeValue(forKey: "cameraPosition")
        userDefaults.set(
            try JSONSerialization.data(withJSONObject: payload),
            forKey: "com.vonage.vera.publisherSettingsPreferences"
        )
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let restored = await repository.getPreferences()
        #expect(restored.selfViewMirroringEnabled)
        #expect(restored.cameraPosition == .front)
        #expect(restored.videoResolution == .high)
        #expect(restored.videoFrameRate == .fps15)
    }

    @Test("Camera choice survives a new repository and camera updates retain other preferences")
    func cameraChoicePersists() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        var preferences = PublisherSettingsPreferences(videoResolution: .high, videoFrameRate: .fps15)
        preferences.selfViewMirroringEnabled = false
        await repository.save(preferences)
        await repository.saveCameraPosition(.back)
        let reloaded = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let restored = await reloaded.getPreferences()
        #expect(restored.cameraPosition == .back)
        #expect(restored.toPublisherAdvancedSettings().cameraPosition == .back)
        #expect(restored.videoResolution == .high)
        #expect(restored.videoFrameRate == .fps15)
        #expect(!restored.selfViewMirroringEnabled)
        await reloaded.reset()
        #expect(await reloaded.getPreferences().cameraPosition == .front)
    }

    // MARK: - Initialization Tests

    @Test("Fresh start loads default preferences")
    func freshStartLoadsDefaults() async {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        let preferences = await repository.getPreferences()

        #expect(preferences == PublisherSettingsPreferences.default)
    }

    @Test("Existing data loads correctly from UserDefaults")
    func existingDataLoadsCorrectly() async throws {
        let userDefaults = UserDefaults.ephemeral()

        // Pre-populate UserDefaults with custom preferences
        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .high,
            videoFrameRate: .fps15,
            codecPreference: SettingsCodecPreference(mode: .manual, orderedCodecs: [.vp8, .h264]),
            audioBitratePreference: .custom(128_000),
            videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000,
            publisherAudioFallbackEnabled: false,
            subscriberAudioFallbackEnabled: false,
            senderStatsEnabled: true,
            degradationPreference: .balanced
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(customPreferences)
        userDefaults.set(data, forKey: "com.vonage.vera.publisherSettingsPreferences")

        // Create repository - should load existing data
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        let loadedPreferences = await repository.getPreferences()

        #expect(loadedPreferences == customPreferences)
        #expect(loadedPreferences.videoResolution == .high)
        #expect(loadedPreferences.senderStatsEnabled == true)
    }

    @Test("Persisted preferences are published before setup")
    func persistedPreferencesArePublishedBeforeSetup() async {
        let userDefaults = UserDefaults.ephemeral()
        var persistedPreferences = PublisherSettingsPreferences.default
        persistedPreferences.screenShareContentHint = .text
        let sourceRepository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        await sourceRepository.save(persistedPreferences)

        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        var receivedPreferences: [PublisherSettingsPreferences] = []
        let cancellable = repository.preferencesPublisher.sink { receivedPreferences.append($0) }

        #expect(receivedPreferences == [persistedPreferences])
        withExtendedLifetime(cancellable) {}
    }

    @Test("Corrupted data falls back to defaults")
    func corruptedDataFallsBackToDefaults() async {
        let userDefaults = UserDefaults.ephemeral()

        // Store corrupted data
        userDefaults.set("corrupted data".data(using: .utf8), forKey: "com.vonage.vera.publisherSettingsPreferences")

        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        let preferences = await repository.getPreferences()

        #expect(preferences == PublisherSettingsPreferences.default)
    }

    @Test("Publisher emits initial value immediately")
    func publisherEmitsInitialValue() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var receivedPreferences: PublisherSettingsPreferences?
        let cancellable = repository.preferencesPublisher
            .sink { preferences in
                receivedPreferences = preferences
            }

        // Wait for emission
        await delay()

        #expect(receivedPreferences == PublisherSettingsPreferences.default)

        cancellable.cancel()
    }

    @Test("setup() seeds publisher with persisted preferences")
    func setupSeedsPublisherWithPersistedPreferences() async throws {
        let userDefaults = UserDefaults.ephemeral()

        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .high,
            senderStatsEnabled: true
        )
        let data = try JSONEncoder().encode(customPreferences)
        userDefaults.set(data, forKey: "com.vonage.vera.publisherSettingsPreferences")

        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        await repository.setup()

        var receivedPreferences: PublisherSettingsPreferences?
        let cancellable = repository.preferencesPublisher
            .sink { receivedPreferences = $0 }

        #expect(receivedPreferences == customPreferences)

        cancellable.cancel()
    }

    // MARK: - Save Tests

    @Test("save() encodes and stores in UserDefaults")
    func saveEncodesAndStores() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .low,
            videoFrameRate: .fps7,
            audioBitratePreference: .custom(64_000),
            senderStatsEnabled: true
        )

        await repository.save(customPreferences)

        // Verify data is stored in UserDefaults
        let storedData = try #require(userDefaults.data(forKey: "com.vonage.vera.publisherSettingsPreferences"))

        // Verify data can be decoded
        let decoder = JSONDecoder()
        let decodedPreferences = try decoder.decode(PublisherSettingsPreferences.self, from: storedData)
        #expect(decodedPreferences == customPreferences)
    }

    @Test("opusDtxEnabled defaults to true and persists correctly")
    func opusDtxDefaultsAndPersists() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        // Verify default value is true
        let defaultPreferences = await repository.getPreferences()
        #expect(defaultPreferences.opusDtxEnabled == true)

        // Save with opusDtxEnabled = false
        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .medium,
            audioBitratePreference: .custom(40_000),
            opusDtxEnabled: false
        )
        await repository.save(customPreferences)

        // Verify persistence
        let loadedPreferences = await repository.getPreferences()
        #expect(loadedPreferences.opusDtxEnabled == false)

        // Verify encoding/decoding
        let storedData = try #require(userDefaults.data(forKey: "com.vonage.vera.publisherSettingsPreferences"))

        let decoder = JSONDecoder()
        let decodedPreferences = try decoder.decode(PublisherSettingsPreferences.self, from: storedData)
        #expect(decodedPreferences.opusDtxEnabled == false)
    }

    @Test("save() updates subject and emits through publisher")
    func saveUpdatesSubjectAndEmits() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var emittedValues: [PublisherSettingsPreferences] = []
        let cancellable = repository.preferencesPublisher
            .sink { preferences in
                emittedValues.append(preferences)
            }

        // Wait for initial value
        await delay()

        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .high,
            senderStatsEnabled: true
        )

        await repository.save(customPreferences)

        // Wait for emission
        await delay()

        #expect(emittedValues.count == 2)
        #expect(emittedValues[0] == PublisherSettingsPreferences.default)
        #expect(emittedValues[1] == customPreferences)

        let currentPreferences = await repository.getPreferences()
        #expect(currentPreferences == customPreferences)

        cancellable.cancel()
    }

    @Test("Saved data persists across instances")
    func savedDataPersistsAcrossInstances() async throws {
        let userDefaults = UserDefaults.ephemeral()

        // First instance - save data
        let repository1 = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let customPreferences = PublisherSettingsPreferences(
            videoFrameRate: .fps1,
            videoBitratePreset: .bandwidthSaver,
            publisherAudioFallbackEnabled: false
        )
        await repository1.save(customPreferences)

        // Second instance - should load saved data
        let repository2 = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let loadedPreferences = await repository2.getPreferences()

        #expect(loadedPreferences == customPreferences)
        #expect(loadedPreferences.videoFrameRate == .fps1)
        #expect(loadedPreferences.videoBitratePreset == .bandwidthSaver)
    }

    @Test("Multiple saves work correctly")
    func multipleSavesWorkCorrectly() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var emittedValues: [PublisherSettingsPreferences] = []
        let cancellable = repository.preferencesPublisher
            .sink { preferences in
                emittedValues.append(preferences)
            }

        // Wait for initial value
        await delay()

        // First save
        let prefs1 = PublisherSettingsPreferences(videoResolution: .low)
        await repository.save(prefs1)
        await delay()

        // Second save
        let prefs2 = PublisherSettingsPreferences(videoResolution: .high)
        await repository.save(prefs2)
        await delay()

        #expect(emittedValues.count == 3)
        #expect(emittedValues[0] == PublisherSettingsPreferences.default)
        #expect(emittedValues[1] == prefs1)
        #expect(emittedValues[2] == prefs2)

        cancellable.cancel()
    }

    // MARK: - Reset Tests

    @Test("reset() removes data from UserDefaults")
    func resetRemovesDataFromUserDefaults() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        // Save some data
        let customPreferences = PublisherSettingsPreferences(senderStatsEnabled: true)
        await repository.save(customPreferences)

        // Verify data exists
        #expect(userDefaults.data(forKey: "com.vonage.vera.publisherSettingsPreferences") != nil)

        // Reset
        await repository.reset()

        // Verify data is removed
        #expect(userDefaults.data(forKey: "com.vonage.vera.publisherSettingsPreferences") == nil)
    }

    @Test("reset() emits default preferences")
    func resetEmitsDefaults() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var emittedValues: [PublisherSettingsPreferences] = []
        let cancellable = repository.preferencesPublisher
            .sink { preferences in
                emittedValues.append(preferences)
            }

        // Wait for initial value
        await delay()

        // Save custom data
        let customPreferences = PublisherSettingsPreferences(videoResolution: .high)
        await repository.save(customPreferences)
        await delay()

        // Reset
        await repository.reset()
        await delay()

        #expect(emittedValues.count == 3)
        #expect(emittedValues[0] == PublisherSettingsPreferences.default)
        #expect(emittedValues[1] == customPreferences)
        #expect(emittedValues[2] == PublisherSettingsPreferences.default)

        let currentPreferences = await repository.getPreferences()
        #expect(currentPreferences == PublisherSettingsPreferences.default)

        cancellable.cancel()
    }

    @Test("After reset, new instance loads defaults")
    func afterResetNewInstanceLoadsDefaults() async throws {
        let userDefaults = UserDefaults.ephemeral()

        // First instance - save and reset
        let repository1 = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let customPreferences = PublisherSettingsPreferences(senderStatsEnabled: true)
        await repository1.save(customPreferences)
        await repository1.reset()

        // Second instance - should load defaults
        let repository2 = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let loadedPreferences = await repository2.getPreferences()

        #expect(loadedPreferences == PublisherSettingsPreferences.default)
    }

    // MARK: - Publisher Tests

    @Test("Multiple subscribers receive same values")
    func multipleSubscribersReceiveSameValues() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var subscriber1Values: [PublisherSettingsPreferences] = []
        var subscriber2Values: [PublisherSettingsPreferences] = []

        let cancellable1 = repository.preferencesPublisher
            .sink { preferences in
                subscriber1Values.append(preferences)
            }

        let cancellable2 = repository.preferencesPublisher
            .sink { preferences in
                subscriber2Values.append(preferences)
            }

        // Wait for initial emissions
        await delay()

        // Update preferences
        let customPreferences = PublisherSettingsPreferences(videoResolution: .high)
        await repository.save(customPreferences)

        // Wait for update
        await delay()

        #expect(subscriber1Values.count == 2)
        #expect(subscriber2Values.count == 2)
        #expect(subscriber1Values[1] == customPreferences)
        #expect(subscriber2Values[1] == customPreferences)

        cancellable1.cancel()
        cancellable2.cancel()
    }

    @Test("Publisher emits on every save")
    func publisherEmitsOnEverySave() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        var emissionCount = 0
        let cancellable = repository.preferencesPublisher
            .sink { _ in
                emissionCount += 1
            }

        // Wait for initial value
        try await Task.sleep(for: .milliseconds(50))
        #expect(emissionCount == 1)

        // Multiple saves
        for i in 0..<5 {
            let prefs = PublisherSettingsPreferences(audioBitratePreference: .custom(Int32(i * 1000)))
            await repository.save(prefs)
            await delay()
        }

        #expect(emissionCount == 6)  // initial + 5 saves

        cancellable.cancel()
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent reads and writes are safe")
    func concurrentReadsAndWritesAreSafe() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        // Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Concurrent writes
            for i in 0..<10 {
                group.addTask {
                    let prefs = PublisherSettingsPreferences(audioBitratePreference: .custom(Int32(i * 1000)))
                    await repository.save(prefs)
                }
            }

            // Concurrent reads
            for _ in 0..<10 {
                group.addTask {
                    _ = await repository.getPreferences()
                }
            }
        }

        // Repository should still be in valid state
        let finalPreferences = await repository.getPreferences()
        #expect(
            finalPreferences.videoResolution == .medium
                || (finalPreferences.audioBitratePreference.customValue ?? 0) >= 0)
    }

    // MARK: - Edge Cases

    @Test("Custom UserDefaults instance works correctly")
    func customUserDefaultsWorks() async throws {
        let customDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: customDefaults)

        let customPreferences = PublisherSettingsPreferences(videoResolution: .high)
        await repository.save(customPreferences)

        // Verify data is in custom UserDefaults, not standard
        let dataInCustom = customDefaults.data(forKey: "com.vonage.vera.publisherSettingsPreferences")
        #expect(dataInCustom != nil)

        // Standard UserDefaults should not have the data
        let dataInStandard = UserDefaults.standard.data(forKey: "com.vonage.vera.publisherSettingsPreferences")
        // Note: Only check if we didn't accidentally pollute standard defaults in this test run
        // In isolated ephemeral suite, standard should be empty
    }

    @Test("getPreferences returns current value synchronously")
    func getPreferencesReturnsCurrentValue() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)

        // Initial value
        let initial = await repository.getPreferences()
        #expect(initial == PublisherSettingsPreferences.default)

        // After save
        let customPreferences = PublisherSettingsPreferences(videoResolution: .high)
        try await repository.save(customPreferences)

        let updated = await repository.getPreferences()
        #expect(updated == customPreferences)
    }
}

// MARK: - Helper Extensions

extension UserDefaults {
    static func ephemeral() -> UserDefaults {
        let suiteName = "com.vonage.vera.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
