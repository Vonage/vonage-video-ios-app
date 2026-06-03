//
//  Created by Vonage on 25/2/26.
//

import Combine
import Foundation
import os.log

/// Constants used throughout the settings system.
private enum SettingsConstants {
    /// The default maximum audio bitrate in bits per second (500 kbps).
    static let defaultMaxAudioBitrate: Int32 = 500_000
}

/// Drives ``SettingsView`` by reading and writing publisher setting preferences.
///
/// Changes are auto-saved to the repository as the user edits, with a short
/// debounce to batch rapid changes (e.g. slider drags). Downstream consumers
/// react immediately via ``PublisherSettingsRepository/preferencesPublisher``.
///
public final class SettingsViewModel: ObservableObject {

    // MARK: - Published state

    /// Controls whether the settings view is currently presented.
    /// Set to `false` to dismiss the settings sheet.
    @Published public var isPresented: Bool = true

    /// The current publisher settings preferences being edited.
    /// Changes are auto-persisted after a short debounce.
    @Published public var settingsPreference: PublisherSettingsPreferences

    /// Whether SDK logging is enabled.
    @Published public var isLoggingEnabled: Bool

    /// The selected SDK logging level.
    @Published public var sdkLogLevel: SDKLogLevel

    /// Controls presentation of the iOS share sheet for log files.
    @Published public var showShareSheet: Bool = false

    /// Controls presentation of the alert shown when no log files are available.
    @Published public var showNoLogsAlert: Bool = false

    /// The current codec mode preference (auto or manual).
    public var codecMode: SettingsCodecMode {
        settingsPreference.codecPreference.mode
    }

    /// The user-defined order of video codecs.
    /// When manual mode is enabled, this order determines codec priority.
    public var orderedCodecs: [SettingsVideoCodec] {
        settingsPreference.codecPreference.orderedCodecs
    }

    /// The video bitrate preset (default or custom).
    public var videoBitratePreset: SettingsVideoBitratePreset {
        settingsPreference.videoBitratePreset
    }

    /// The custom maximum video bitrate in bits per second.
    /// Only used when `videoBitratePreset` is set to custom.
    public var customMaxVideoBitrate: Int32 {
        settingsPreference.maxVideoBitrate
    }

    /// A human-readable formatted string of the current video bitrate.
    /// Returns an empty string if formatting fails.
    public var videoBitrateFormatted: String {
        SettingsFormatter.formatBandwidth(customMaxVideoBitrate) ?? ""
    }

    /// The maximum audio bitrate in bits per second.
    public var maxAudioBitrate: Int32 {
        settingsPreference.maxAudioBitrate
    }

    /// A human-readable formatted string of the current audio bitrate.
    /// Returns an empty string if formatting fails.
    public var maxAudioBitrateFormatted: String {
        SettingsFormatter.formatBandwidth(maxAudioBitrate) ?? ""
    }

    /// Indicates whether sender statistics are enabled for debugging.
    public var senderStatsEnabled: Bool {
        settingsPreference.senderStatsEnabled
    }

    /// Whether SDK logging support is configured.
    /// When `false`, the logging UI section should be hidden.
    public var hasLoggingSupport: Bool {
        loggingRepository != nil
    }

    /// Current log file URLs returned by the injected provider.
    public var logFileURLs: [URL] {
        logFileURLProvider?() ?? []
    }

    /// Whether the logging configuration has been modified from its initial state.
    /// Used by the UI to show a restart-required note.
    public var loggingSettingsChanged: Bool {
        loggingRepository != nil
            && (isLoggingEnabled != initialLoggingEnabled || sdkLogLevel != initialLogLevel)
    }

    /// Whether any log files are currently available to share.
    public var hasLogFiles: Bool {
        !logFileURLs.isEmpty
    }

    /// Attempts to share log files. Shows the share sheet if files exist,
    /// or an alert if no log files are available yet.
    public func sendLogs() {
        if hasLogFiles {
            showShareSheet = true
        } else {
            showNoLogsAlert = true
        }
    }

    // MARK: - Dependencies

    /// Logger for recording errors during settings persistence.
    private let logger = Logger(
        subsystem: "com.vonage.vera.settings",
        category: "SettingsViewModel"
    )

