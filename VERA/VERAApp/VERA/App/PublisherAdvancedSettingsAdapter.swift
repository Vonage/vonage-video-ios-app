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
    /// `setup(with:)` subscribes to the preferences publisher; because that
    /// publisher is a `CurrentValueSubject`, the latest value is captured as
    /// soon as `setup(with:)` returns. Used by
    /// `DefaultCameraPreviewProviderRepository` so the waiting-room camera
    /// preview honors the user's Settings → Video → Resolution choice instead
    /// of falling back to the SDK's capture default.
    ///
    /// When the persisted preferences change (after the initial load), `onChange`
    /// fires so the dependency container can invalidate the cached preview
    /// publisher and the next `getPublisher()` produces one with the new settings.
    ///
    /// The cached state is guarded by a lock: the preferences publisher may emit
    /// on the settings actor's executor while `get()` is called synchronously
    /// from the camera-preview path on an unrelated thread.
    final class PublisherAdvancedSettingsAdapter {

        /// Invoked whenever the underlying preferences change after the initial
        /// load. Always called on the main actor.
        var onChange: (() -> Void)?

        private let lock = NSLock()
        private var current: PublisherAdvancedSettings?
        private var lastPreferences: PublisherSettingsPreferences?
        private var cancellable: AnyCancellable?

        /// Subscribes to the preferences publisher. Call once after instantiation.
        func setup(with preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never>) {
            cancellable = preferencesPublisher
                .sink { [weak self] preferences in
                    guard let self else { return }
                    guard self.apply(preferences) else { return }
                    Task { @MainActor in
                        self.onChange?()
                    }
                }
        }

        /// The latest `PublisherAdvancedSettings`. Safe to call from any thread.
        func get() -> PublisherAdvancedSettings? {
            lock.lock()
            defer { lock.unlock() }
            return current
        }

        /// Stores the latest preferences under the lock and reports whether the
        /// change should notify observers (i.e. it isn't the initial emission).
        private func apply(_ preferences: PublisherSettingsPreferences) -> Bool {
            lock.lock()
            defer { lock.unlock() }
            let isInitial = lastPreferences == nil
            let changed = !isInitial && preferences != lastPreferences
            lastPreferences = preferences
            current = preferences.toPublisherAdvancedSettings()
            return changed
        }
    }
#endif
