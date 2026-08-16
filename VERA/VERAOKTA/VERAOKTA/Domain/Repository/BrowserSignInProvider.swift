//
//  Created by Vonage on 14/8/26.
//

import Foundation

/// Result of a successful browser sign-in.
public struct SignInResult: Sendable {
    public let accessToken: String
    public let userName: String?

    public init(accessToken: String, userName: String?) {
        self.accessToken = accessToken
        self.userName = userName
    }
}

/// Abstracts the Okta browser sign-in and credential storage for testability.
public protocol BrowserSignInProvider {
    /// Performs browser-based sign-in. Returns nil if no token was issued.
    func signIn(from anchor: ASPresentationAnchor) async throws -> SignInResult?

    /// Returns a fresh access token, refreshing if expired. Throws if no credential stored.
    func currentToken() async throws -> String

    /// Removes the stored credential.
    func removeCredential() throws

    /// Restores a previously stored session. Returns nil if nothing stored.
    func restoreSession() -> SignInResult?
}
