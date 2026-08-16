//
//  Created by Vonage on 14/8/26.
//

import Foundation

@testable import VERAOKTA

@MainActor
final class MockBrowserSignInProvider: BrowserSignInProvider {

    var signInResult: Result<SignInResult?, Error> = .success(nil)
    var signInCallCount = 0

    var currentTokenResult: Result<String, Error> = .failure(OktaAuthError.noCredential)
    var currentTokenCallCount = 0

    var removeCredentialResult: Result<Void, Error> = .success(())
    var removeCredentialCallCount = 0

    var restoreSessionResult: SignInResult?
    var restoreSessionCallCount = 0

    func signIn(from anchor: ASPresentationAnchor) async throws -> SignInResult? {
        signInCallCount += 1
        return try signInResult.get()
    }

    func currentToken() async throws -> String {
        currentTokenCallCount += 1
        return try currentTokenResult.get()
    }

    func removeCredential() throws {
        removeCredentialCallCount += 1
        try removeCredentialResult.get()
    }

    func restoreSession() -> SignInResult? {
        restoreSessionCallCount += 1
        return restoreSessionResult
    }
}