    /// The repository responsible for persisting and retrieving publisher settings.
    private let repository: PublisherSettingsRepository

    /// Repository for reading and writing SDK logging preferences.
    private let loggingRepository: SDKLoggingRepository?

    /// Supplies URLs for currently available log files.
    private let logFileURLProvider: (() -> [URL])?

    /// Tracks the original persisted logging toggle to decide cleanup behavior.
    private var initialLoggingEnabled: Bool = false

    /// Tracks the original persisted log level to detect changes.
    private var initialLogLevel: SDKLogLevel = .debug
    /// Cancellables for auto-save subscriptions.
    private var autoSaveCancellables: Set<AnyCancellable> = []

    /// In-flight auto-save task. Cancelled before each new save to
    /// prevent overlapping writes that could overwrite newer data.
    private var autoSaveTask: Task<Void, Never>?

    /// Debounce interval for auto-save (seconds).
    private let autoSaveDebounce: TimeInterval

    /// Tracks whether the view model has been initialized.
    private var isInitialized: Bool = false


    /// Called after each persistence attempt (success or failure).
    /// Used by tests to synchronise with the auto-save pipeline.
    var onDidSave: (@Sendable () -> Void)?

    // MARK: - Init

    /// Creates a new settings view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to use for persisting and retrieving settings.
    ///   - settingsPreference: The initial settings preferences. Defaults to `.default`.
    ///   - loggingRepository: Repository for SDK logging preferences. Defaults to `nil`.
    ///   - initialLoggingPreferences: Synchronously loaded logging preferences for immediate UI state. Defaults to `.default`.
    ///   - logFileURLProvider: Provider for shareable log file URLs. Defaults to `nil`.
    ///   - autoSaveDebounce: Debounce interval for auto-save in seconds. Defaults to `0.3`.
    public init(
        repository: PublisherSettingsRepository,
        settingsPreference: PublisherSettingsPreferences = .default,
        autoSaveDebounce: TimeInterval = 0.3,
        loggingRepository: SDKLoggingRepository? = nil,
        initialLoggingPreferences: SDKLoggingPreferences = .default,
        logFileURLProvider: (() -> [URL])? = nil
    ) {
        self.repository = repository
        self.settingsPreference = settingsPreference
        self.autoSaveDebounce = autoSaveDebounce
        self.loggingRepository = loggingRepository
        self.logFileURLProvider = logFileURLProvider
        self.isLoggingEnabled = initialLoggingPreferences.isLoggingEnabled
        self.sdkLogLevel = initialLoggingPreferences.logLevel
        self.initialLoggingEnabled = initialLoggingPreferences.isLoggingEnabled
        self.initialLogLevel = initialLoggingPreferences.logLevel
    }

    // MARK: - Actions

    /// Reorders the codec list by moving items from source indices to a destination index.
    ///
    /// - Parameters:
    ///   - source: The index set of items to move.
    ///   - destination: The destination index for the moved items.
    public func sortingCodec(source: IndexSet, destination: Int) {
        settingsPreference.codecPreference.orderedCodecs.move(fromOffsets: source, toOffset: destination)
    }

    /// Updates the maximum video bitrate.
    ///
    /// - Parameter maxVideoBitrate: The new maximum video bitrate in bits per second.
    public func setMaxVideorate(_ maxVideoBitrate: Double) {
        settingsPreference.maxVideoBitrate = Int32(maxVideoBitrate)
    }

    /// Updates the maximum audio bitrate.
    ///
    /// - Parameter maxAudioBitrate: The new maximum audio bitrate in bits per second.
    public func setMaxAudioBitrate(_ maxAudioBitrate: Double) {
        settingsPreference.maxAudioBitrate = Int32(maxAudioBitrate)
    }

    /// Loads the current settings preferences from the repository and starts
    /// the auto-save pipeline.
    ///
    /// This should be called when the view appears to ensure the latest values
    /// are displayed. Subsequent changes are automatically persisted.
    /// Subsequent calls are ignored to prevent re-initialization.
    @MainActor
    public func setup() async {
        guard !isInitialized else { return }
        isInitialized = true

        settingsPreference = await repository.getPreferences()

        if let loggingRepository {
            let loggingPreferences = await loggingRepository.getPreferences()
            isLoggingEnabled = loggingPreferences.isLoggingEnabled
            sdkLogLevel = loggingPreferences.logLevel
            initialLoggingEnabled = loggingPreferences.isLoggingEnabled
            initialLogLevel = loggingPreferences.logLevel
        }
        startAutoSave()
    }

