//
//  Created by Vonage on 02/03/2026.
//

import VERADomain

/// Default implementation of ``PublisherAdvancedSettingsUseCase`` that retrieves
/// publisher configuration from the settings repository.
///
/// This use case bridges the gap between the Settings module and the publisher
/// creation flow by transforming ``PublisherSettingsPreferences`` into
/// ``PublisherAdvancedSettings``.
public final class DefaultAdvancedSettingsUseCase: PublisherAdvancedSettingsUseCase {

    // MARK: - Dependencies

    /// The repository that persists and retrieves user settings.
    private let publisherSettingsRepository: PublisherSettingsRepository

    // MARK: - Init

    /// Creates a new advanced settings use case.
    ///
    /// - Parameter publisherSettingsRepository: The repository to read settings from.
    public init(publisherSettingsRepository: PublisherSettingsRepository) {
        self.publisherSettingsRepository = publisherSettingsRepository
    }

    // MARK: - PublisherAdvancedSettingsUseCase

    /// Retrieves the current publisher advanced settings.
    ///
    /// - Returns: The publisher advanced settings derived from user preferences.
    public func callAsFunction() async -> PublisherAdvancedSettings {
        await publisherSettingsRepository.getPreferences().toPublisherAdvancedSettings()
    }
}
