//
//  Created by Vonage on 30/7/25.
//

import Foundation
import VERACore

public func makeGetRoomCredentialsUseCase(
    baseURL: URL = makeMockBaseURL(),
    httpClient: MockHTTPClient = .init(),
    jsonDecoder: JSONDecoder = JSONDecoder()
) -> GetRoomCredentialsUseCase {
    GetRoomCredentialsUseCase(
        baseURL: baseURL,
        httpClient: httpClient,
        jsonDecoder: jsonDecoder)
}
