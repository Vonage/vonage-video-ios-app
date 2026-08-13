//
//  Created by Vonage on 13/8/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERAOKTA

@MainActor
@Suite("OktaAuthManager Tests")
struct OktaAuthManagerTests {

    // MARK: - Initial State

    @Test("initial authState is notAuthenticated")
    func initialState() {
        let sut = OktaAuthManager()

        #expect(sut.authState == .notAuthenticated)
    }

    @Test("authStatePublisher emits notAuthenticated on subscription")
    func initialPublisherValue() {
        let sut = OktaAuthManager()
        var received: [AuthState] = []
        let cancellable = sut.authStatePublisher.sink { received.append($0) }

        #expect(received == [.notAuthenticated])
        _ = cancellable
    }

    // MARK: - Sign Out

    @Test("signOut sets state to notAuthenticated when no credential stored")
    func signOutWithoutCredential() async throws {
        let sut = OktaAuthManager()

        try await sut.signOut()

        #expect(sut.authState == .notAuthenticated)
    }

    @Test("signOut publishes notAuthenticated")
    func signOutPublishes() async throws {
        let sut = OktaAuthManager()
        var received: [AuthState] = []
        let cancellable = sut.authStatePublisher
            .dropFirst()
            .sink { received.append($0) }

        try await sut.signOut()

        #expect(received.contains(.notAuthenticated))
        _ = cancellable
    }

    // MARK: - Restore Session

    @Test("restoreSession sets notAuthenticated when no stored credential exists")
    func restoreSessionWithNoStoredCredential() {
        let sut = OktaAuthManager()

        sut.restoreSession()

        #expect(sut.authState == .notAuthenticated)
    }

    // MARK: - currentToken

    @Test("currentToken throws noCredential when not authenticated")
    func currentTokenThrowsWhenNoCredential() async {
        let sut = OktaAuthManager()

        await #expect(throws: OktaAuthError.noCredential) {
            try await sut.currentToken()
        }
    }

    // MARK: - OktaAuthError

    @Test("OktaAuthError has localized descriptions")
    func errorDescriptions() {
        #expect(OktaAuthError.signInFailed.errorDescription != nil)
        #expect(OktaAuthError.noCredential.errorDescription != nil)
        #expect(OktaAuthError.noAccessToken.errorDescription != nil)
    }

    @Test("OktaAuthError cases are distinct")
    func errorCasesDistinct() {
        let errors: [OktaAuthError] = [.signInFailed, .noCredential, .noAccessToken]
        let descriptions = errors.compactMap(\.errorDescription)
        #expect(Set(descriptions).count == 3)
    }
}
