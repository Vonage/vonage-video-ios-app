//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("Room identifier value transfer")
struct RoomIdentifierTransferTests {

    @Test("Plain room names survive task transfer without normalization")
    func plainRoomsAcrossTasks() async {
        let rooms = ["", "heart-of-gold", "会議室 🚀"].map { PlainRoomIdentifier(roomName: $0) }
        let received = await Task.detached { rooms }.value
        #expect(received == rooms)
        #expect(received.map(\.roomName) == ["", "heart-of-gold", "会議室 🚀"])
    }

    @Test("Session-key identifiers preserve the key and decoded room name across tasks")
    func sessionKeyRoomsAcrossTasks() async throws {
        for name in ["", "heart-of-gold", "会議室 🚀"] {
            let key = try makeSessionKey(payload: ["roomName": name, "sessionId": "test-session"])
            let room = SessionKeyRoomIdentifier(sessionKey: key)
            let received = await Task.detached { room }.value
            #expect(received == room)
            #expect(received.sessionKey == key)
            #expect(received.roomName == name)
        }
    }

    @Test("Malformed and missing-room keys retain the existing empty-name fallback after transfer")
    func invalidSessionKeyFallback() async throws {
        let missingRoom = try makeSessionKey(payload: ["sessionId": "test-session"])
        for key in ["", "not-a-session-key", "header.invalid!.signature", missingRoom] {
            let room = SessionKeyRoomIdentifier(sessionKey: key)
            let received = await Task.detached { room }.value
            #expect(received.sessionKey == key)
            #expect(received.roomName == "")
        }
    }

    private func makeSessionKey(payload: [String: String]) throws -> String {
        let encoded = try JSONEncoder().encode(payload).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        // Synthetic JWT-shaped fixtures exercise payload parsing, not signature verification.
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(encoded).dGVzdC1zaWduYXR1cmU"
    }
}
