//
//  Created by Vonage on 12/8/26.
//

#if canImport(UIKit)

    import Foundation
    import os

    /// A `Sendable` token provider that bridges the `@MainActor`-isolated
    /// `OktaAuthManager` to the `HTTPClient` layer.
    ///
    /// Returns the current access token if the user is authenticated,
    /// or `nil` if unauthenticated.
    public final class OktaTokenProvider: TokenProvider, @unchecked Sendable {

        private let authManager: OktaAuthManager

        private static let logger = Logger(
            subsystem: "com.vonage.VERA",
            category: "okta-token"
        )

        public init(authManager: OktaAuthManager) {
            self.authManager = authManager
        }

        public func token() async -> String? {
            await getToken()
        }

        @MainActor
        private func getToken() async -> String? {
            guard authManager.authState.isAuthenticated else {
                return nil
            }
            do {
                return try await authManager.currentToken()
            } catch {
                Self.logger.debug("Token unavailable: \(error.localizedDescription)")
                return nil
            }
        }
    }

#endif
