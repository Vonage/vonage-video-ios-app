//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain

@testable import VERAOKTA

/// Mock implementation of `OKTAAuthenticating` for unit tests.
@MainActor
final class MockOKTAAuthenticating: OKTAAuthenticating, AuthStateDataSource, ObservableObject {

    // MARK: - Published State

    @Published var authState: AuthState = .notAuthenticated

    // MARK: - AuthStateDataSource

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    // MARK: - Spying

    var signInCallCount = 0
    var signOutCallCount = 0
    var currentTokenCallCount = 0

    var signInResult: Result<Void, Error> = .success(())
    var signOutResult: Result<Void, Error> = .success(())
    var currentTokenResult: Result<String, Error> = .success("mock-token")

    // MARK: - OKTAAuthenticating

    func signIn(from anchor: ASPresentationAnchor) async throws {
        signInCallCount += 1
        switch signInResult {
        case .success:
            authState = .authenticated(
                AuthenticatedUser(email: "test@vonage.com", name: "Test User")
            )
        case .failure(let error):
            throw error
        }
    }

    func signOut() async throws {
        signOutCallCount += 1
        switch signOutResult {
        case .success:
            authState = .notAuthenticated
        case .failure(let error):
            throw error
        }
    }

    func currentToken() async throws -> String {
        currentTokenCallCount += 1
        return try currentTokenResult.get()
    }
}
