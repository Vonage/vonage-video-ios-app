//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import Testing
import VERAVonage

@testable import VERAE2E

@Suite("E2E HTTP helpers tests")
struct E2EHTTPHelpersTests {

    @Test("Request body decoder returns empty dictionary for nil and empty data")
    func requestBodyDecoderReturnsEmptyDictionaryForNilAndEmptyData() throws {
        #expect(try E2EHTTPRequestBodyDecoder.decode(nil).isEmpty)
        #expect(try E2EHTTPRequestBodyDecoder.decode(Data()).isEmpty)
    }

    @Test("Request body decoder returns dictionary for valid JSON")
    func requestBodyDecoderReturnsDictionaryForValidJSON() throws {
        let data = try JSONSerialization.data(
            withJSONObject: [
                "roomName": "testroom",
                "count": 1,
            ])

        let decoded = try E2EHTTPRequestBodyDecoder.decode(data)

        #expect(decoded["roomName"] as? String == "testroom")
        #expect(decoded["count"] as? Int == 1)
    }

    @Test("Response builder wraps data in tRPC envelope")
    func responseBuilderWrapsDataInEnvelope() throws {
        let data = E2EHTTPResponseBuilder.envelope(["archiveId": "archive-id"])

        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let result = try #require(json["result"] as? [String: Any])
        let payload = try #require(result["data"] as? [String: Any])

        #expect(payload["archiveId"] as? String == "archive-id")
    }

    @Test("Response builder creates forced failure body")
    func responseBuilderCreatesForcedFailureBody() throws {
        let data = E2EHTTPResponseBuilder.errorBody(for: E2EEndpoint.startArchive.rawValue)

        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let error = try #require(json["error"] as? [String: Any])

        #expect(error["endpoint"] as? String == E2EEndpoint.startArchive.rawValue)
        #expect(error["code"] as? String == "VERA_E2E_FORCED_FAILURE")
    }

    @Test("Stable identifier lowercases filters and truncates")
    func stableIdentifierLowercasesFiltersAndTruncates() {
        let identifier = E2EIdentifier.stableIdentifier(
            from: "Room Name_#$-ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

        #expect(identifier == "roomname-abcdefghijklmnopqrstuvw")
        #expect(identifier.count == 32)
    }
}
