//
//  Created by Vonage on 25/2/26.
//

@preconcurrency import Combine
import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("Settings ViewModel Tests")
struct SettingsViewModelTests {

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default preferences")
    func initializesWithDefaults() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.settingsPreference.videoResolution == .medium)
        #expect(viewModel.settingsPreference.videoFrameRate == .fps30)
        #expect(viewModel.settingsPreference.codecPreference.mode == .automatic)
        #expect(viewModel.maxAudioBitrate == 40_000)
        #expect(viewModel.videoBitratePreset == .default)
        #expect(viewModel.settingsPreference.publisherAudioFallbackEnabled == true)
        #expect(viewModel.settingsPreference.subscriberAudioFallbackEnabled == true)
        #expect(viewModel.senderStatsEnabled == false)
        #expect(viewModel.settingsPreference.degradationPreference == .notSet)
        #expect(viewModel.settingsPreference.opusDtxEnabled == true)
        #expect(viewModel.isPresented == true)
    }

    @Test("ViewModel initializes with custom preferences")
    func initializesWithCustomPreferences() async throws {
        let customPrefs = PublisherSettingsPreferences(
            videoResolution: .high,
            videoFrameRate: .fps15,
            codecPreference: SettingsCodecPreference(
                mode: .manual,
                orderedCodecs: [.vp8, .h264, .vp9]
            ),
            maxAudioBitrate: 128_000,
            videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000,
            publisherAudioFallbackEnabled: false,
            subscriberAudioFallbackEnabled: false,
            senderStatsEnabled: true,
            degradationPreference: .balanced,
            opusDtxEnabled: true
        )
        let repository = MockSettingsRepository(initialPreferences: customPrefs)
        let viewModel = SettingsViewModel(repository: repository)
        await viewModel.setup()

        #expect(viewModel.settingsPreference.videoResolution == .high)
        #expect(viewModel.settingsPreference.videoFrameRate == .fps15)
        #expect(viewModel.settingsPreference.codecPreference.mode == .manual)
        #expect(viewModel.settingsPreference.codecPreference.orderedCodecs == [.vp8, .h264, .vp9])
        #expect(viewModel.maxAudioBitrate == 128_000)
        #expect(viewModel.videoBitratePreset == .custom)
        #expect(viewModel.customMaxVideoBitrate == 2_000_000)
        #expect(viewModel.settingsPreference.publisherAudioFallbackEnabled == false)
        #expect(viewModel.settingsPreference.subscriberAudioFallbackEnabled == false)
        #expect(viewModel.senderStatsEnabled == true)
        #expect(viewModel.settingsPreference.degradationPreference == .balanced)
        #expect(viewModel.settingsPreference.opusDtxEnabled == true)
    }

    // MARK: - Auto-Save Tests

    @Test("Auto-save persists changes after setup")
    func autoSavePersistsAfterSetup() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        // Modify some values
        viewModel.settingsPreference.videoResolution = .high
        viewModel.settingsPreference.maxAudioBitrate = 128_000
        viewModel.settingsPreference.senderStatsEnabled = true

        // Wait for debounce + persist
        await delay()

        // Verify persistence
        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.videoResolution == .high)
        #expect(repository.lastSavedPreferences?.maxAudioBitrate == 128_000)
        #expect(repository.lastSavedPreferences?.senderStatsEnabled == true)
    }

    @Test("Auto-save persists opusDtxEnabled toggle")
    func autoSavePersistsOpusDtx() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        viewModel.settingsPreference.opusDtxEnabled = false

        await delay()

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.opusDtxEnabled == false)
    }

    @Test("Auto-save with custom bitrate preset persists custom value")
    func autoSaveWithCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        viewModel.settingsPreference.videoBitratePreset = .custom
        viewModel.settingsPreference.maxVideoBitrate = 5_000_000

        // Wait for debounce + persist
        await delay()

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .custom)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 5_000_000)
    }

    @Test("Auto-save with non-custom bitrate preset saves zero for maxVideoBitrate")
    func autoSaveWithNonCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        viewModel.settingsPreference.videoBitratePreset = .default
        viewModel.settingsPreference.maxVideoBitrate = 5_000_000

        // Wait for debounce + persist
        await delay()

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .default)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 0)
    }

    @Test("Auto-save persists codec preference correctly")
    func autoSavePersistsCodecPreference() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        viewModel.settingsPreference.codecPreference.mode = .manual
        viewModel.settingsPreference.codecPreference.orderedCodecs = [.h264, .vp9, .vp8]

        // Wait for debounce + persist
        await delay()

        let savedPreference = repository.lastSavedPreferences?.codecPreference
        #expect(savedPreference?.mode == .manual)
        #expect(savedPreference?.orderedCodecs == [.h264, .vp9, .vp8])
    }

    @Test("Auto-save does not persist before setup")
    func autoSaveDoesNotPersistBeforeSetup() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)

        // Modify without calling setup
        viewModel.settingsPreference.videoResolution = .high

        await delay()

        // No auto-save pipeline active
        #expect(repository.saveCallCount == 0)
    }

    @Test("Dismiss sets isPresented to false")
    func dismissSetsIsPresentedToFalse() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.dismiss()

        #expect(viewModel.isPresented == false)
    }

    // MARK: - Reset Tests

    @Test("Reset to defaults restores all values")
    func resetToDefaultsRestoresValues() async throws {
        let customPrefs = PublisherSettingsPreferences(
            videoResolution: .high,
            videoFrameRate: .fps15,
            maxAudioBitrate: 128_000,
            senderStatsEnabled: true
        )
        let repository = MockSettingsRepository(initialPreferences: customPrefs)
        let viewModel = SettingsViewModel(repository: repository)
        await viewModel.setup()

        // Verify custom values loaded
        #expect(viewModel.settingsPreference.videoResolution == .high)
        #expect(viewModel.settingsPreference.videoFrameRate == .fps15)

        // Reset to defaults
        viewModel.resetToDefaults()

        // Wait for update
        await delay()

        // Verify reset
        #expect(repository.resetCallCount == 1)
        #expect(viewModel.settingsPreference.videoResolution == .medium)
        #expect(viewModel.settingsPreference.videoFrameRate == .fps30)
        #expect(viewModel.maxAudioBitrate == 40_000)
        #expect(viewModel.videoBitratePreset == .default)
        #expect(viewModel.settingsPreference.publisherAudioFallbackEnabled == true)
        #expect(viewModel.settingsPreference.subscriberAudioFallbackEnabled == true)
        #expect(viewModel.settingsPreference.opusDtxEnabled == true)
        #expect(viewModel.senderStatsEnabled == false)
        #expect(viewModel.settingsPreference.degradationPreference == .notSet)
    }

    // MARK: - Cancel Tests

    @Test("Dismiss does not trigger additional save")
    func dismissDoesNotTriggerAdditionalSave() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        // Modify values (will auto-save)
        viewModel.settingsPreference.videoResolution = .high

        await delay()
        let saveCountAfterAutoSave = repository.saveCallCount

        // Dismiss
        viewModel.dismiss()

        await delay()

        // No additional save beyond the auto-save
        #expect(repository.saveCallCount == saveCountAfterAutoSave)
        #expect(viewModel.isPresented == false)
    }

    // MARK: - Formatted Properties Tests

    @Test("Audio bitrate formatted returns correct string")
    func audioBitrateFormatted() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.maxAudioBitrate = 40_000
        let formatted1 = viewModel.maxAudioBitrateFormatted
        #expect(formatted1 == "40.0 kbps")

        viewModel.settingsPreference.maxAudioBitrate = 128_000
        let formatted2 = viewModel.maxAudioBitrateFormatted
        #expect(formatted2 == "128.0 kbps")

        viewModel.settingsPreference.maxAudioBitrate = 1_000_000
        let formatted3 = viewModel.maxAudioBitrateFormatted
        #expect(formatted3 == "1.0 Mbps")

        // Keep objects alive until end of test
        _ = repository
        _ = viewModel
    }

    @Test("Video bitrate formatted returns correct string")
    func videoBitrateFormatted() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.maxVideoBitrate = 500_000
        let formatted1 = viewModel.videoBitrateFormatted
        #expect(formatted1 == "500.0 kbps")

        viewModel.settingsPreference.maxVideoBitrate = 2_000_000
        let formatted2 = viewModel.videoBitrateFormatted
        #expect(formatted2 == "2.0 Mbps")

        viewModel.settingsPreference.maxVideoBitrate = 5_000_000
        let formatted3 = viewModel.videoBitrateFormatted
        #expect(formatted3 == "5.0 Mbps")

        // Keep objects alive until end of test
        _ = repository
        _ = viewModel
    }

    // MARK: - State Mutation Tests

    @Test("Modifying properties updates values correctly")
    func propertyMutations() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Test all property mutations
        viewModel.settingsPreference.videoResolution = .high
        #expect(viewModel.settingsPreference.videoResolution == .high)

        viewModel.settingsPreference.videoFrameRate = .fps15
        #expect(viewModel.settingsPreference.videoFrameRate == .fps15)

        viewModel.settingsPreference.codecPreference.mode = .manual
        #expect(viewModel.settingsPreference.codecPreference.mode == .manual)

        viewModel.settingsPreference.codecPreference.orderedCodecs = [.h264, .vp8]
        #expect(viewModel.settingsPreference.codecPreference.orderedCodecs == [.h264, .vp8])

        viewModel.settingsPreference.maxAudioBitrate = 256_000
        #expect(viewModel.maxAudioBitrate == 256_000)

        viewModel.settingsPreference.videoBitratePreset = .bandwidthSaver
        #expect(viewModel.videoBitratePreset == .bandwidthSaver)

        viewModel.settingsPreference.maxVideoBitrate = 3_000_000
        #expect(viewModel.customMaxVideoBitrate == 3_000_000)

        viewModel.settingsPreference.publisherAudioFallbackEnabled = false
        #expect(viewModel.settingsPreference.publisherAudioFallbackEnabled == false)

        viewModel.settingsPreference.subscriberAudioFallbackEnabled = false
        #expect(viewModel.settingsPreference.subscriberAudioFallbackEnabled == false)

        viewModel.settingsPreference.senderStatsEnabled = true
        #expect(viewModel.senderStatsEnabled == true)

        viewModel.settingsPreference.degradationPreference = .maintainFrameRate
        #expect(viewModel.settingsPreference.degradationPreference == .maintainFrameRate)

        viewModel.settingsPreference.degradationPreference = .balanced
        #expect(viewModel.settingsPreference.degradationPreference == .balanced)

        viewModel.isPresented = false
        #expect(viewModel.isPresented == false)
    }
}
