//
//  Created by Vonage on 30/06/2026.
//

import Foundation

/// Utility for parsing session key JWTs to extract metadata.
///
/// Session keys are JWTs with the structure `header.payload.signature`.
/// The payload contains claims such as `roomName` and `sessionId`.
///
/// This parser performs minimal JWT inspection without cryptographic verification,
/// as the server handles token validation.
public enum SessionKeyParser {

    /// Checks whether a given string looks like a valid JWT session key.
    ///
    /// A JWT consists of three base64url-encoded segments separated by dots.
    /// Additionally, each segment must have a minimum length to avoid false positives
    /// with short dotted strings.
    /// - Parameter value: The string to check.
    /// - Returns: `true` if the string matches the JWT format.
    public static func isSessionKey(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return false }
        // Real JWT headers and payloads are substantially longer than typical room names.
        // A minimal JWT header like {"alg":"HS256"} encodes to ~20+ characters.
        guard parts[0].count >= 20, parts[1].count >= 20 else { return false }
        return parts.allSatisfy { isBase64URLEncoded(String($0)) }
    }

    /// Extracts the room name from a session key JWT payload.
    ///
    /// The JWT payload is expected to contain a `roomName` field.
    /// - Parameter sessionKey: The JWT string.
    /// - Returns: The room name if it can be extracted, or `nil`.
    public static func extractRoomName(from sessionKey: String) -> String? {
        guard let payload = decodePayload(sessionKey) else { return nil }
        return payload["roomName"] as? String
    }

    /// Extracts the session ID from a session key JWT payload.
    ///
    /// The JWT payload is expected to contain a `sessionId` field.
    /// - Parameter sessionKey: The JWT string.
    /// - Returns: The session ID if it can be extracted, or `nil`.
    public static func extractSessionId(from sessionKey: String) -> String? {
        guard let payload = decodePayload(sessionKey) else { return nil }
        return payload["sessionId"] as? String
    }

    // MARK: - Private

    private static func decodePayload(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }

        let payloadSegment = String(parts[1])
        guard let data = base64URLDecode(payloadSegment) else { return nil }

        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 =
            string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64.append(contentsOf: repeatElement("=", count: 4 - remainder))
        }

        return Data(base64Encoded: base64)
    }

    private static func isBase64URLEncoded(_ string: String) -> Bool {
        guard !string.isEmpty else { return false }
        let allowedCharacters = CharacterSet(
            charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=")
        return string.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}
