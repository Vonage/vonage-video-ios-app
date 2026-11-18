//
//  Created by Vonage on 28/6/26.
//

import Foundation
import Testing

@testable import VERADomain

@Suite("SessionKeyParser tests")
struct SessionKeyParserTests {

    // MARK: - isSessionKey

    @Test("Valid JWT is detected as session key")
    func validJWTIsSessionKey() {
        // A real JWT structure: header.payload.signature
        let jwt = makeValidSessionKey()
        #expect(SessionKeyParser.isSessionKey(jwt))
    }

    @Test("Simple room name is not a session key")
    func roomNameIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("heart-of-gold"))
    }

    @Test("Room name with numbers is not a session key")
    func roomNameWithNumbersIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("room-123"))
    }

    @Test("Empty string is not a session key")
    func emptyStringIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey(""))
    }

    @Test("String with two dots but invalid base64url is not a session key")
    func invalidBase64IsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("not.valid.base64!"))
    }

    @Test("String with only one dot is not a session key")
    func oneDotIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("header.payload"))
    }

    @Test("String with four dots is not a session key")
    func fourDotsIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("a.b.c.d"))
    }

    @Test("Short dotted string is not a session key")
    func shortDottedStringIsNotSessionKey() {
        #expect(!SessionKeyParser.isSessionKey("abc.def.ghi"))
    }

    // MARK: - extractRoomName

    @Test("Extracts room name from valid JWT")
    func extractsRoomNameFromJWT() {
        let jwt = makeValidSessionKey(roomName: "heart-of-gold")
        #expect(SessionKeyParser.extractRoomName(from: jwt) == "heart-of-gold")
    }

    @Test("Returns nil for invalid JWT")
    func returnsNilForInvalidJWT() {
        #expect(SessionKeyParser.extractRoomName(from: "not-a-jwt") == nil)
    }

    @Test("Returns nil when payload has no roomName field")
    func returnsNilWhenNoRoomNameField() {
        let jwt = makeJWT(payload: ["sessionId": "123"])
        #expect(SessionKeyParser.extractRoomName(from: jwt) == nil)
    }

    // MARK: - extractSessionId

    @Test("Extracts session ID from valid JWT")
    func extractsSessionIdFromJWT() {
        let sessionId = "1_MX4xYmMxYzhkZS03ZTUwLTQ5N2ItYjBiMS03ZDhlMWFlNDZkMzh-fjE3NzY4NDQ3NzE3Mjl-"
        let jwt = makeValidSessionKey(sessionId: sessionId)
        #expect(SessionKeyParser.extractSessionId(from: jwt) == sessionId)
    }

    @Test("Returns nil for session ID from invalid JWT")
    func returnsNilSessionIdForInvalidJWT() {
        #expect(SessionKeyParser.extractSessionId(from: "not-a-jwt") == nil)
    }

    // MARK: - extractExpiration

    @Test("Extracts expiration date from JWT with exp claim")
    func extractsExpirationFromJWT() {
        let exp: TimeInterval = 1_800_000_000
        let jwt = makeJWT(payload: ["exp": exp, "roomName": "heart-of-gold"])
        #expect(SessionKeyParser.extractExpiration(from: jwt) == Date(timeIntervalSince1970: exp))
    }

    @Test("Returns nil when JWT has no exp claim")
    func returnsNilWhenNoExpClaim() {
        #expect(SessionKeyParser.extractExpiration(from: makeValidSessionKey()) == nil)
    }

    @Test("Returns nil for invalid JWT")
    func returnsNilExpirationForInvalidJWT() {
        #expect(SessionKeyParser.extractExpiration(from: "not-a-jwt") == nil)
    }

    // MARK: - isExpired

    @Test("Returns false when no exp claim")
    func notExpiredWhenNoExpClaim() {
        #expect(SessionKeyParser.isExpired(makeValidSessionKey()) == false)
    }

    @Test("Returns false for a future exp claim")
    func notExpiredForFutureDate() {
        let futureExp = Date().addingTimeInterval(3600).timeIntervalSince1970
        let jwt = makeJWT(payload: ["exp": futureExp, "roomName": "heart-of-gold"])
        #expect(SessionKeyParser.isExpired(jwt, now: Date()) == false)
    }

    @Test("Returns true for a past exp claim")
    func expiredForPastDate() {
        let pastExp = Date().addingTimeInterval(-3600).timeIntervalSince1970
        let jwt = makeJWT(payload: ["exp": pastExp, "roomName": "heart-of-gold"])
        #expect(SessionKeyParser.isExpired(jwt, now: Date()) == true)
    }

    @Test("Returns false when exp equals now")
    func notExpiredWhenExpEqualsNow() {
        let now = Date()
        let jwt = makeJWT(payload: ["exp": now.timeIntervalSince1970, "roomName": "heart-of-gold"])
        #expect(SessionKeyParser.isExpired(jwt, now: now) == false)
    }

    // MARK: - Helpers

    private func makeValidSessionKey(
        roomName: String = "heart-of-gold",
        sessionId: String = "1_MX4xYmMxYzhkZS03ZTUwLTQ5N2ItYjBiMS03ZDhlMWFlNDZkMzh-fjE3NzY4NDQ3NzE3Mjl-"
    ) -> String {
        makeJWT(payload: [
            "sessionId": sessionId,
            "roomName": roomName,
            "iat": 1_776_844_771,
        ])
    }

    private func makeJWT(payload: [String: Any]) -> String {
        let header = base64URLEncode(
            (try? JSONSerialization.data(
                withJSONObject: ["alg": "HS256", "typ": "JWT"])) ?? Data())
        let payloadData = base64URLEncode(
            (try? JSONSerialization.data(
                withJSONObject: payload)) ?? Data())
        let signature = base64URLEncode(Data("fake-signature-bytes".utf8))
        return "\(header).\(payloadData).\(signature)"
    }

    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
