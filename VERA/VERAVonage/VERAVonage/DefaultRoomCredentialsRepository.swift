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
/// The v2 flow requires two sequential calls:
/// 1. `POST /v2/createSession` — creates or retrieves a session, returns `sessionId` and `sessionKey` (JWT).
/// 2. `POST /v2/joinSession` — exchanges the `sessionKey` for a client `token`.
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

        // Step 1: Create session
        let createBody = try jsonEncoder.encode(CreateSessionRequestBody(roomName: request.roomName))
        let createData = try await httpClient.post(
            baseURL.appendingPathComponent("v2").appendingPathComponent("createSession"),
            data: createBody)
        let createResponse = try jsonDecoder.decode(
            TRPCResponse<CreateSessionResponse>.self, from: createData)

        // Step 2: Join session
        let joinBody = try jsonEncoder.encode(
            JoinSessionRequestBody(sessionKey: createResponse.result.data.sessionKey))
        let joinData = try await httpClient.post(
            baseURL.appendingPathComponent("v2").appendingPathComponent("joinSession"),
            data: joinBody)
        let joinResponse = try jsonDecoder.decode(
            TRPCResponse<JoinSessionResponse>.self, from: joinData)

        let credentials = RoomCredentialsResponse(
            sessionId: createResponse.result.data.sessionId,
            token: joinResponse.result.data.token,
            apiKey: createResponse.result.data.applicationId,
            sessionKey: createResponse.result.data.sessionKey)

        cache[request.roomName] = credentials

        return credentials
    }
}

private struct CreateSessionRequestBody: Encodable {
    let roomName: String
}

private struct JoinSessionRequestBody: Encodable {
    let sessionKey: String
}
