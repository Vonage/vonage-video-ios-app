//
//  Created by Vonage on 12/8/26.
//

import AuthFoundation
import BrowserSignin
import Combine
import Foundation
import VERADomain
import os

@MainActor
public final class OktaAuthManager: OKTAAuthenticating {

    private let authStateSubject = CurrentValueSubject<AuthState, Never>(.notAuthenticated)

    public var authState: AuthState { authStateSubject.value }

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    private var credential: Credential?

    private static let logger = Logger(
        subsystem: "com.vonage.VERA",
        category: "okta"
    )

    public init() {
    }

    public func signIn(from anchor: ASPresentationAnchor) async throws {
        Self.logger.info("Starting Okta browser sign-in")

        #if canImport(UIKit)
            let token = try await BrowserSignin.shared?.signIn(from: anchor)

            guard let token else {
                Self.logger.error("Sign-in returned nil token")
                throw OktaAuthError.signInFailed
            }

            let stored = try Credential.store(token)
            credential = stored
            Self.logger.info("Sign-in successful, credential stored")

            updateState(from: stored)
        #endif
    }

    public func signOut() async throws {
        Self.logger.info("Starting sign-out")

        guard let credential else {
            sendState(.notAuthenticated)
            return
        }

        try credential.remove()

        self.credential = nil
        sendState(.notAuthenticated)
        Self.logger.info("Sign-out completed")
    }

    public func currentToken() async throws -> String {
        guard let credential else {
            throw OktaAuthError.noCredential
        }

        if credential.token.isExpired {
            Self.logger.info("Token expired, refreshing")
            try await credential.refreshIfNeeded()
        }

        return credential.token.accessToken
    }

    public func restoreSession() {
        guard let stored = Credential.default else {
            sendState(.notAuthenticated)
            return
        }

        credential = stored
        Self.logger.info("Restored session from Keychain")
        updateState(from: stored)
    }

    private func updateState(from credential: Credential) {
        let name = credential.token.idToken?.body.value["name"]?.string
        sendState(.authenticated(AuthenticatedUser(name: name)))
    }

    private func sendState(_ state: AuthState) {
        authStateSubject.send(state)
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
