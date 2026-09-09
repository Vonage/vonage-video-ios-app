//
//  Created by Vonage on 15/8/26.
//

import Testing

@testable import VERAOKTA

@Suite("SignInResult Tests")
struct SignInResultTests {

    @Test("init stores accessToken and userName")
    func initStoresValues() {
        let sut = SignInResult(accessToken: "token-abc", userName: "Alice")

        #expect(sut.accessToken == "token-abc")
        #expect(sut.userName == "Alice")
    }

    @Test("init stores nil userName")
    func initStoresNilUserName() {
        let sut = SignInResult(accessToken: "token-xyz", userName: nil)

        #expect(sut.accessToken == "token-xyz")
        #expect(sut.userName == nil)
    }
}
