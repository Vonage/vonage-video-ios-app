//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("Room credentials value transfer")
struct RoomCredentialsTransferTests {

    @Test("Credential requests and responses cross an actor boundary without losing fields")
    func repositoryBoundary() async throws {
        let repository = CredentialsRepository()
        let response = try await repository.getRoomCredentials(.init(roomName: "room"))
        let received = await Task.detached { response }.value
        #expect(received.sessionId == "session")
        #expect(received.token == "test-token")
        #expect(received.apiKey == "application")
        #expect(received.sessionKey == "test-key")
        #expect(received.captionsId == "captions")
        #expect(await repository.requestedRoom == "room")

        let credentials = RoomCredentials(
            sessionId: received.sessionId, token: received.token,
            applicationId: received.apiKey, roomName: "room",
            sessionKey: received.sessionKey, captionsId: received.captionsId)
        let transferred = await Task.detached { credentials }.value
        #expect(transferred.sessionId == "session")
        #expect(transferred.token == "test-token")
        #expect(transferred.applicationId == "application")
        #expect(transferred.roomName == "room")
        #expect(transferred.sessionKey == "test-key")
        #expect(transferred.captionsId == "captions")
        let withoutCaptions = RoomCredentialsResponse(
            sessionId: "session", token: "test-token", apiKey: "application", sessionKey: "test-key")
        #expect(await Task.detached { withoutCaptions }.value.captionsId == nil)
    }

    @Test("Create and join payloads retain their JSON contracts across tasks")
    func apiPayloads() async throws {
        let createRequest = CreateSessionRequestBody(roomName: "room")
        let createJSON = try await Task.detached { try JSONEncoder().encode(createRequest) }.value
        #expect(try JSONSerialization.jsonObject(with: createJSON) as? [String: String] == ["roomName": "room"])
        let joinRequest = JoinSessionRequestBody(sessionKey: "test-key")
        let joinJSON = try await Task.detached { try JSONEncoder().encode(joinRequest) }.value
        #expect(try JSONSerialization.jsonObject(with: joinJSON) as? [String: String] == ["sessionKey": "test-key"])

        let createResponse = try JSONDecoder().decode(
            CreateSessionResponse.self,
            from: Data(#"{"sessionId":"session","sessionKey":"test-key","applicationId":"application"}"#.utf8))
        let created = await Task.detached { createResponse }.value
        #expect(created.sessionId == "session")
        #expect(created.sessionKey == "test-key")
        #expect(created.applicationId == "application")
        let joinResponse = try JSONDecoder().decode(
            JoinSessionResponse.self,
            from: Data(#"{"token":"test-token","applicationId":"application"}"#.utf8))
        let joined = await Task.detached { joinResponse }.value
        #expect(joined.token == "test-token")
        #expect(joined.applicationId == "application")
    }

    @Test("Session details preserve all fields across tasks")
    func sessionDetails() async {
        let session = SessionInfo(apiKey: "application", sessionId: "session", token: "test-token")
        let received = await Task.detached { session }.value
        #expect(received.apiKey == "application")
        #expect(received.sessionId == "session")
        #expect(received.token == "test-token")
    }
}

private actor CredentialsRepository: RoomCredentialsRepository {
    private(set) var requestedRoom: String?

    func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse {
        requestedRoom = request.roomName
        return .init(
            sessionId: "session", token: "test-token", apiKey: "application", sessionKey: "test-key",
            captionsId: "captions")
    }
}
