//
//  Created by Vonage on 7/5/26.
//

import Foundation

/// Generic wrapper for tRPC-over-HTTP JSON-RPC responses.
///
/// All v2 API responses follow the envelope: `{ "result": { "data": <payload> } }`.
/// Use `TRPCResponse<MyPayload>` to decode the outer structure automatically.
public struct TRPCResponse<T: Decodable>: Decodable {
    public let result: TRPCResult<T>
}

public struct TRPCResult<T: Decodable>: Decodable {
    public let data: T
}
