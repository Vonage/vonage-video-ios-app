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
        #expect(viewModel.isLoggingEnabled == false)
        #expect(viewModel.sdkLogLevel == .debug)
        #expect(viewModel.hasLogFiles == false)
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

    @Test("Setup loads SDK logging preferences")
    func setupLoadsLoggingPreferences() async throws {
        let repository = MockSettingsRepository()
        let loggingRepository = MockSDKLoggingRepository(
            initialPreferences: SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .warn)
        )
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository
        )

        await viewModel.setup()

        #expect(viewModel.isLoggingEnabled == true)
        #expect(viewModel.sdkLogLevel == .warn)
    }

    // MARK: - Save Tests

    @Test("Save persists current state and dismisses view")
    func savePersistsAndDismisses() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Modify some values
        viewModel.settingsPreference.videoResolution = .high
        viewModel.settingsPreference.maxAudioBitrate = 128_000
        viewModel.settingsPreference.senderStatsEnabled = true

        // Save
        await viewModel.save()

        // Verify persistence
        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.videoResolution == .high)
        #expect(repository.lastSavedPreferences?.maxAudioBitrate == 128_000)
        #expect(repository.lastSavedPreferences?.senderStatsEnabled == true)
        #expect(viewModel.isPresented == false)
    }

    @Test("Save persists opusDtxEnabled toggle")
    func savePersistsOpusDtx() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.opusDtxEnabled = true

        await viewModel.save()

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.opusDtxEnabled == true)
    }

    @Test("Save with custom bitrate preset persists custom value")
    func saveWithCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.videoBitratePreset = .custom
        viewModel.settingsPreference.maxVideoBitrate = 5_000_000

        await viewModel.save()

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .custom)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 5_000_000)
    }

    @Test("Save with non-custom bitrate preset saves zero for maxVideoBitrate")
    func saveWithNonCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.videoBitratePreset = .default
        viewModel.settingsPreference.maxVideoBitrate = 5_000_000

        await viewModel.save()

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .default)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 0)
    }

    @Test("Save persists codec preference correctly")
    func savePersistsCodecPreference() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.codecPreference.mode = .manual
        viewModel.settingsPreference.codecPreference.orderedCodecs = [.h264, .vp9, .vp8]

        await viewModel.save()

        let savedPreference = repository.lastSavedPreferences?.codecPreference
        #expect(savedPreference?.mode == .manual)
        #expect(savedPreference?.orderedCodecs == [.h264, .vp9, .vp8])
    }

    @Test("Save shows restart alert when logging toggle changes")
    func saveShowsRestartAlertWhenLoggingToggleChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        viewModel.isLoggingEnabled = true
        viewModel.sdkLogLevel = .error

        await viewModel.save()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(
            loggingRepository.lastSavedPreferences
                == SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .error, pendingLogCleanup: true)
        )
        #expect(viewModel.showRestartAlert == true)
        #expect(viewModel.isPresented == true)
    }

    @Test("Save shows restart alert when only log level changes")
    func saveShowsRestartAlertWhenLogLevelChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        viewModel.sdkLogLevel = .warn

        await viewModel.save()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(
            loggingRepository.lastSavedPreferences
                == SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .warn, pendingLogCleanup: true)
        )
        #expect(viewModel.showRestartAlert == true)
        #expect(viewModel.isPresented == true)
    }

    @Test("Save dismisses without alert when logging settings are unchanged")
    func saveDismissesWhenLoggingSettingsAreUnchanged() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await viewModel.save()

        #expect(viewModel.showRestartAlert == false)
        #expect(viewModel.isPresented == false)
    }

    @Test("Save sets pendingLogCleanup when logging is re-enabled")
    func saveSetsCleanupFlagWhenLoggingIsReenabled() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        viewModel.isLoggingEnabled = true
        await viewModel.save()

        let saved = await loggingRepository.getPreferences()
        #expect(saved.pendingLogCleanup == true)
    }

    @Test("Save sets pendingLogCleanup when log level changes")
    func saveSetsCleanupFlagWhenLogLevelChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        viewModel.sdkLogLevel = .info
        await viewModel.save()

        let saved = await loggingRepository.getPreferences()
        #expect(saved.pendingLogCleanup == true)
    }

    @Test("Save does not set pendingLogCleanup when nothing changes")
    func saveDoesNotSetCleanupFlagWhenNothingChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await viewModel.save()

        let saved = await loggingRepository.getPreferences()
        #expect(saved.pendingLogCleanup == false)
    }

    @Test("Logging preferences persist across ViewModel instances")
    func loggingPreferencesPersistAcrossViewModelInstances() async throws {
        let userDefaults = UserDefaults.ephemeral()
        let settingsRepo = MockSettingsRepository()
        let loggingRepo = UserDefaultsSDKLoggingRepository(userDefaults: userDefaults)

        let vm1 = SettingsViewModel(
            repository: settingsRepo,
            loggingRepository: loggingRepo,
            initialLoggingPreferences: UserDefaultsSDKLoggingRepository.loadPreferencesSync(from: userDefaults)
        )
        await vm1.setup()

        vm1.isLoggingEnabled = true
        vm1.sdkLogLevel = .error
        await vm1.save()

        let vm2 = SettingsViewModel(
            repository: settingsRepo,
            loggingRepository: loggingRepo,
            initialLoggingPreferences: UserDefaultsSDKLoggingRepository.loadPreferencesSync(from: userDefaults)
        )

        #expect(vm2.isLoggingEnabled == true)
        #expect(vm2.sdkLogLevel == .error)
    }

    // MARK: - Send Logs Tests

    @Test("sendLogs shows share sheet when log files exist")
    @MainActor
    func sendLogsShowsShareSheetWhenFilesExist() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: {
                [URL(fileURLWithPath: "/tmp/test.log")]
            }
        )

        viewModel.sendLogs()

        #expect(viewModel.showShareSheet == true)
        #expect(viewModel.showNoLogsAlert == false)
    }

    @Test("sendLogs shows no-logs alert when no files exist")
    @MainActor
    func sendLogsShowsNoLogsAlertWhenNoFilesExist() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: { [] }
        )

        viewModel.sendLogs()

        #expect(viewModel.showShareSheet == false)
        #expect(viewModel.showNoLogsAlert == true)
    }

    @Test("sendLogs shows no-logs alert when provider is nil")
    @MainActor
    func sendLogsShowsNoLogsAlertWhenProviderIsNil() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: nil
        )

        viewModel.sendLogs()

        #expect(viewModel.showShareSheet == false)
        #expect(viewModel.showNoLogsAlert == true)
    }

    @Test("hasLogFiles returns true when provider has files")
    @MainActor
    func hasLogFilesReturnsTrueWhenProviderHasFiles() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: {
                [URL(fileURLWithPath: "/tmp/test.log")]
            }
        )

        #expect(viewModel.hasLogFiles == true)
    }

    @Test("hasLogFiles returns false when provider returns empty")
    @MainActor
    func hasLogFilesReturnsFalseWhenEmpty() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: { [] }
        )

        #expect(viewModel.hasLogFiles == false)
    }

    @Test("hasLoggingSupport returns true when logging repository is set")
    @MainActor
    func hasLoggingSupportReturnsTrueWithRepo() {
        let repository = MockSettingsRepository()
        let loggingRepository = MockSDKLoggingRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository
        )

        #expect(viewModel.hasLoggingSupport == true)
    }

    @Test("hasLoggingSupport returns false when logging repository is nil")
    @MainActor
    func hasLoggingSupportReturnsFalseWithoutRepo() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: nil
        )

        #expect(viewModel.hasLoggingSupport == false)
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

    @Test("Cancel dismisses without saving")
    func cancelDismissesWithoutSaving() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Modify values
        viewModel.settingsPreference.videoResolution = .high
        viewModel.settingsPreference.maxAudioBitrate = 128_000

        // Cancel
        viewModel.cancel()

        // Verify no save happened
        #expect(repository.saveCallCount == 0)
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

    @Test("Log file provider exposes shareable URLs")
    func logFileProviderExposesURLs() {
        let repository = MockSettingsRepository()
        let logFileURLs = [
            URL(fileURLWithPath: "/Users/iujie/Documents/demos/vonage-video-ios-app/VERA/logs/sdk.log")
        ]
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: { logFileURLs }
        )

        #expect(viewModel.logFileURLs == logFileURLs)
        #expect(viewModel.hasLogFiles == true)
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
