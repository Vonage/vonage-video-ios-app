//
//  Created by Vonage on 12/8/26.
//

#if canImport(UIKit)

    import Foundation
    import os

    /// Bridges `@MainActor`-isolated `OktaAuthManager` to `Sendable` `TokenProvider`.
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
