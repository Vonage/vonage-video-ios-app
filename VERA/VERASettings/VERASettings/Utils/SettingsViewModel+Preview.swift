//
//  Created by Vonage on 4/3/26.
//

#if DEBUG
    import Combine
    import Foundation
    import VERADomain

    // MARK: - Mock Repository

    final class PreviewSettingsRepository: PublisherSettingsRepository {

        private nonisolated let subject = CurrentValueSubject<PublisherSettingsPreferences, Never>(.default)

        nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
            subject.eraseToAnyPublisher()
        }

        func getPreferences() async -> PublisherSettingsPreferences {
            subject.value
        }

        func save(_ preferences: PublisherSettingsPreferences) async {
            subject.send(preferences)
        }

        func reset() async {
            subject.send(.default)
        }

        func saveNoAsync(_ preferences: PublisherSettingsPreferences) {
            subject.send(preferences)
        }
    }

    // MARK: - Mock SDKLoggingRepository

    final class PreviewSDKLoggingRepository: SDKLoggingRepository {
        func loadPreferencesSync() -> SDKLoggingPreferences {
            return subject.value
        }

        func savePreferencesSync(_ preferences: SDKLoggingPreferences) {
            subject.send(preferences)
        }

        private nonisolated let subject = CurrentValueSubject<SDKLoggingPreferences, Never>(.default)

        // Conforming to the Publisher requirement
        var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> {
            subject.eraseToAnyPublisher()
        }

        func save(_ preferences: SDKLoggingPreferences) async {
            subject.send(preferences)
        }

        func getPreferences() async -> SDKLoggingPreferences {
            subject.value
        }

        func reset() async {
            subject.send(.default)
        }
    }

    // MARK: - Mock GetLogFileURLsUseCase
    final class PreviewGetLogFileURLsUseCase: GetLogFileURLsUseCase {

        var urls: [URL] = []

        func callAsFunction() -> [URL] {
            urls
        }
    }


    // MARK: - Preview Instances

    extension SettingsViewModel {

        static var preview: SettingsViewModel {
            SettingsViewModel(
                repository: PreviewSettingsRepository(),
                loggingRepository: PreviewSDKLoggingRepository(),
                getLogFileURLsUseCase: PreviewGetLogFileURLsUseCase())
        }

        static var previewWithStatsEnabled: SettingsViewModel {
            let repo = PreviewSettingsRepository()
            var prefs = PublisherSettingsPreferences.default
            prefs.senderStatsEnabled = true
            return SettingsViewModel(
                repository: repo,
                settingsPreference: prefs,
                loggingRepository: PreviewSDKLoggingRepository(),
                getLogFileURLsUseCase: PreviewGetLogFileURLsUseCase())
        }

        static var previewWithLoggingEnabled: SettingsViewModel {
            SettingsViewModel(
                repository: PreviewSettingsRepository(),
                loggingRepository: PreviewSDKLoggingRepository(),
                initialLoggingPreferences: SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .debug),
                getLogFileURLsUseCase: PreviewGetLogFileURLsUseCase()
            )
        }
    }
#endif
