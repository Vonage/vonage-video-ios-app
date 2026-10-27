//
//  Created by Vonage on 14/8/26.
//

import Combine
import VERADomain

/// A fake auth state manager used by E2E tests to bypass real identity provider flows.
public final class E2EAuthStateManager: OKTAAuthenticating {
    private let subject = CurrentValueRelay<AuthState, Never>(.notAuthenticated)

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        subject.publisher
    }

    public init() {}

    @MainActor
    public func signIn(from anchor: ASPresentationAnchor) async throws {
        subject.send(.authenticated(AuthenticatedUser(name: "E2E Test User")))
    }

    public func signOut() async throws {
        subject.send(.notAuthenticated)
    }

    public func currentToken() async throws -> String {
        "e2e-fake-token"
    }
}
