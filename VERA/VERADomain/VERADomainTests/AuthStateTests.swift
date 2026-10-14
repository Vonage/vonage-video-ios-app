//
//  Created by Vonage on 15/8/26.
//

import Testing

@testable import VERADomain

@Suite("AuthState Tests")
struct AuthStateTests {

    @Test("isAuthenticated returns true when authenticated")
    func isAuthenticatedTrue() {
        let sut = AuthState.authenticated(AuthenticatedUser(name: "Alice"))

        #expect(sut.isAuthenticated)
    }

    @Test("isAuthenticated returns false when notAuthenticated")
    func isAuthenticatedFalse() {
        let sut = AuthState.notAuthenticated

        #expect(!sut.isAuthenticated)
    }

    @Test("user returns the AuthenticatedUser when authenticated")
    func userReturnsUser() {
        let user = AuthenticatedUser(name: "Bob")
        let sut = AuthState.authenticated(user)

        #expect(sut.user == user)
    }

    @Test("user returns nil when notAuthenticated")
    func userReturnsNil() {
        let sut = AuthState.notAuthenticated

        #expect(sut.user == nil)
    }

    @Test("Authentication state retains its value across task boundaries")
    func statesAcrossTasks() async {
        let states: [AuthState] = [
            .notAuthenticated,
            .authenticated(AuthenticatedUser(name: "Alice")),
            .authenticated(AuthenticatedUser()),
        ]

        for state in states {
            let received = await Task.detached { state }.value

            #expect(received == state)
        }
    }
}
