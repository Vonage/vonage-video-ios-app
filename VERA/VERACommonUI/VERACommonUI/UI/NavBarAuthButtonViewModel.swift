//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain

/// ViewModel for `NavBarAuthButton` that observes the authentication state
/// from an `AuthStateDataSource` and delegates login actions to the composition root.
///
/// Fully decoupled from any specific identity provider (OKTA, etc.).
@MainActor
public final class NavBarAuthButtonViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var authState: AuthState = .notAuthenticated

    // MARK: - Actions

    /// Called when the user taps the button while not authenticated.
    /// The composition root should present the sign-in flow.
    public var onLoginTapped: () -> Void

    /// Called when the user requests to sign out.
    public var onLogoutTapped: () async -> Void

    // MARK: - Private

    private let authStateDataSource: AuthStateDataSource
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// - Parameters:
    ///   - authStateDataSource: A reactive source of authentication state.
    ///   - onLoginTapped: Action delegated to the composition root when login is requested.
    ///   - onLogoutTapped: Action delegated to the composition root when logout is requested.
    public init(
        authStateDataSource: AuthStateDataSource,
        onLoginTapped: @escaping () -> Void,
        onLogoutTapped: @escaping () async -> Void
    ) {
        self.authStateDataSource = authStateDataSource
        self.onLoginTapped = onLoginTapped
        self.onLogoutTapped = onLogoutTapped
    }

    // MARK: - Public

    /// Starts observing the authentication state. Call this when the view appears.
    public func startObserving() {
        authStateDataSource.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authState = state
            }
            .store(in: &cancellables)
    }
}
