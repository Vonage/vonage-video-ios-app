//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import Testing
import VERADomain
import VERAVonage

@testable import VERAE2E

@Suite("E2E call params builder tests")
struct E2ECallParamsBuilderTests {

    @Test("Call params are empty without credentials")
    func callParamsAreEmptyWithoutCredentials() {
        #expect(E2ECallParamsBuilder.callParams(from: nil).isEmpty)
    }

    @Test("Call params include credentials and generated call id")
    func callParamsIncludeCredentialsAndGeneratedCallId() throws {
        let credentials = RoomCredentials(
            sessionId: "session-id",
            token: "token",
            applicationId: "application-id",
            roomName: "testroom",
            sessionKey: "session-key")

        let params = E2ECallParamsBuilder.callParams(from: credentials)

        #expect(params[VonageCallParams.username.rawValue] as? String == "Test User")
        #expect(params[VonageCallParams.roomName.rawValue] as? String == "testroom")
        #expect(params[VonageCallParams.applicationId.rawValue] as? String == "application-id")
        #expect(params[VonageCallParams.sessionId.rawValue] as? String == "session-id")
        #expect(params[VonageCallParams.token.rawValue] as? String == "token")

        let callId = try #require(params[VonageCallParams.callID.rawValue] as? String)
        #expect(UUID(uuidString: callId) != nil)
    }
}
