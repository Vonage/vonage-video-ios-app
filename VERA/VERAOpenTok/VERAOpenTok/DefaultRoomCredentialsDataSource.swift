//
//  Created by Vonage on 17/7/25.
//

import Foundation

public struct RoomCredentialsResponse: Decodable {
    public let sessionId: String
    public let token: String
    public let apiKey: String
    public let captionsId: String?
}

public struct RoomCredentialsRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public final class DefaultRoomCredentialsDataSource {

    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let baseURL: URL

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
    }

    public func getRoomCredentials(
        _ request: RoomCredentialsRequest
    ) async throws -> RoomCredentialsResponse {
        let data = try await httpClient.get(
            baseURL
                .appendingPathComponent("session")
                .appending(path: request.roomName))
        return try jsonDecoder.decode(RoomCredentialsResponse.self, from: data)
    }
}
