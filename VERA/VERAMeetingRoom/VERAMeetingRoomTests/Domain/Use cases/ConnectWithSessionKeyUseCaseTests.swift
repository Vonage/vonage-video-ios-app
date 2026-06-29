//
//  Created by Vonage on 23/7/25.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@Suite("Connect with session key use case tests")
struct ConnectWithSessionKeyUseCaseTests {

    @Test
    func connectWithSessionKeyCallsCreateSession() async throws {
        let sessionRepository = makeMockSessionRepository()
        sessionRepository.currentCall = MockCall()
        let sessionKeyHolder = DefaultSessionKeyHolder()

        let sut = makeSUT(
            sessionRepository: sessionRepository,
            sessionKeyWriter: sessionKeyHolder)

        let sessionKey = makeTestSessionKey()
        _ = try await sut(sessionKey: sessionKey)

        #expect(sessionRepository.createSessionCallCount == 1)
        #expect(sessionKeyHolder.sessionKey == sessionKey)
    }

    @Test
    func connectWithSessionKeySetsSessionKey() async throws {
        let sessionKeyHolder = DefaultSessionKeyHolder()
        let sessionRepository = makeMockSessionRepository()
        sessionRepository.currentCall = MockCall()

        let sut = makeSUT(
            sessionRepository: sessionRepository,
            sessionKeyWriter: sessionKeyHolder)

        let sessionKey = makeTestSessionKey()
        _ = try await sut(sessionKey: sessionKey)

        #expect(sessionKeyHolder.sessionKey == sessionKey)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        roomCredentialsRepository: RoomCredentialsRepository = makeMockRoomCredentialsRepository(),
        sessionRepository: SessionRepository = makeMockSessionRepository(),
        sessionKeyWriter: SessionKeyWriter = DefaultSessionKeyHolder()
    ) -> ConnectWithSessionKeyUseCase {
        return DefaultConnectWithSessionKeyUseCase(
            sessionRepository: sessionRepository,
            roomCredentialsRepository: roomCredentialsRepository,
            sessionKeyWriter: sessionKeyWriter)
    }

    private func makeTestSessionKey() -> String {
        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payload = Data("{\"sessionId\":\"1_MX4x\",\"roomName\":\"solutions\",\"iat\":1776844771}".utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let signature = Data("test-signature".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(header).\(payload).\(signature)"
    }
}