    /// Dismisses the settings view after ensuring all pending changes are saved.
    ///
    /// This method persists any changes that might still be in the debounce window
    /// before dismissing, ensuring no data loss on quick dismissals.
    @MainActor
    public func dismiss() async {
        // Save any pending changes that haven't been auto-saved yet
        await persistCurrentState()
        await persistLoggingState()
        isPresented = false

    }

    /// Reverts all settings to their default values and persists the changes.
    /// This resets both the local state and the persisted preferences.
    public func resetToDefaults() {
        Task { @MainActor in
            await repository.reset()
            setAsDefault()
        }
    }

    // MARK: - Private

    /// Sets up Combine pipelines that auto-save preferences after a debounce.
    ///
    /// Two pipelines run independently:
    /// 1. **Settings pipeline** – watches `$settingsPreference` and persists both
    ///    publisher settings and logging preferences on every debounced change.
    /// 2. **Logging pipeline** – watches `$isLoggingEnabled` and `$sdkLogLevel`
    ///    so that toggling the logging switch or changing the log level triggers
    ///    persistence and a restart alert even when no other setting changes.
    ///
    /// `dropFirst()` avoids re-saving the value just loaded from the repository.
    /// `removeDuplicates()` prevents unnecessary writes when the value hasn't changed.
    /// `debounce` batches rapid changes (e.g. slider drags) to avoid excessive writes.
    private func startAutoSave() {
        $settingsPreference
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(autoSaveDebounce), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleAutoSave()
            }
            .store(in: &autoSaveCancellables)

        guard loggingRepository != nil else { return }

        $isLoggingEnabled
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(autoSaveDebounce), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleAutoSave()
            }
            .store(in: &autoSaveCancellables)

        $sdkLogLevel
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .seconds(autoSaveDebounce), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleAutoSave()
            }
            .store(in: &autoSaveCancellables)
    }

    /// Coalesces multiple pipeline triggers into a single auto-save task.
    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task {
            await persistCurrentState()
            await persistLoggingState()
        }
    }

    /// Persists all current field values to the repository.
    /// Sanitizes the settings before saving to ensure data consistency.
    /// Logs any errors that occur during persistence.
    private func persistCurrentState() async {
        let sanitized = sanitized(settingsPreference)
        do {
            try await repository.save(sanitized)
        } catch {
            logger.error("Failed to save settings preferences: \(error.localizedDescription)")
        }
        onDidSave?()
    }

    /// Persists the current logging values. When the logging toggle or log
    /// level has changed, sets ``SDKLoggingPreferences/pendingLogCleanup``
    /// so that log files are cleared on the next app launch.
    private func persistLoggingState() async {
        guard let loggingRepository else { return }

        let loggingToggleChanged = isLoggingEnabled != initialLoggingEnabled
        let logLevelChanged = sdkLogLevel != initialLogLevel

        let preferences = SDKLoggingPreferences(
            isLoggingEnabled: isLoggingEnabled,
            logLevel: sdkLogLevel,
            pendingLogCleanup: loggingToggleChanged || logLevelChanged
        )

        await loggingRepository.save(preferences)
    }

    /// Returns a sanitized copy of the preferences to ensure data consistency.
    /// Resets the maximum video bitrate to 0 when using the default preset.
    /// Does not modify the original to avoid triggering another auto-save cycle.
    private func sanitized(_ preferences: PublisherSettingsPreferences) -> PublisherSettingsPreferences {
        var sanitized = preferences
        if sanitized.videoBitratePreset == .default {
            sanitized.maxVideoBitrate = 0
        }
        return sanitized
    }

    /// Resets the local settings preference to default values.
    /// This only affects the local state, not the persisted values.
    private func setAsDefault() {
        settingsPreference = PublisherSettingsPreferences.default
    }
}
