//
//  Created by Vonage on 14/8/26.
//

import Combine
import VERADomain

/// A fake auth state manager used by E2E tests to bypass real identity provider flows.
@MainActor
public final class E2EAuthStateManager: AuthStateDataSource {
    private let subject = CurrentValueSubject<AuthState, Never>(.notAuthenticated)

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        subject.eraseToAnyPublisher()
    }

    public init() {}

    public func signIn() {
        subject.send(.authenticated(AuthenticatedUser(name: "E2E Test User")))
    }

    public func signOut() {
        subject.send(.notAuthenticated)
    }
}
