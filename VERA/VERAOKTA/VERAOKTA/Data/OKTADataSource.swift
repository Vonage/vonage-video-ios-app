//
//  Created by Vonage on 12/8/26.
//

import AuthFoundation
import BrowserSignin
import Combine
import Foundation
import VERADomain
import os

/// Concrete implementation of `OKTAAuthenticating` that wraps `okta-mobile-swift`.
///
/// Responsibilities:
/// - Opens Okta browser-based sign-in via `BrowserSignin`
/// - Stores/retrieves credentials from Keychain (handled by Okta SDK)
/// - Refreshes tokens automatically when expired
/// - Publishes `authState` changes for the UI layer
/// - Conforms to `AuthStateDataSource` for reactive observation
@MainActor
public final class OktaAuthManager: OKTAAuthenticating, AuthStateDataSource, ObservableObject {

    // MARK: - Published State

    @Published public private(set) var authState: AuthState = .notAuthenticated

    // MARK: - AuthStateDataSource

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    // MARK: - Private

    private static let logger = Logger(
        subsystem: "com.vonage.VERA",
        category: "okta"
    )

    // MARK: - Initialization

    public init() {
        restoreSession()
    }

    // MARK: - Public API

    public func signIn(from anchor: ASPresentationAnchor) async throws {
        Self.logger.info("Starting Okta browser sign-in")

        let token = try await BrowserSignin.shared?.signIn(from: anchor)

        guard let token else {
            Self.logger.error("Sign-in returned nil token")
            throw OktaAuthError.signInFailed
        }

        let credential = try Credential.store(token)
        Self.logger.info("Sign-in successful, credential stored")

        updateState(from: credential)
    }

    public func signOut() async throws {
        Self.logger.info("Starting sign-out")

        guard let credential = Credential.default else {
            Self.logger.warning("No credential to sign out")
            authState = .notAuthenticated
            return
        }

        try await credential.revoke(type: .all)
        try credential.remove()

        authState = .notAuthenticated
        Self.logger.info("Sign-out completed, credentials cleared")
    }

    public func currentToken() async throws -> String {
        guard let credential = Credential.default else {
            Self.logger.error("No stored credential when requesting token")
            throw OktaAuthError.noCredential
        }

        // Refresh if the token is expired or about to expire
        if credential.token.isExpired {
            Self.logger.info("Token expired, refreshing")
            try await credential.refreshIfNeeded()
        }

        return credential.token.accessToken
    }

    // MARK: - Private Helpers

    private func restoreSession() {
        guard let credential = Credential.default else {
            Self.logger.info("No stored session found")
            authState = .notAuthenticated
            return
        }

        Self.logger.info("Restored session from Keychain")
        updateState(from: credential)
    }

    private func updateState(from credential: Credential) {
        let email = credential.userInfo?.email ?? ""
        let name = credential.userInfo?.name ?? credential.userInfo?.preferredUsername ?? email

        let user = AuthenticatedUser(email: email, name: name)
        authState = .authenticated(user)
    }
}

// MARK: - Errors

/// Errors specific to the Okta authentication flow.
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
