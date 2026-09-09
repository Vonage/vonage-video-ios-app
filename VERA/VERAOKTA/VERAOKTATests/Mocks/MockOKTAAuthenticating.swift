//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain

@testable import VERAOKTA

final class MockOKTAAuthenticating: OKTAAuthenticating, @unchecked Sendable {

    var authStateSubject = CurrentValueSubject<AuthState, Never>(.notAuthenticated)

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    var signInCallCount = 0
    var signOutCallCount = 0
    var currentTokenCallCount = 0

    var signInResult: Result<Void, Error> = .success(())
    var signOutResult: Result<Void, Error> = .success(())
    var currentTokenResult: Result<String, Error> = .success("mock-token")

    @MainActor func signIn(from anchor: ASPresentationAnchor) async throws {
        signInCallCount += 1
        switch signInResult {
        case .success:
            authStateSubject.send(
                .authenticated(AuthenticatedUser(name: "Test User"))
            )
        case .failure(let error):
            throw error
        }
    }

    func signOut() async throws {
        signOutCallCount += 1
        switch signOutResult {
        case .success:
            authStateSubject.send(.notAuthenticated)
        case .failure(let error):
            throw error
        }
    }

    func currentToken() async throws -> String {
        currentTokenCallCount += 1
        return try currentTokenResult.get()
    }
}
