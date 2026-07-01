//
//  Created by Vonage on 8/6/26.
//

import Foundation

enum E2EHTTPBodyPreviewSanitizer {
    private static let maxLength = 2_048
    private static let sensitiveKeys: Set<String> = [
        "sessionkey",
        "token",
        "apikey",
        "applicationid",
        "password",
        "authorization",
        "jwt",
    ]

    static func preview(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        guard let body = String(data: data, encoding: .utf8) else {
            return "<non-utf8 body: \(data.count) bytes>"
        }

        let sanitizedBody = sanitize(body)
        guard sanitizedBody.count > maxLength else {
            return sanitizedBody
        }

        let endIndex = sanitizedBody.index(sanitizedBody.startIndex, offsetBy: maxLength)
        return "\(sanitizedBody[..<endIndex])... <truncated>"
    }

    private static func sanitize(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data)
        else {
            return body
        }

        let sanitizedJSON = sanitize(json)
        guard JSONSerialization.isValidJSONObject(sanitizedJSON),
            let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitizedJSON, options: [.sortedKeys]),
            let sanitizedBody = String(data: sanitizedData, encoding: .utf8)
        else {
            return body
        }

        return sanitizedBody
    }

    private static func sanitize(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, pair in
                if sensitiveKeys.contains(pair.key.lowercased()) {
                    result[pair.key] = "<redacted>"
                } else {
                    result[pair.key] = sanitize(pair.value)
                }
            }
        }

        if let array = value as? [Any] {
            return array.map(sanitize)
        }

        return value
    }
}
