//
//  Created by Vonage on 12/8/26.
//

import Foundation
import VERADomain

/// Protocol defining the OKTA authentication interface.
/// Enables dependency injection and testability via mocking.
@MainActor
public protocol OKTAAuthenticating: ObservableObject {
    /// The current authentication state.
    var authState: AuthState { get }

    /// Signs the user in via OKTA browser-based authentication.
    /// - Parameter anchor: The presentation anchor for the ASWebAuthenticationSession.
    func signIn(from anchor: ASPresentationAnchor) async throws

    /// Signs the user out, clearing tokens from Keychain.
    func signOut() async throws

    /// Returns the current valid access token, refreshing if needed.
    /// - Throws: If no credential is stored or token refresh fails.
    func currentToken() async throws -> String
}

#if canImport(UIKit)
    import UIKit
    public typealias ASPresentationAnchor = UIWindow
#endif
