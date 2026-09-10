//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain

@MainActor
public final class NavBarAuthButtonViewModel: ObservableObject {

    @Published public private(set) var authState: AuthState = .notAuthenticated

    /// Controls presentation of the account menu sheet.
    @Published public var showAccountMenu = false

    /// Whether a sign-out is in progress (disables the sign-out button).
    @Published public private(set) var isLoggingOut = false

    public var onLoginTapped: () -> Void
    public var onLogoutTapped: () async -> Void

    private let authStateDataSource: AuthStateDataSource

    public init(
        authStateDataSource: AuthStateDataSource,
        initialState: AuthState = .notAuthenticated,
        onLoginTapped: @escaping () -> Void,
        onLogoutTapped: @escaping () async -> Void
    ) {
        self.authStateDataSource = authStateDataSource
        self.authState = initialState
        self.onLoginTapped = onLoginTapped
        self.onLogoutTapped = onLogoutTapped
    }

    public func startObserving() {
        authStateDataSource.authStatePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$authState)
    }

    /// Handles a tap on the nav-bar auth button: signed-out users are sent to login,
    /// signed-in users get the account menu.
    public func authButtonTapped() {
        switch authState {
        case .notAuthenticated:
            onLoginTapped()
        case .authenticated:
            showAccountMenu = true
        }
    }

    /// Performs sign-out, keeping the sign-out button disabled until it completes and
    /// dismissing the account menu afterwards.
    public func signOut() async {
        isLoggingOut = true
        await onLogoutTapped()
        isLoggingOut = false
        showAccountMenu = false
    }
}
