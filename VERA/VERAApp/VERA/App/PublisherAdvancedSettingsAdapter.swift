//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation

#if SETTINGS_ENABLED
    import VERADomain
    import VERASettings

    final class PublisherAdvancedSettingsAdapter {

        var onChange: (() -> Void)?

        private var current: PublisherAdvancedSettings?
        private var cancellable: AnyCancellable?

        func setup(with preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never>) {
            cancellable =
                preferencesPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] preferences in
                    self?.apply(preferences)
                }
        }

        func get() -> PublisherAdvancedSettings? {
            current
        }

        private func apply(_ preferences: PublisherSettingsPreferences) {
            // Compare the mapped publisher settings: non-publisher preferences (stats overlay,
            // captions translation) must not reset the camera preview.
            let settings = preferences.toPublisherAdvancedSettings()
            let changed = current != nil && settings != current
            current = settings
            if changed {
                onChange?()
            }
        }
    }
#endif
