//
//  Created by Vonage on 12/8/26.
//

import Foundation

#if canImport(UIKit)

    import AuthFoundation
    import BrowserSignin
    import Combine
    import VERADomain
    import os

    @MainActor
    public final class OktaAuthManager: OKTAAuthenticating, AuthStateDataSource, ObservableObject {

        @Published public private(set) var authState: AuthState = .notAuthenticated

        public var authStatePublisher: AnyPublisher<AuthState, Never> {
            $authState.eraseToAnyPublisher()
        }

        private static let logger = Logger(
            subsystem: "com.vonage.VERA",
            category: "okta"
        )

        public init() {
            restoreSession()
        }

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
                authState = .notAuthenticated
                return
            }

            try await credential.revoke(type: .all)
            try credential.remove()

            authState = .notAuthenticated
            Self.logger.info("Sign-out completed")
        }

        public func currentToken() async throws -> String {
            guard let credential = Credential.default else {
                throw OktaAuthError.noCredential
            }

            if credential.token.isExpired {
                Self.logger.info("Token expired, refreshing")
                try await credential.refreshIfNeeded()
            }

            return credential.token.accessToken
        }

        private func restoreSession() {
            guard let credential = Credential.default else {
                authState = .notAuthenticated
                return
            }

            Self.logger.info("Restored session from Keychain")
            updateState(from: credential)
        }

        private func updateState(from credential: Credential) {
            let name = credential.token.idToken?.body.value["name"] as? String ?? ""
            authState = .authenticated(AuthenticatedUser(name: name))
        }
    }

#endif


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
