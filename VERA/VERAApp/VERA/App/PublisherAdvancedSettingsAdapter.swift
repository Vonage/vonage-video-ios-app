//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation

#if SETTINGS_ENABLED
    import VERADomain
    import VERASettings

    /// Subscribes to the publisher settings repository and exposes the latest
    /// `PublisherAdvancedSettings` synchronously.
    ///
    /// The underlying publisher emits the current value on subscribe (it's a
    /// `CurrentValueSubject`), so `current` is valid as soon as `init` returns.
    /// Used by `DefaultCameraPreviewProviderRepository` so the waiting-room
    /// camera preview honors the user's Settings → Video → Resolution choice
    /// instead of falling back to the SDK's capture default.
    ///
    /// When the persisted preferences change (after the initial load), `onChange`
    /// fires so the dependency container can invalidate the cached preview
    /// publisher and the next `getPublisher()` produces one with the new settings.
    final class PublisherAdvancedSettingsAdapter {

        private(set) var current: PublisherAdvancedSettings?
        /// Invoked whenever the underlying preferences change after the initial
        /// load. Always called on the main actor.
        var onChange: (() -> Void)?

        private var cancellable: AnyCancellable?
        private var lastPreferences: PublisherSettingsPreferences?

        init(repository: PublisherSettingsRepository) {
            cancellable = repository.preferencesPublisher
                .sink { [weak self] preferences in
                    guard let self = self else { return }
                    let isInitial = self.lastPreferences == nil
                    let changed = !isInitial && preferences != self.lastPreferences
                    self.lastPreferences = preferences
                    self.current = preferences.toPublisherAdvancedSettings()
                    guard changed else { return }
                    Task { @MainActor in
                        self.onChange?()
                    }
                }
        }

        func get() -> PublisherAdvancedSettings? {
            current
        }
    }
#endif
