//
//  Created by Vonage on 18/11/26.
//

import Foundation

/// Builds a fake JWT (`header.payload.signature`) for tests, without real signing.
public func makeJWT(payload: [String: Any]) -> String {
    let header = jwtBase64URLEncode(
        (try? JSONSerialization.data(withJSONObject: ["alg": "HS256", "typ": "JWT"])) ?? Data())
    let payloadData = jwtBase64URLEncode(
        (try? JSONSerialization.data(withJSONObject: payload)) ?? Data())
    let signature = jwtBase64URLEncode(Data("fake-signature-bytes".utf8))
    return "\(header).\(payloadData).\(signature)"
}

private func jwtBase64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}
