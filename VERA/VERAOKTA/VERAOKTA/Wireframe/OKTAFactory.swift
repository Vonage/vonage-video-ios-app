//
//  Created by Vonage on 12/8/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Creates views and view models for the OKTA authentication flow.
public final class OKTAFactory {

    private let authManager: OktaAuthManager

    public init(authManager: OktaAuthManager) {
        self.authManager = authManager
    }

    @MainActor
    public func makeSignInView(
        providers: [IDProvider],
        onProviderSelected: @escaping (IDProvider) async throws -> Void
    ) -> some View {
        SignInView(providers: providers, onProviderSelected: onProviderSelected)
    }

    @MainActor
    public func makeNavBarAuthButtonViewModel(
        onLoginTapped: @escaping () -> Void,
        onLogoutTapped: @escaping () async -> Void
    ) -> NavBarAuthButtonViewModel {
        NavBarAuthButtonViewModel(
            authStateDataSource: authManager,
            onLoginTapped: onLoginTapped,
            onLogoutTapped: onLogoutTapped
        )
    }

    public var authenticationManager: OktaAuthManager {
        authManager
    }
}
