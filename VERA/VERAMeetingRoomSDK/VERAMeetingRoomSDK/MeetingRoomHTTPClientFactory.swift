//
//  Created by Vonage on 09/06/2026.
//

import VERACore
import VERADomain

public struct HTTPClientContext {
    public let interceptor: any HTTPClientInterceptor

    public init(interceptor: any HTTPClientInterceptor) {
        self.interceptor = interceptor
    }
}

public protocol MeetingRoomHTTPClientFactory {
    func callAsFunction(_ context: HTTPClientContext) -> any HTTPClient
}

public struct DefaultMeetingRoomHTTPClientFactory: MeetingRoomHTTPClientFactory {

    public init() {}

    public func callAsFunction(_ context: HTTPClientContext) -> any HTTPClient {
        URLSessionHTTPClient(interceptor: context.interceptor)
    }
}
