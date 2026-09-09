//
//  Created by Vonage on 13/8/26.
//

import Foundation
import Testing
import VERADomain

@testable import VERAOKTA

@Suite("OktaTokenProvider Tests")
struct OktaTokenProviderTests {

    @Test("token returns value when authManager provides token")
    func tokenReturnsValue() async {
        let mock = await MockOKTAAuthenticating()
        await MainActor.run { mock.currentTokenResult = .success("access-token-123") }
        let sut = OktaTokenProvider(authManager: mock)

        let result = await sut.token()

        #expect(result == "access-token-123")
    }

    @Test("token returns nil when authManager throws")
    func tokenReturnsNilOnError() async {
        let mock = await MockOKTAAuthenticating()
        await MainActor.run { mock.currentTokenResult = .failure(OktaAuthError.noCredential) }
        let sut = OktaTokenProvider(authManager: mock)

        let result = await sut.token()

        #expect(result == nil)
    }

    @Test("token calls currentToken on authManager")
    func tokenCallsAuthManager() async {
        let mock = await MockOKTAAuthenticating()
        let sut = OktaTokenProvider(authManager: mock)

        _ = await sut.token()

        let callCount = await mock.currentTokenCallCount
        #expect(callCount == 1)
    }

    @Test("token returns nil when authManager throws arbitrary error")
    func tokenReturnsNilOnArbitraryError() async {
        let mock = await MockOKTAAuthenticating()
        await MainActor.run { mock.currentTokenResult = .failure(NSError(domain: "test", code: -1)) }
        let sut = OktaTokenProvider(authManager: mock)

        let result = await sut.token()

        #expect(result == nil)
    }

    @Test("multiple calls each invoke authManager")
    func multipleCallsInvokeAuthManager() async {
        let mock = await MockOKTAAuthenticating()
        let sut = OktaTokenProvider(authManager: mock)

        _ = await sut.token()
        _ = await sut.token()
        _ = await sut.token()

        let callCount = await mock.currentTokenCallCount
        #expect(callCount == 3)
    }
}
