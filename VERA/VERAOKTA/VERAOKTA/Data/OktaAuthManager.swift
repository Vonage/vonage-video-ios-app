//
//  Created by Vonage on 12/8/26.
//

import Combine
import Foundation
import VERADomain
import os

public final class OktaAuthManager: OKTAAuthenticating, @unchecked Sendable {

    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.notAuthenticated)
    private let browserSignIn: BrowserSignInProvider

    public var authState: AuthState { authStateSubject.value }

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    private static let logger = Logger(
        subsystem: "com.vonage.VERA",
        category: "okta"
    )

    public init(browserSignIn: BrowserSignInProvider = DefaultBrowserSignInProvider()) {
        self.browserSignIn = browserSignIn
    }

    @MainActor
    public func signIn(from anchor: ASPresentationAnchor) async throws {
        Self.logger.info("Starting Okta browser sign-in")

        guard let result = try await browserSignIn.signIn(from: anchor) else {
            Self.logger.error("Sign-in returned nil token")
            throw OktaAuthError.signInFailed
        }

        Self.logger.info("Sign-in successful, credential stored")
        authStateSubject.send(.authenticated(AuthenticatedUser(name: result.userName)))
    }

    public func signOut() async throws {
        Self.logger.info("Starting sign-out")
        try browserSignIn.removeCredential()
        authStateSubject.send(.notAuthenticated)
        Self.logger.info("Sign-out completed")
    }

    public func currentToken() async throws -> String {
        try await browserSignIn.currentToken()
    }

    public func restoreSession() {
        guard let result = browserSignIn.restoreSession() else {
            authStateSubject.send(.notAuthenticated)
            return
        }
        Self.logger.info("Restored session from Keychain")
        authStateSubject.send(.authenticated(AuthenticatedUser(name: result.userName)))
    }
}


public enum OktaAuthError: Error, LocalizedError {
    case signInFailed
    case noCredential
    case noAccessToken

    public var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Okta sign-in failed. Please try again."
        case .noCredential:
            return "No stored authentication credential. Please sign in."
        case .noAccessToken:
            return "Unable to retrieve access token."
        }
    }
}
