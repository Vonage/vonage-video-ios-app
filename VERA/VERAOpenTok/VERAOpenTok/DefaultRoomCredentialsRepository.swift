//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERACore

/// Default implementation of ``RoomCredentialsRepository`` that fetches video session credentials from a remote server.
///
/// This actor provides thread-safe access to room credentials with built-in caching to minimize network requests.
/// Credentials are cached per room name and reused for subsequent requests to the same room.
///
/// ### Creating a Repository
/// - ``init(baseURL:httpClient:jsonDecoder:)``
///
/// ### Fetching Credentials
/// - ``getRoomCredentials(_:)``
public final actor DefaultRoomCredentialsRepository: RoomCredentialsRepository {
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let baseURL: URL
    private var cache: [String: RoomCredentialsResponse] = [:]

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
    }

    public func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse {
        if let cached = cache[request.roomName] {
            return cached
        }

        let response = try await httpClient.get(
            baseURL
                .appendingPathComponent("session")
                .appending(path: request.roomName))

        let credentials = try jsonDecoder.decode(RoomCredentialsResponse.self, from: response)
        cache[request.roomName] = credentials

        return credentials
    }
}
