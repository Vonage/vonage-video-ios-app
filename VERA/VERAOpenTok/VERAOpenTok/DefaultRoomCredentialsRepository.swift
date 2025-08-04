//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERACore

public final class DefaultRoomCredentialsRepository: RoomCredentialsRepository {
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
