//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERATestHelpers
import VERAVonage

public func makeMockDefaultRoomCredentialsRepository(
    baseURL: URL = makeMockBaseURL(),
    httpClient: MockHTTPClient = .init(),
    jsonDecoder: JSONDecoder = JSONDecoder()
) -> DefaultRoomCredentialsRepository {
    DefaultRoomCredentialsRepository(
        baseURL: baseURL,
        httpClient: httpClient,
        jsonDecoder: jsonDecoder)
}
