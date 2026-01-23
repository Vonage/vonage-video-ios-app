//
//  Created by Vonage on 22/1/26.
//

import Foundation

extension VonageSignal {
    static func archivingState(_ archivingID: String) throws -> VonageSignal {
        try createSignal(
            type: "archiving",
            payload: ["action": "start", "archivingID": archivingID]
        )
    }

    static func idleArchivingState() throws -> VonageSignal {
        try createSignal(
            type: "archiving",
            payload: ["action": "stop"]
        )
    }

    private static func createSignal<T: Encodable>(type: String, payload: T) throws -> VonageSignal {
        let jsonData = try JSONEncoder().encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        return .init(type: type, data: jsonString)
    }
}
