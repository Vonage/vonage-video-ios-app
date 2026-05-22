//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation

#if SETTINGS_ENABLED
    import VERADomain
    import VERASettings

    /// Subscribes to the publisher settings repository and exposes the latest
    /// `PublisherAdvancedSettings` for synchronous reads.
    ///
    /// `setup(with:)` subscribes to the preferences publisher (a
    /// `CurrentValueSubject`) and caches each value as it arrives on the main
    /// queue. Used by `DefaultCameraPreviewProviderRepository` so the
    /// waiting-room camera preview honors the user's Settings → Video →
    /// Resolution choice instead of falling back to the SDK's capture default.
    ///
    /// When the persisted preferences change (after the initial load), `onChange`
    /// fires so the dependency container can invalidate the cached preview
    /// publisher and the next `getPublisher()` produces one with the new settings.
    ///
    /// Threading: `setup(with:)` delivers emissions on the main queue, and the
    /// only reader (`get()`) is invoked from the main-actor camera-preview
    /// path, so the cached state is only ever touched on the main thread — no
    /// explicit locking required.
    final class PublisherAdvancedSettingsAdapter {

        /// Invoked whenever the underlying preferences change after the initial
        /// load. Always called on the main thread.
        var onChange: (() -> Void)?

        private var current: PublisherAdvancedSettings?
        private var lastPreferences: PublisherSettingsPreferences?
        private var cancellable: AnyCancellable?

        /// Subscribes to the preferences publisher. Call once after instantiation.
        func setup(with preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never>) {
            cancellable =
                preferencesPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] preferences in
                    self?.apply(preferences)
                }
        }

        /// The latest `PublisherAdvancedSettings`. Read from the main thread.
        func get() -> PublisherAdvancedSettings? {
            current
        }

        /// Stores the latest preferences and notifies observers when the value
        /// actually changes (i.e. not the initial emission). Runs on the main
        /// thread via the `receive(on:)` upstream in `setup(with:)`.
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
