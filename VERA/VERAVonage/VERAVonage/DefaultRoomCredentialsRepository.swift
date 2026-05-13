//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERACore
import VERADomain

/// Default implementation of ``RoomCredentialsRepository`` that fetches video session credentials from the v2 API.
///
/// This actor provides thread-safe access to room credentials with built-in caching to minimize network requests.
/// Credentials are cached per room name and reused for subsequent requests to the same room.
///
/// The v2 flow uses a single call:
/// - `POST /v2/createSessionAndJoin` — creates (or retrieves) a session and joins it in one step,
///   returning `sessionId`, `sessionKey` (JWT), `applicationId`, and a client `token`.
///
/// ### Creating a Repository
/// - ``init(baseURL:httpClient:jsonDecoder:jsonEncoder:)``
///
/// ### Fetching Credentials
/// - ``getRoomCredentials(_:)``
public final actor DefaultRoomCredentialsRepository: RoomCredentialsRepository {
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let baseURL: URL
    private var cache: [String: RoomCredentialsResponse] = [:]

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    public func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse {
        if let cached = cache[request.roomName] {
            return cached
        }

        let createBody = try jsonEncoder.encode(CreateSessionAndJoinRequestBody(roomName: request.roomName))
        let createData = try await httpClient.post(
            baseURL.appendingPathComponent("v2").appendingPathComponent("createSessionAndJoin"),
            data: createBody)
        let response = try jsonDecoder.decode(
            TRPCResponse<CreateSessionAndJoinResponse>.self, from: createData)

        let credentials = RoomCredentialsResponse(
            sessionId: response.result.data.sessionId,
            token: response.result.data.token,
            apiKey: response.result.data.applicationId,
            sessionKey: response.result.data.sessionKey)

        cache[request.roomName] = credentials

        return credentials
    }
}
