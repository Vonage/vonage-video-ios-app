//
//  Created by Vonage on 12/10/2026.
//

import Testing

@testable import VERAVonageSettingsPlugin

@Suite("Network statistics RTC report compatibility")
struct NetworkStatsCodecReportTests {
    @Test(
        "Malformed or unsupported JSON shapes differ from valid empty reports",
        arguments: ["invalid", "{", "{}", "null", "[1]", "[{},null]"])
    func rejectsMalformedReports(json: String) {
        #expect(NetworkStatsCodecReport.parse(json, direction: .inbound) == nil)
    }

    @Test(
        "Valid reports without resolvable RTP codecs return an empty list",
        arguments: [
            "[]", "[{}]", #"[{"type":"codec","id":"a","mimeType":"audio/opus"}]"#,
            #"[{"type":"inbound-rtp","codecId":"missing","kind":"audio"}]"#,
        ])
    func acceptsReportsWithoutCodecs(json: String) {
        #expect(NetworkStatsCodecReport.parse(json, direction: .inbound)?.isEmpty == true)
    }

    @Test("Lookup resolves codecs after RTP entries, preserves report order and separates direction")
    func resolvesReports() throws {
        let json = #"""
            [
              {"type":"inbound-rtp","codecId":"v","kind":"video"},
              {"type":"outbound-rtp","codecId":"a","kind":"audio"},
              {"type":"inbound-rtp","codecId":"a","kind":"audio"},
              {"type":"inbound-rtp","codecId":"a","kind":"unknown"},
              {"type":"codec","id":"a","mimeType":"audio/opus"},
              {"type":"codec","id":"v","mimeType":"video/VP8"}
            ]
            """#
        let inbound = try #require(NetworkStatsCodecReport.parse(json, direction: .inbound))
        #expect(inbound.map(\.kind) == ["video", "audio", "unknown"])
        #expect(inbound.map(\.name) == ["VP8", "opus", "opus"])
        let outbound = try #require(NetworkStatsCodecReport.parse(json, direction: .outbound))
        #expect(outbound.map(\.kind) == ["audio"])
        #expect(outbound.map(\.name) == ["opus"])
    }

    @Test("Duplicate codec IDs use the last MIME type; absent and mistyped fields are skipped")
    func handlesDuplicateAndMissingFields() throws {
        let json = #"""
            [
              {"type":"codec","id":"a","mimeType":"audio/first"},
              {"type":"codec","id":"a","mimeType":"audio/last"},
              {"type":"codec","id":"a"},
              {"type":"codec","id":5,"mimeType":"audio/wrong"},
              {"type":"inbound-rtp","codecId":"a","kind":"audio"},
              {"type":"inbound-rtp","codecId":"a"},
              {"type":"inbound-rtp","codecId":5,"kind":"audio"},
              {"type":"inbound-rtp","codecId":"a","kind":5},
              {"type":"inbound-rtp","kind":"video"}
            ]
            """#
        let codecs = try #require(NetworkStatsCodecReport.parse(json, direction: .inbound))
        #expect(codecs.map(\.name) == ["last"])
        #expect(codecs.map(\.kind) == ["audio"])
    }

    @Test("MIME codec extraction preserves empty trailing components and slashless values")
    func preservesMIMEParsing() throws {
        let json = #"""
            [
              {"type":"codec","id":"a","mimeType":"audio/"},
              {"type":"codec","id":"v","mimeType":"VP9"},
              {"type":"inbound-rtp","codecId":"a","kind":"audio"},
              {"type":"inbound-rtp","codecId":"v","kind":"video"}
            ]
            """#
        let codecs = try #require(NetworkStatsCodecReport.parse(json, direction: .inbound))
        #expect(codecs.map(\.name) == ["", "VP9"])
    }
}
