//
//  Created by Vonage on 7/6/26.
//

import Testing
import VERADomain

@testable import VERAE2E

@Suite("E2E session repository tests")
struct E2ESessionRepositoryTests {

    @Test("Session repository creates and reuses a deterministic call")
    func sessionRepositoryCreatesAndReusesCall() async throws {
        let sut = E2ESessionRepository()
        let credentials = RoomCredentials(
            sessionId: "e2e-session",
            token: "e2e-token",
            applicationId: "e2e-application-id",
            roomName: "testroom",
            sessionKey: "e2e-session-key"
        )

        let call = try await sut.createSession(credentials)
        call.connect()
        await call.enableCaptions()

        #expect(sut.currentCall != nil)
        #expect(call.areCaptionsEnabled)

        let reusedCall = try await sut.createSession(credentials)
        #expect(call === reusedCall)

        sut.clearSession()
        #expect(sut.currentCall == nil)
    }
}
