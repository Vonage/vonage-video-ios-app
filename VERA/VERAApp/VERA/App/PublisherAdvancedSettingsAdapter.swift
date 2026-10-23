//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation

#if SETTINGS_ENABLED
    import VERACommonUI
    import VERADomain
    import VERASettings

    @MainActor
    final class PublisherAdvancedSettingsAdapter {

        var onChange: (() -> Void)?

        private var current: PublisherAdvancedSettings?
        private var lastPreferences: PublisherSettingsPreferences?
        private var cancellable: AnyCancellable?

        func setup(with preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never>) {
            cancellable =
                preferencesPublisher
                .sinkOnMainActor { [weak self] preferences in
                    self?.apply(preferences)
                }
        }

        func get() -> PublisherAdvancedSettings? {
            current
        }

        private func apply(_ preferences: PublisherSettingsPreferences) {
            let isInitial = lastPreferences == nil
            let changed = !isInitial && preferences != lastPreferences
            lastPreferences = preferences
            current = preferences.toPublisherAdvancedSettings()
            if changed {
                onChange?()
            }
        }
    }
#endif
