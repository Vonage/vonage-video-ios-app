//
//  Created by Vonage on 25/2/26.
//

import Combine
import Foundation

/// Constants used throughout the settings system.
private enum SettingsConstants {
    /// The default maximum audio bitrate in bits per second (500 kbps).
    static let defaultMaxAudioBitrate: Int32 = 500_000
}

/// Drives ``SettingsView`` by reading and writing publisher setting preferences.
///
/// All mutations go through ``PublisherSettingsRepository`` so that they are
/// immediately available to the publisher creation flow.
///
public final class SettingsViewModel: ObservableObject {

    // MARK: - Published state

    /// Controls whether the settings view is currently presented.
    /// Set to `false` to dismiss the settings sheet.
    @Published public var isPresented: Bool = true

    /// The current publisher settings preferences being edited.
    /// This is a published property that binds to the settings form.
    @Published public var settingsPreference: PublisherSettingsPreferences

    /// Whether SDK logging is enabled.
    @Published public var isLoggingEnabled: Bool

    /// The selected SDK logging level.
    @Published public var sdkLogLevel: SDKLogLevel

    /// Controls presentation of the iOS share sheet for log files.
    @Published public var showShareSheet: Bool = false

    /// Controls presentation of the alert shown when no log files are available.
    @Published public var showNoLogsAlert: Bool = false

    /// Controls presentation of the restart-required alert after logging changes.
    @Published public var showRestartAlert: Bool = false

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

    // MARK: - Init

    /// Creates a new settings view model.
    ///
    /// - Parameters:
    ///   - repository: The repository to use for persisting and retrieving settings.
    ///   - settingsPreference: The initial settings preferences. Defaults to `.default`.
    ///   - loggingRepository: Repository for SDK logging preferences. Defaults to `nil`.
    ///   - initialLoggingPreferences: Synchronously loaded logging preferences for immediate UI state. Defaults to `.default`.
    ///   - logFileURLProvider: Provider for shareable log file URLs. Defaults to `nil`.
    public init(
        repository: PublisherSettingsRepository,
        settingsPreference: PublisherSettingsPreferences = .default,
        loggingRepository: SDKLoggingRepository? = nil,
        initialLoggingPreferences: SDKLoggingPreferences = .default,
        logFileURLProvider: (() -> [URL])? = nil
    ) {
        self.repository = repository
        self.settingsPreference = settingsPreference
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

    /// Loads the current settings preferences from the repository.
    /// This should be called when the view appears to ensure the latest values are displayed.
    @MainActor
    public func setup() async {
        settingsPreference = await repository.getPreferences()

        if let loggingRepository {
            let loggingPreferences = await loggingRepository.getPreferences()
            isLoggingEnabled = loggingPreferences.isLoggingEnabled
            sdkLogLevel = loggingPreferences.logLevel
            initialLoggingEnabled = loggingPreferences.isLoggingEnabled
            initialLogLevel = loggingPreferences.logLevel
        }
    }

    /// Persists the current form values to the repository and dismisses the settings view.
    /// Shows a restart alert if logging settings changed, otherwise dismisses.
    /// SDK logging changes only take effect after the app is killed and reopened.
    /// Changes are fully saved before the view is dismissed.
    public func save() {
        Task { @MainActor in
            await persistCurrentState()
            await persistLoggingState()

            let loggingChanged =
                loggingRepository != nil
                && (isLoggingEnabled != initialLoggingEnabled || sdkLogLevel != initialLogLevel)

            if loggingChanged {
                showRestartAlert = true
            } else {
                isPresented = false
            }
        }
    }

    /// Reverts all settings to their default values and persists the changes.
    /// This resets both the local state and the persisted preferences.
    public func resetToDefaults() {
        Task { @MainActor in
            await repository.reset()
            setAsDefault()
        }
    }

    /// Dismisses the settings view without saving any changes.
    /// All modifications made during this session are discarded.
    public func cancel() {
        isPresented = false
    }

    /// Persists all current field values to the repository without dismissing the view.
    /// Sanitizes the settings before saving to ensure data consistency.
    private func persistCurrentState() async {
        await sanitize()
        try? await repository.save(settingsPreference)
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

    /// Sanitizes the settings to ensure data consistency.
    /// Resets the maximum video bitrate to 0 when using the default preset.
    @MainActor
    private func sanitize() async {
        if settingsPreference.videoBitratePreset == .default {
            settingsPreference.maxVideoBitrate = 0
        }
    }

    /// Resets the local settings preference to default values.
    /// This only affects the local state, not the persisted values.
    private func setAsDefault() {
        settingsPreference = PublisherSettingsPreferences.default
    }
}
