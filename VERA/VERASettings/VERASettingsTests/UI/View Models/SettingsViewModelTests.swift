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

    /// Waits deterministically for the auto-save pipeline to complete.
    /// Sets the `onDidSave` callback, executes `perform`, then suspends
    /// until `persistCurrentState()` finishes and invokes the callback.
    private func awaitAutoSave(
        on viewModel: SettingsViewModel,
        while perform: () -> Void
    ) async {
        await withCheckedContinuation { continuation in
            viewModel.onDidSave = { continuation.resume() }
            perform()
        }
        viewModel.onDidSave = nil
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default preferences")
    func initializesWithDefaults() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.settingsPreference.videoResolution == .medium)
        #expect(viewModel.settingsPreference.videoFrameRate == .fps30)
        #expect(viewModel.settingsPreference.codecPreference.mode == .automatic)
        #expect(viewModel.settingsPreference.audioBitratePreference == .default)
        #expect(viewModel.maxAudioBitrate == nil)
        #expect(viewModel.audioBitrateMode == .default)
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
            audioBitratePreference: .custom(128_000),
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
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(128_000))
        #expect(viewModel.audioBitrateMode == .custom)
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

    // MARK: - Auto-Save Tests

    @Test("Setup ignores subsequent calls to prevent re-initialization")
    func setupIgnoresSubsequentCalls() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)

        // First setup
        await viewModel.setup()
        #expect(repository.getPreferencesCallCount == 1)

        // Modify repository state by saving new preferences
        var newPreferences = PublisherSettingsPreferences.default
        newPreferences.videoResolution = .high
        try await repository.save(newPreferences)

        // Second setup should be ignored (getPreferencesCallCount should not increment)
        await viewModel.setup()
        #expect(repository.getPreferencesCallCount == 1)  // Still 1, not 2

        // viewModel should retain the original value, not reload
        #expect(viewModel.settingsPreference.videoResolution == .medium)

        // Auto-save should still work (only one subscription was created)
        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoResolution = .low
        }
        #expect(repository.saveCallCount == 2)  // 1 from our manual save + 1 from auto-save
        #expect(repository.lastSavedPreferences?.videoResolution == .low)
    }

    @Test("Auto-save persists changes after setup")
    func autoSavePersistsAfterSetup() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoResolution = .high
            viewModel.settingsPreference.audioBitratePreference = .custom(128_000)
            viewModel.settingsPreference.senderStatsEnabled = true
        }

        // Verify persistence
        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.videoResolution == .high)
        #expect(repository.lastSavedPreferences?.audioBitratePreference == .custom(128_000))
        #expect(repository.lastSavedPreferences?.senderStatsEnabled == true)
    }

    @Test("Auto-save persists opusDtxEnabled toggle")
    func autoSavePersistsOpusDtx() async throws {
        // Start with a non-default value to ensure the test is meaningful
        var initialPrefs = PublisherSettingsPreferences.default
        initialPrefs.opusDtxEnabled = false
        let repository = MockSettingsRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.opusDtxEnabled = true
        }

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.opusDtxEnabled == true)
    }

    @Test("Auto-save with custom bitrate preset persists custom value")
    func autoSaveWithCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoBitratePreset = .custom
            viewModel.settingsPreference.maxVideoBitrate = 5_000_000
        }

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .custom)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 5_000_000)
    }

    @Test("Auto-save with non-custom bitrate preset saves zero for maxVideoBitrate")
    func autoSaveWithNonCustomBitrate() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoBitratePreset = .default
            viewModel.settingsPreference.maxVideoBitrate = 5_000_000
        }

        #expect(repository.lastSavedPreferences?.videoBitratePreset == .default)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 0)
    }

    @Test("Auto-save persists codec preference correctly")
    func autoSavePersistsCodecPreference() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.codecPreference.mode = .manual
            viewModel.settingsPreference.codecPreference.orderedCodecs = [.h264, .vp9, .vp8]
        }

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

        // Wait long enough for debounce to have fired if pipeline were active
        await delay()

        // No auto-save pipeline active
        #expect(repository.saveCallCount == 0)
    }

    @Test("Dismiss sets isPresented to false")
    func dismissSetsIsPresentedToFalse() async {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)
        await viewModel.setup()

        await viewModel.dismiss()

        #expect(viewModel.isPresented == false)
    }

    @Test("Dismiss saves pending changes before closing")
    func dismissSavesPendingChanges() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.3)
        await viewModel.setup()

        // Make a change but don't wait for auto-save debounce
        viewModel.settingsPreference.videoResolution = .high
        viewModel.settingsPreference.audioBitratePreference = .custom(128_000)

        // Dismiss immediately (before debounce fires)
        await viewModel.dismiss()

        // Verify changes were saved despite quick dismissal
        #expect(repository.saveCallCount >= 1)
        #expect(repository.lastSavedPreferences?.videoResolution == .high)
        #expect(repository.lastSavedPreferences?.audioBitratePreference == .custom(128_000))
        #expect(viewModel.isPresented == false)
    }

    @Test("Dismiss sanitizes settings before saving")
    func dismissSanitizesBeforeSaving() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.3)
        await viewModel.setup()

        // Set default preset but with a custom bitrate (invalid state)
        viewModel.settingsPreference.videoBitratePreset = .default
        viewModel.settingsPreference.maxVideoBitrate = 5_000_000

        // Dismiss immediately
        await viewModel.dismiss()

        // Verify sanitization occurred (maxVideoBitrate should be reset to 0)
        #expect(repository.lastSavedPreferences?.videoBitratePreset == .default)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 0)
    }

    @Test("Dismiss handles save errors gracefully without crashing")
    func dismissHandlesSaveErrorsGracefully() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.3)
        await viewModel.setup()

        // Make changes
        viewModel.settingsPreference.videoResolution = .high

        // Make save fail
        repository.shouldThrowOnSave = true

        // Dismiss should not crash despite save error (error is logged)
        await viewModel.dismiss()

        // Verify dismiss still sets isPresented to false
        #expect(viewModel.isPresented == false)
        // Verify save was attempted
        #expect(repository.saveCallCount == 1)
    }

    @Test("Auto-save handles repository errors gracefully")
    func autoSaveHandlesErrorsGracefully() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        // Make save fail
        repository.shouldThrowOnSave = true

        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoResolution = .high
        }

        // Verify save was attempted despite error (error is logged, not thrown)
        #expect(repository.saveCallCount >= 1)
    }

    @Test("loggingSettingsChanged is true when logging toggle changes")
    func loggingSettingsChangedWhenToggleChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        #expect(viewModel.loggingSettingsChanged == false)

        viewModel.isLoggingEnabled = true

        #expect(viewModel.loggingSettingsChanged == true)
    }

    @Test("Auto-save persists logging when toggle changes")
    func autoSavePersistsLoggingWhenToggleChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.isLoggingEnabled = true
        }
        await delay()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(
            loggingRepository.lastSavedPreferences
                == SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug, pendingLogCleanup: true)
        )
    }

    @Test("loggingSettingsChanged is true when only log level changes")
    func loggingSettingsChangedWhenLogLevelChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        #expect(viewModel.loggingSettingsChanged == false)

        viewModel.sdkLogLevel = .warn

        #expect(viewModel.loggingSettingsChanged == true)
    }

    @Test("Auto-save persists logging when log level changes")
    func autoSavePersistsLoggingWhenLogLevelChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.sdkLogLevel = .warn
        }
        await delay()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(
            loggingRepository.lastSavedPreferences
                == SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .warn, pendingLogCleanup: true)
        )
    }

    @Test("loggingSettingsChanged is false when logging settings are unchanged")
    func loggingSettingsChangedIsFalseWhenUnchanged() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        #expect(viewModel.loggingSettingsChanged == false)
    }

    @Test("Dismiss sets pendingLogCleanup when logging is re-enabled")
    func dismissSetsCleanupFlagWhenLoggingIsReenabled() async throws {
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
        await viewModel.dismiss()

        let saved = await loggingRepository.getPreferences()
        #expect(saved.pendingLogCleanup == true)
    }

    @Test("Dismiss sets pendingLogCleanup when log level changes")
    func dismissSetsCleanupFlagWhenLogLevelChanges() async throws {
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
        await viewModel.dismiss()

        let saved = await loggingRepository.getPreferences()
        #expect(saved.pendingLogCleanup == true)
    }

    @Test("Dismiss does not set pendingLogCleanup when nothing changes")
    func dismissDoesNotSetCleanupFlagWhenNothingChanges() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await viewModel.dismiss()

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
        await vm1.dismiss()

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
            audioBitratePreference: .custom(128_000),
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
        #expect(viewModel.maxAudioBitrate == nil)
        #expect(viewModel.videoBitratePreset == .default)
        #expect(viewModel.settingsPreference.publisherAudioFallbackEnabled == true)
        #expect(viewModel.settingsPreference.subscriberAudioFallbackEnabled == true)
        #expect(viewModel.settingsPreference.opusDtxEnabled == true)
        #expect(viewModel.senderStatsEnabled == false)
        #expect(viewModel.settingsPreference.degradationPreference == .notSet)
    }

    // MARK: - Dismiss Tests

    @Test("Dismiss saves pending changes in addition to auto-save")
    func dismissSavesAfterAutoSave() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        // Modify values and wait for auto-save
        await awaitAutoSave(on: viewModel) {
            viewModel.settingsPreference.videoResolution = .high
        }
        let saveCountAfterAutoSave = repository.saveCallCount

        // Make another change and dismiss immediately
        viewModel.settingsPreference.videoFrameRate = .fps15
        await viewModel.dismiss()

        // Verify dismiss triggered a save for the second change
        #expect(repository.saveCallCount >= saveCountAfterAutoSave + 1)
        #expect(repository.lastSavedPreferences?.videoResolution == .high)
        #expect(repository.lastSavedPreferences?.videoFrameRate == .fps15)
        #expect(viewModel.isPresented == false)
    }

    // MARK: - Formatted Properties Tests

    @Test("Audio bitrate formatted returns correct string")
    func audioBitrateFormatted() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.maxAudioBitrateFormatted == "Default")

        viewModel.settingsPreference.audioBitratePreference = .custom(40_000)
        let formatted1 = viewModel.maxAudioBitrateFormatted
        #expect(formatted1 == "40.0 kbps")

        viewModel.settingsPreference.audioBitratePreference = .custom(128_000)
        let formatted2 = viewModel.maxAudioBitrateFormatted
        #expect(formatted2 == "128.0 kbps")

        viewModel.settingsPreference.audioBitratePreference = .custom(1_000_000)
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

    @Test("logFileURLs returns empty when provider is nil")
    func logFileURLsReturnsEmptyWhenProviderIsNil() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            logFileURLProvider: nil
        )

        #expect(viewModel.logFileURLs.isEmpty)
    }

    // MARK: - Sorting & Bitrate Setters

    @Test("sortingCodec reorders codec list")
    func sortingCodecReordersCodecs() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.codecPreference.orderedCodecs = [.vp8, .h264, .vp9]
        viewModel.sortingCodec(source: IndexSet(integer: 2), destination: 0)

        #expect(viewModel.settingsPreference.codecPreference.orderedCodecs == [.vp9, .vp8, .h264])
    }

    @Test("setMaxVideorate updates maximum video bitrate")
    func setMaxVideorateSetsValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.setMaxVideorate(2_500_000)

        #expect(viewModel.settingsPreference.maxVideoBitrate == 2_500_000)
    }

    @Test("setMaxAudioBitrate updates maximum audio bitrate")
    func setMaxAudioBitrateSetsValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.setMaxAudioBitrate(96_000)

        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(96_000))
    }

    @Test("audioBitrateMode updates audio bitrate preference")
    func audioBitrateModeUpdatesPreference() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.audioBitrateMode = .custom
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(40_000))
        #expect(viewModel.audioBitrateMode == .custom)

        viewModel.audioBitrateMode = .default
        #expect(viewModel.settingsPreference.audioBitratePreference == .default)
        #expect(viewModel.maxAudioBitrate == nil)
        #expect(viewModel.audioBitrateMode == .default)
    }

    @Test("Default audio bitrate preference bridges to nil")
    func defaultAudioBitratePreferenceBridgesToNil() {
        let preferences = PublisherSettingsPreferences(audioBitratePreference: .default)

        let advancedSettings = preferences.toPublisherAdvancedSettings()

        #expect(advancedSettings.maxAudioBitrate == nil)
    }

    @Test("Custom audio bitrate preference bridges to value")
    func customAudioBitratePreferenceBridgesToValue() {
        let preferences = PublisherSettingsPreferences(audioBitratePreference: .custom(96_000))

        let advancedSettings = preferences.toPublisherAdvancedSettings()

        #expect(advancedSettings.maxAudioBitrate == 96_000)
    }

    @Test("audioBitrateMode custom preserves existing custom bitrate")
    func audioBitrateModeCustomPreservesExistingValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.audioBitratePreference = .custom(128_000)
        viewModel.audioBitrateMode = .custom

        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(128_000))
        #expect(viewModel.audioBitrateMode == .custom)
    }
   
    // MARK: - Dismiss & Logging Tests

    @Test("Dismiss does not persist logging when no changes made")
    func dismissDoesNotPersistLoggingWhenNoChanges() async {
        let repository = MockSettingsRepository()
        let loggingRepository = MockSDKLoggingRepository(
            initialPreferences: SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        )
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository
        )
        await viewModel.setup()

        // Change logging but then dismiss — logging should still be saved
        viewModel.isLoggingEnabled = true
        viewModel.sdkLogLevel = .error
        await viewModel.dismiss()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(viewModel.isPresented == false)
    }

    @Test("Dismiss without logging repository skips logging persistence")
    func dismissWithoutLoggingRepositorySkipsLogging() async {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: nil
        )

        viewModel.isLoggingEnabled = true
        await viewModel.dismiss()

        #expect(viewModel.loggingSettingsChanged == false)
        #expect(viewModel.isPresented == false)
    }

    @Test("showShareSheet defaults to false")
    func showShareSheetDefaultsToFalse() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.showShareSheet == false)
    }

    @Test("showNoLogsAlert defaults to false")
    func showNoLogsAlertDefaultsToFalse() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.showNoLogsAlert == false)
    }

    @Test("loggingSettingsChanged is false without logging repository")
    func loggingSettingsChangedIsFalseWithoutRepo() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.isLoggingEnabled = true
        #expect(viewModel.loggingSettingsChanged == false)
    }

    @Test("codecMode reflects preference mode")
    func codecModeReflectsPreference() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        #expect(viewModel.codecMode == .automatic)

        viewModel.settingsPreference.codecPreference.mode = .manual
        #expect(viewModel.codecMode == .manual)
    }

    @Test("orderedCodecs reflects preference codecs")
    func orderedCodecsReflectsPreference() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.codecPreference.orderedCodecs = [.h264, .vp9]
        #expect(viewModel.orderedCodecs == [.h264, .vp9])
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

        viewModel.settingsPreference.audioBitratePreference = .custom(256_000)
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(256_000))

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

    // MARK: - Computed Properties Tests

    @Test("codecMode returns the current codec preference mode")
    func codecModeReturnsCorrectValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Default is automatic
        #expect(viewModel.codecMode == .automatic)

        // Change to manual
        viewModel.settingsPreference.codecPreference.mode = .manual
        #expect(viewModel.codecMode == .manual)
    }

    @Test("orderedCodecs returns the codec preference list")
    func orderedCodecsReturnsCorrectValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Default order
        let defaultOrder = viewModel.orderedCodecs
        #expect(!defaultOrder.isEmpty)

        // Custom order
        let customOrder: [SettingsVideoCodec] = [.h264, .vp9, .vp8]
        viewModel.settingsPreference.codecPreference.orderedCodecs = customOrder
        #expect(viewModel.orderedCodecs == customOrder)
    }

    @Test("videoBitratePreset returns the current preset")
    func videoBitratePresetReturnsCorrectValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Default preset
        #expect(viewModel.videoBitratePreset == .default)

        // Change to custom
        viewModel.settingsPreference.videoBitratePreset = .custom
        #expect(viewModel.videoBitratePreset == .custom)

        // Change to bandwidth saver
        viewModel.settingsPreference.videoBitratePreset = .bandwidthSaver
        #expect(viewModel.videoBitratePreset == .bandwidthSaver)
    }

    @Test("customMaxVideoBitrate returns the current video bitrate")
    func customMaxVideoBitrateReturnsCorrectValue() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Default value
        #expect(viewModel.customMaxVideoBitrate == 500_000)

        // Custom value
        viewModel.settingsPreference.maxVideoBitrate = 2_000_000
        #expect(viewModel.customMaxVideoBitrate == 2_000_000)
    }

    // MARK: - Action Methods Tests

    @Test("sortingCodec reorders codec list correctly")
    func sortingCodecReordersCorrectly() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Set initial order
        viewModel.settingsPreference.codecPreference.orderedCodecs = [.vp8, .h264, .vp9]
        #expect(viewModel.orderedCodecs == [.vp8, .h264, .vp9])

        // Move first item (vp8) to last position
        viewModel.sortingCodec(source: IndexSet(integer: 0), destination: 3)
        #expect(viewModel.orderedCodecs == [.h264, .vp9, .vp8])

        // Move last item (vp8) to first position
        viewModel.sortingCodec(source: IndexSet(integer: 2), destination: 0)
        #expect(viewModel.orderedCodecs == [.vp8, .h264, .vp9])
    }

    @Test("sortingCodec handles multiple items")
    func sortingCodecHandlesMultipleItems() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        viewModel.settingsPreference.codecPreference.orderedCodecs = [.vp8, .h264, .vp9]

        // Move item 0 to the end
        viewModel.sortingCodec(source: IndexSet(integer: 0), destination: 3)
        #expect(viewModel.orderedCodecs == [.h264, .vp9, .vp8])

        // Move items 1 and 2 to the beginning
        viewModel.sortingCodec(source: IndexSet([1, 2]), destination: 0)
        #expect(viewModel.orderedCodecs == [.vp9, .vp8, .h264])
    }

    @Test("setMaxVideorate updates video bitrate correctly")
    func setMaxVideorateUpdatesCorrectly() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Set to 1.5 Mbps
        viewModel.setMaxVideorate(1_500_000.0)
        #expect(viewModel.settingsPreference.maxVideoBitrate == 1_500_000)

        // Set to 3 Mbps
        viewModel.setMaxVideorate(3_000_000.0)
        #expect(viewModel.settingsPreference.maxVideoBitrate == 3_000_000)

        // Set to zero
        viewModel.setMaxVideorate(0.0)
        #expect(viewModel.settingsPreference.maxVideoBitrate == 0)
    }

    @Test("setMaxVideorate converts Double to Int32")
    func setMaxVideorateConvertsDoubleToInt32() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Fractional value should be truncated
        viewModel.setMaxVideorate(1_234_567.89)
        #expect(viewModel.settingsPreference.maxVideoBitrate == 1_234_567)
    }

    @Test("setMaxAudioBitrate updates audio bitrate correctly")
    func setMaxAudioBitrateUpdatesCorrectly() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Set to 64 kbps
        viewModel.setMaxAudioBitrate(64_000.0)
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(64_000))

        // Set to 128 kbps
        viewModel.setMaxAudioBitrate(128_000.0)
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(128_000))

        // Set to zero
        viewModel.setMaxAudioBitrate(0.0)
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(6_000))
    }

    @Test("setMaxAudioBitrate converts Double to Int32")
    func setMaxAudioBitrateConvertsDoubleToInt32() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        // Fractional value should be truncated
        viewModel.setMaxAudioBitrate(96_123.45)
        #expect(viewModel.settingsPreference.audioBitratePreference == .custom(96_123))
    }

    @Test("setMaxAudioBitrate triggers auto-save after setup")
    func setMaxAudioBitrateTriggersSave() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            viewModel.setMaxAudioBitrate(128_000.0)
        }

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.audioBitratePreference == .custom(128_000))
    }

    @Test("setMaxVideorate triggers auto-save after setup")
    func setMaxVideorateTriggersSave() async throws {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository, autoSaveDebounce: 0.05)
        await viewModel.setup()

        await awaitAutoSave(on: viewModel) {
            // Set preset to custom so sanitization doesn't reset to 0
            viewModel.settingsPreference.videoBitratePreset = .custom
            viewModel.setMaxVideorate(2_000_000.0)
        }

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedPreferences?.maxVideoBitrate == 2_000_000)
    }

    // MARK: - Available Sections Tests

    @Test("availableSections includes logging when logging is supported")
    func availableSectionsIncludesLoggingWhenSupported() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: MockSDKLoggingRepository()
        )

        #expect(viewModel.availableSections.contains(.logging))
    }

    @Test("availableSections excludes logging when logging is not supported")
    func availableSectionsExcludesLoggingWhenNotSupported() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: nil
        )

        #expect(!viewModel.availableSections.contains(.logging))
    }

    @Test("availableSections always includes non-logging sections")
    func availableSectionsAlwaysIncludesNonLoggingSections() {
        let repository = MockSettingsRepository()
        let viewModel = SettingsViewModel(repository: repository)

        let sections = viewModel.availableSections
        #expect(sections.contains(.general))
        #expect(sections.contains(.video))
        #expect(sections.contains(.audio))
        #expect(sections.contains(.stats))
    }

    // MARK: - Dismiss Logging Persistence Tests

    @Test("Dismiss persists logging state")
    func dismissPersistsLoggingState() async {
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

        await viewModel.dismiss()

        #expect(loggingRepository.saveCallCount == 1)
        #expect(loggingRepository.lastSavedPreferences?.isLoggingEnabled == true)
        #expect(loggingRepository.lastSavedPreferences?.logLevel == .error)
        #expect(loggingRepository.lastSavedPreferences?.pendingLogCleanup == true)
        #expect(viewModel.isPresented == false)
    }

    @Test("Dismiss does not set pendingLogCleanup when logging unchanged")
    func dismissDoesNotSetPendingCleanupWhenUnchanged() async {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        await viewModel.dismiss()

        #expect(loggingRepository.lastSavedPreferences?.pendingLogCleanup == false)
    }

    // MARK: - loggingSettingsChanged Edge Cases

    @Test("loggingSettingsChanged becomes false when reverted to initial")
    func loggingSettingsChangedRevertedToInitial() async {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        viewModel.sdkLogLevel = .error
        #expect(viewModel.loggingSettingsChanged == true)

        viewModel.sdkLogLevel = .debug
        #expect(viewModel.loggingSettingsChanged == false)
    }

    @Test("loggingSettingsChanged detects both toggle and level changes")
    func loggingSettingsChangedDetectsBothChanges() async {
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
        #expect(viewModel.loggingSettingsChanged == true)

        viewModel.isLoggingEnabled = false
        #expect(viewModel.loggingSettingsChanged == false)

        viewModel.sdkLogLevel = .warn
        #expect(viewModel.loggingSettingsChanged == true)
    }

    @Test("Auto-save persists logging when both toggle and level change")
    func autoSavePersistsLoggingWhenBothChange() async throws {
        let repository = MockSettingsRepository()
        let initialPrefs = SDKLoggingPreferences(isLoggingEnabled: false, logLevel: .debug)
        let loggingRepository = MockSDKLoggingRepository(initialPreferences: initialPrefs)
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository,
            initialLoggingPreferences: initialPrefs
        )
        await viewModel.setup()

        // Change both settings before auto-save triggers
        viewModel.sdkLogLevel = .error
        viewModel.isLoggingEnabled = true

        // Wait for debounced auto-save to complete
        try await Task.sleep(for: .milliseconds(200))

        #expect(loggingRepository.saveCallCount >= 1)
        #expect(loggingRepository.lastSavedPreferences?.isLoggingEnabled == true)
        #expect(loggingRepository.lastSavedPreferences?.logLevel == .error)
        #expect(loggingRepository.lastSavedPreferences?.pendingLogCleanup == true)
    }

    @Test("Auto-save does not persist logging before setup")
    func autoSaveDoesNotPersistLoggingBeforeSetup() async {
        let repository = MockSettingsRepository()
        let loggingRepository = MockSDKLoggingRepository()
        let viewModel = SettingsViewModel(
            repository: repository,
            autoSaveDebounce: 0.05,
            loggingRepository: loggingRepository
        )

        viewModel.isLoggingEnabled = true
        await delay()

        #expect(loggingRepository.saveCallCount == 0)
    }
}
