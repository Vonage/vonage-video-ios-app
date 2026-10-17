//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Creates the On-the-Go feature components.
///
/// Composition root for the module: holds the shared preferences repository,
/// the motion provider and the integrator configuration, and builds views and
/// view models wired to them.
@MainActor
public final class OnTheGoFactory {

    private let configuration: OnTheGoConfiguration
    private let preferences: OnTheGoPreferencesRepository
    private let motionProvider: MotionActivityProviding?

    /// Creates a factory with explicit dependencies.
    ///
    /// - Parameters:
    ///   - configuration: Integrator configuration.
    ///   - preferences: Repository storing the user's On-the-Go preferences.
    ///   - motionProvider: Motion sample source, or `nil` on platforms without
    ///     motion support (e.g. macOS).
    public init(
        configuration: OnTheGoConfiguration,
        preferences: OnTheGoPreferencesRepository,
        motionProvider: MotionActivityProviding?
    ) {
        self.configuration = configuration
        self.preferences = preferences
        self.motionProvider = motionProvider
    }

    /// Creates a factory with the default production dependencies: a
    /// `UserDefaults`-backed preferences repository and a
    /// `CoreMotionActivityProvider` on iOS (`nil` elsewhere).
    public static func makeDefault(
        configuration: OnTheGoConfiguration = .init()
    ) -> OnTheGoFactory {
        #if canImport(CoreMotion) && !os(macOS)
            let provider: MotionActivityProviding? = CoreMotionActivityProvider()
        #else
            let provider: MotionActivityProviding? = nil
        #endif
        return OnTheGoFactory(
            configuration: configuration,
            preferences: UserDefaultsOnTheGoPreferencesRepository(),
            motionProvider: provider
        )
    }

    /// Creates the On-the-Go view model.
    public func makeViewModel(actions: OnTheGoCallActions) -> OnTheGoViewModel {
        OnTheGoViewModel(
            configuration: configuration,
            preferences: preferences,
            motionProvider: motionProvider,
            actions: actions
        )
    }

    /// Creates the full-screen On-the-Go view.
    public func makeView(viewModel: OnTheGoViewModel) -> OnTheGoView {
        OnTheGoView(viewModel: viewModel)
    }

    /// Creates the non-blocking suggestion banner.
    public func makeSuggestionBanner(viewModel: OnTheGoViewModel) -> OnTheGoSuggestionBanner {
        OnTheGoSuggestionBanner(viewModel: viewModel)
    }

    /// Creates the settings row (embed inside a `Form`/`Section` host).
    public func makeSettingsRow() -> OnTheGoSettingsRow {
        OnTheGoSettingsRow(
            preferences: preferences,
            isMotionPermissionDenied: [.denied, .restricted]
                .contains(motionProvider?.authorizationStatus ?? .authorized)
        )
    }
}
