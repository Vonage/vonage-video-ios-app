//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import Testing

@testable import VERAE2E

@Suite("E2E HTTP body preview sanitizer tests")
struct E2EHTTPBodyPreviewSanitizerTests {

    @Test("Preview returns nil for nil and empty body")
    func previewReturnsNilForNilAndEmptyBody() {
        #expect(E2EHTTPBodyPreviewSanitizer.preview(from: nil) == nil)
        #expect(E2EHTTPBodyPreviewSanitizer.preview(from: Data()) == nil)
    }

    @Test("Preview redacts sensitive keys and preserves useful fields")
    func previewRedactsSensitiveKeysAndPreservesUsefulFields() throws {
        let data = try JSONSerialization.data(
            withJSONObject: [
                "sessionKey": "secret-session-key",
                "token": "secret-token",
                "roomName": "testroom",
                "archives": [
                    [
                        "archiveId": "archive-id",
                        "applicationId": "secret-application-id",
                        "status": "available",
                    ]
                ],
            ])

        let preview = try #require(E2EHTTPBodyPreviewSanitizer.preview(from: data))

        #expect(preview.contains("\"sessionKey\":\"<redacted>\""))
        #expect(preview.contains("\"token\":\"<redacted>\""))
        #expect(preview.contains("\"applicationId\":\"<redacted>\""))
        #expect(preview.contains("\"roomName\":\"testroom\""))
        #expect(preview.contains("\"archiveId\":\"archive-id\""))
        #expect(preview.contains("\"status\":\"available\""))
        #expect(!preview.contains("secret-token"))
    }

    @Test("Preview returns original text for non JSON UTF8 body")
    func previewReturnsOriginalTextForNonJSONUTF8Body() throws {
        let data = try #require("plain body".data(using: .utf8))

        let preview = E2EHTTPBodyPreviewSanitizer.preview(from: data)

        #expect(preview == "plain body")
    }

    @Test("Preview describes non UTF8 body")
    func previewDescribesNonUTF8Body() {
        let preview = E2EHTTPBodyPreviewSanitizer.preview(from: Data([0xff, 0xfe]))

        #expect(preview == "<non-utf8 body: 2 bytes>")
    }

    @Test("Preview truncates long body")
    func previewTruncatesLongBody() throws {
        let data = try #require(String(repeating: "a", count: 2_100).data(using: .utf8))

        let preview = try #require(E2EHTTPBodyPreviewSanitizer.preview(from: data))

        #expect(preview.hasSuffix("... <truncated>"))
    }
}
