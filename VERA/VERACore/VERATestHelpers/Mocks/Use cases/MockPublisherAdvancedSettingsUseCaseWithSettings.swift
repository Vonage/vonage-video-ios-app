//
//  Created by Vonage on 13/03/2026.
//

import VERADomain

public final class MockPublisherAdvancedSettingsUseCaseWithSettings: PublisherAdvancedSettingsUseCase {

    let settings: PublisherAdvancedSettings

    public init(settings: PublisherAdvancedSettings) {
        self.settings = settings
    }

    public func callAsFunction() async -> PublisherAdvancedSettings {
        settings
    }
}
