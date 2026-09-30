//
//  Created by Vonage on 24/9/26.
//

import Testing

@testable import VERADomain

@Suite("AuthenticationError Tests")
struct AuthenticationErrorTests {

    @Test("init creates an Error value")
    func initCreatesError() {
        let sut = AuthenticationError()

        #expect(sut is Error)
    }

    @Test("two instances are equal")
    func instancesAreEqual() {
        #expect(AuthenticationError() == AuthenticationError())
    }
}
