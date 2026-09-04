//
//  Created by Vonage on 13/8/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@testable import VERAOKTA

#if canImport(UIKit)
    import UIKit
#endif


@MainActor
@Suite("OktaAuthManager Tests")
struct OktaAuthManagerTests {

    // MARK: - Initial State

    @Test("initial authState is notAuthenticated")
    func initialState() {
        let (sut, _) = makeSUT()

        #expect(sut.authState == .notAuthenticated)
    }

    @Test("authStatePublisher emits notAuthenticated on subscription")
    func initialPublisherValue() {
        let (sut, _) = makeSUT()
        var received: [AuthState] = []
        let cancellable = sut.authStatePublisher.sink { received.append($0) }

        #expect(received == [.notAuthenticated])
        _ = cancellable
    }

    // MARK: - Sign In

    @Test("signIn publishes authenticated with user name on success")
    func signInSuccess() async throws {
        let (sut, provider) = makeSUT()
        provider.signInResult = .success(SignInResult(accessToken: "tok", userName: "Alice"))

        try await sut.signIn(from: makeAnchor())

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: "Alice")))
    }

    @Test("signIn publishes authenticated with nil name when provider returns nil name")
    func signInSuccessNilName() async throws {
        let (sut, provider) = makeSUT()
        provider.signInResult = .success(SignInResult(accessToken: "tok", userName: nil))

        try await sut.signIn(from: makeAnchor())

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: nil)))
    }

    @Test("signIn throws signInFailed when provider returns nil")
    func signInReturnsNil() async {
        let (sut, provider) = makeSUT()
        provider.signInResult = .success(nil)

        await #expect(throws: OktaAuthError.signInFailed) {
            try await sut.signIn(from: makeAnchor())
        }
        #expect(sut.authState == .notAuthenticated)
    }

    @Test("signIn rethrows provider error")
    func signInRethrows() async {
        let (sut, provider) = makeSUT()
        provider.signInResult = .failure(NSError(domain: "test", code: 42))

        await #expect(throws: Error.self) {
            try await sut.signIn(from: makeAnchor())
        }
        #expect(sut.authState == .notAuthenticated)
    }

    // MARK: - Sign Out

    @Test("signOut sets state to notAuthenticated")
    func signOut() async throws {
        let (sut, provider) = makeSUT()
        provider.signInResult = .success(SignInResult(accessToken: "tok", userName: "Bob"))
        try await sut.signIn(from: makeAnchor())

        try await sut.signOut()

        #expect(sut.authState == .notAuthenticated)
        #expect(provider.removeCredentialCallCount == 1)
    }

    @Test("signOut rethrows removeCredential error")
    func signOutRethrows() async {
        let (sut, provider) = makeSUT()
        provider.removeCredentialResult = .failure(NSError(domain: "test", code: 1))

        await #expect(throws: Error.self) {
            try await sut.signOut()
        }
    }

    // MARK: - Current Token

    @Test("currentToken returns token from provider")
    func currentToken() async throws {
        let (sut, provider) = makeSUT()
        provider.currentTokenResult = .success("access-123")

        let token = try await sut.currentToken()

        #expect(token == "access-123")
    }

    @Test("currentToken throws when provider throws")
    func currentTokenThrows() async {
        let (sut, provider) = makeSUT()
        provider.currentTokenResult = .failure(OktaAuthError.noCredential)

        await #expect(throws: OktaAuthError.noCredential) {
            try await sut.currentToken()
        }
    }

    // MARK: - Restore Session

    @Test("restoreSession publishes authenticated when provider has stored session")
    func restoreSessionSuccess() {
        let (sut, provider) = makeSUT()
        provider.restoreSessionResult = SignInResult(accessToken: "tok", userName: "Restored")

        sut.restoreSession()

        #expect(sut.authState == .authenticated(AuthenticatedUser(name: "Restored")))
    }

    @Test("restoreSession publishes notAuthenticated when no stored session")
    func restoreSessionNone() {
        let (sut, provider) = makeSUT()
        provider.restoreSessionResult = nil

        sut.restoreSession()

        #expect(sut.authState == .notAuthenticated)
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

    // MARK: - Helpers

    private func makeSUT() -> (OktaAuthManager, MockBrowserSignInProvider) {
        let provider = MockBrowserSignInProvider()
        let sut = OktaAuthManager(browserSignIn: provider)
        return (sut, provider)
    }

    private func makeAnchor() -> ASPresentationAnchor {
        #if canImport(UIKit)
            UIWindow()
        #else
            () as Any
        #endif
    }
}
