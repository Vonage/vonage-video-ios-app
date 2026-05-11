//
//  Created by Vonage on 10/5/26.
//

import Combine
import Foundation

#if BACKGROUND_EFFECTS_ENABLED && SETTINGS_ENABLED
    import VERABackgroundEffects
    import VERASettings

    /// Subscribes to the publisher settings repository and exposes synchronous accessors
    /// for the background-effects provider and Apple Vision quality.
    ///
    /// The Settings module owns its own typed enums (`SettingsBackgroundProvider`,
    /// `SettingsAppleVisionQuality`); the BackgroundEffects module owns parallel enums
    /// (`BackgroundEffectProvider`, `AppleVisionSegmentationQuality`). Neither module
    /// depends on the other — this adapter, living in the composition root, bridges
    /// the two so the blur button view model can be configured with synchronous
    /// closures.
    final class BackgroundEffectsPreferencesAdapter {

        private(set) var currentProvider: BackgroundEffectProvider = .vonage
        private(set) var currentVisionQuality: AppleVisionSegmentationQuality = .fast
        private var cancellable: AnyCancellable?

        init(repository: PublisherSettingsRepository) {
            // `preferencesPublisher` is backed by a `CurrentValueSubject`, so the initial
            // value is delivered synchronously on subscribe — `currentProvider` and
            // `currentVisionQuality` are valid as soon as the init returns. We also
            // forward `performanceHUDEnabled` to the shared performance tracker so the
            // HUD view's visibility tracks the Settings toggle.
            cancellable = repository.preferencesPublisher
                .sink { preferences in
                    self.currentProvider = preferences.backgroundProvider.asBackgroundEffectProvider
                    self.currentVisionQuality = preferences.appleVisionQuality.asAppleVisionSegmentationQuality
                    TransformPerformanceTracker.shared.setVisible(preferences.performanceHUDEnabled)
                }
        }

        func getProvider() -> BackgroundEffectProvider {
            currentProvider
        }

        func getVisionQuality() -> AppleVisionSegmentationQuality {
            currentVisionQuality
        }
    }

    // MARK: - Settings → BackgroundEffects mapping

    extension SettingsBackgroundProvider {
        /// Maps to the matching VERABackgroundEffects enum. Raw values align by design.
        fileprivate var asBackgroundEffectProvider: BackgroundEffectProvider {
            BackgroundEffectProvider(rawValue: rawValue) ?? .vonage
        }
    }

    extension SettingsAppleVisionQuality {
        /// Maps to the matching VERABackgroundEffects enum. Raw values align by design.
        fileprivate var asAppleVisionSegmentationQuality: AppleVisionSegmentationQuality {
            AppleVisionSegmentationQuality(rawValue: rawValue) ?? .fast
        }
    }
#endif
