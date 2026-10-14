//
//  Created by Vonage on 12/10/2026.
//

import Foundation

/// A value extracted from an RTC report; no SDK object is held by collector state.
struct NetworkStatsCodec {
    let kind: String
    let name: String
}

/// Keeps malformed-report handling and codec lookup independent from SDK delegates.
enum NetworkStatsCodecReport {
    enum Direction: String {
        case inbound = "inbound-rtp"
        case outbound = "outbound-rtp"
    }

    /// Nil denotes malformed JSON. A valid report without matching codecs returns an empty array.
    static func parse(_ jsonArrayString: String, direction: Direction) -> [NetworkStatsCodec]? {
        guard let data = jsonArrayString.data(using: .utf8),
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return nil }

        var codecLookup: [String: String] = [:]
        for entry in entries where (entry["type"] as? String) == "codec" {
            if let id = entry["id"] as? String, let mimeType = entry["mimeType"] as? String {
                codecLookup[id] = mimeType
            }
        }

        return entries.compactMap { entry in
            guard (entry["type"] as? String) == direction.rawValue,
                let codecId = entry["codecId"] as? String,
                let mimeType = codecLookup[codecId],
                let kind = entry["kind"] as? String
            else { return nil }
            return NetworkStatsCodec(
                kind: kind,
                name: mimeType.components(separatedBy: "/").last ?? mimeType
            )
        }
    }
}
