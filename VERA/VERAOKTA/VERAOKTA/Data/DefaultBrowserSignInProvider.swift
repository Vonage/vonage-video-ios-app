//
//  Created by Vonage on 14/8/26.
//

import AuthFoundation
import BrowserSignin
import Foundation
import VERADomain

/// Default implementation that delegates to the Okta SDK.
public struct DefaultBrowserSignInProvider: BrowserSignInProvider {

    public init() {}

    public func signIn(from anchor: ASPresentationAnchor) async throws -> SignInResult? {
        #if canImport(UIKit)
            guard let token = try await BrowserSignin.shared?.signIn(from: anchor) else {
                return nil
            }
            let credential = try Credential.store(token)
            return makeResult(from: credential)
        #else
            return nil
        #endif
    }

    public func currentToken() async throws -> String {
        guard let credential = Credential.default else {
            throw OktaAuthError.noCredential
        }
        if credential.token.isExpired {
            try await credential.refreshIfNeeded()
        }
        return credential.token.accessToken
    }

    public func removeCredential() throws {
        guard let credential = Credential.default else { return }
        try credential.remove()
    }

    public func restoreSession() -> SignInResult? {
        guard let credential = Credential.default else { return nil }
        return makeResult(from: credential)
    }

    private func makeResult(from credential: Credential) -> SignInResult {
        let name = credential.token.idToken?.body.value["name"]?.string
        return SignInResult(accessToken: credential.token.accessToken, userName: name)
    }
}
