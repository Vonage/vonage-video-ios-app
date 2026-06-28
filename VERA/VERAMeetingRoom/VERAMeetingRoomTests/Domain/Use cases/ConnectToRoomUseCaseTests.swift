//
//  Created by Vonage on 30/7/25.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@Suite("Connect to room use case tests")
struct ConnectToRoomUseCaseTests {

    @Test
    func connectToRoomUseCaseCreatesAndCallsToConnect() async throws {
        let roomCredentialsRepository = makeMockRoomCredentialsRepository()
        let sessionRepository = makeMockSessionRepository()

        let mockCall = MockCall()
        sessionRepository.currentCall = mockCall

        let sut = makeSUT(
            roomCredentialsRepository: roomCredentialsRepository,
            sessionRepository: sessionRepository)

        _ = try await sut(roomName: "heart-of-gold")

        #expect(sessionRepository.createSessionCallCount == 1)
        #expect(mockCall.recordedActions == [.connect])
    }

    @Test
    func sessionKeyIsSetAfterSuccessfulConnection() async throws {
        let sessionKeyHolder = DefaultSessionKeyHolder()
        let sessionRepository = makeMockSessionRepository()
        sessionRepository.currentCall = MockCall()

        let sut = makeSUT(
            sessionRepository: sessionRepository,
            sessionKeyWriter: sessionKeyHolder)

        _ = try await sut(roomName: "heart-of-gold")

        #expect(sessionKeyHolder.sessionKey == "aSessionKey")
    }

    @Test
    func sessionKeyIsNotSetWhenCreateSessionFails() async throws {
        let sessionKeyHolder = DefaultSessionKeyHolder()
        let sessionRepository = makeMockSessionRepository()
        sessionRepository.createSessionError = MockError.sessionCreationFailed

        let sut = makeSUT(
            sessionRepository: sessionRepository,
            sessionKeyWriter: sessionKeyHolder)

        await #expect(throws: MockError.self) {
            try await sut(roomName: "heart-of-gold")
        }

        #expect(sessionKeyHolder.sessionKey == "")
    }

    @Test
    func connectWithSessionKeySkipsCreateSession() async throws {
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

    private enum MockError: Error {
        case sessionCreationFailed
    }

    private func makeSUT(
        roomCredentialsRepository: RoomCredentialsRepository = makeMockRoomCredentialsRepository(),
        sessionRepository: SessionRepository = makeMockSessionRepository(),
        sessionKeyWriter: SessionKeyWriter = DefaultSessionKeyHolder()
    ) -> ConnectToRoomUseCase {
        return DefaultConnectToRoomUseCase(
            sessionRepository: sessionRepository,
            roomCredentialsRepository: roomCredentialsRepository,
            sessionKeyWriter: sessionKeyWriter)
    }

    private func makeTestSessionKey() -> String {
        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payload = Data("{\"sessionId\":\"1_MX4x\",\"roomName\":\"solutions\",\"iat\":1776844771}".utf8).base64EncodedString()
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
