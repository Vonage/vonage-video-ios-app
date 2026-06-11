//
//  Created by Vonage on 8/6/26.
//

import Foundation

enum E2EHTTPRequestBodyDecoder {
    static func decode(_ data: Data?) throws -> [String: Any] {
        guard let data, !data.isEmpty else { return [:] }
        return (try JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
}

enum E2EHTTPResponseBuilder {
    static func envelope(_ data: [String: Any]) -> Data {
        encode([
            "result": [
                "data": data
            ]
        ])
    }

    static func errorBody(for endpoint: String) -> Data {
        encode([
            "error": [
                "message": "E2E forced failure for \(endpoint)",
                "code": "VERA_E2E_FORCED_FAILURE",
                "endpoint": endpoint,
            ]
        ])
    }

    private static func encode(_ value: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])) ?? Data()
    }
}

enum E2EIdentifier {
    static func stableIdentifier(from value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            .prefix(32)
            .description
    }
}
