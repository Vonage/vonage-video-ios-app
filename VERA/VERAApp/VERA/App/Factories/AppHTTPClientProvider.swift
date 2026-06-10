//
//  Created by Vonage on 09/06/2026.
//

import VERACore
import VERADomain
import VERAE2E
import VERAMeetingRoomSDK

public protocol HTTPClientProvider {
    func callAsFunction() -> any HTTPClient
}

struct AppHTTPClientProvider: HTTPClientProvider {

    private let isE2EEnabled: Bool

    init(isE2EEnabled: Bool) {
        self.isE2EEnabled = isE2EEnabled
    }

    func callAsFunction() -> any HTTPClient {
        let interceptor = OSLogHTTPClientInterceptor()

        if isE2EEnabled {
            return E2EHTTPClient(interceptor: interceptor)
        }

        return URLSessionHTTPClient(interceptor: interceptor)
    }
}

struct SharedMeetingRoomHTTPClientFactory: MeetingRoomHTTPClientFactory {
    let httpClient: any HTTPClient

    func callAsFunction(_: HTTPClientContext) -> any HTTPClient {
        httpClient
    }
}
