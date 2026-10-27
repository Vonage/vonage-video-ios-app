//
//  Created by Vonage on 22/1/26.
//

import Foundation
import VERADomain

extension VonageSignal {
    static func archivingState(_ archivingID: String, kind: ArchiveKind) throws -> VonageSignal {
        try createSignal(
            type: "archiving",
            payload: ["action": "start", "archivingID": archivingID, "kind": kind.rawValue]
        )
    }

    static func idleArchivingState(kind: ArchiveKind) throws -> VonageSignal {
        try createSignal(
            type: "archiving",
            payload: ["action": "stop", "kind": kind.rawValue]
        )
    }

    private static func createSignal<T: Encodable>(type: String, payload: T) throws -> VonageSignal {
        let jsonData = try JSONEncoder().encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        return .init(type: type, data: jsonString)
    }
}
