//
//  Created by Vonage on 12/8/26.
//

import Foundation
import VERADomain
import os

public final class OktaTokenProvider: TokenProvider, @unchecked Sendable {

    private let authManager: any OKTAAuthenticating

    private static let logger = Logger(
        subsystem: "com.vonage.VERA",
        category: "okta-token"
    )

    public init(authManager: any OKTAAuthenticating) {
        self.authManager = authManager
    }

    public func token() async -> String? {
        await getToken()
    }

    @MainActor
    private func getToken() async -> String? {
        do {
            return try await authManager.currentToken()
        } catch {
            Self.logger.debug("Token unavailable: \(error.localizedDescription)")
            return nil
        }
    }
}
