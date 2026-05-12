//
//  Created by Vonage on 2/12/25.
//

import Foundation
import VERACore

public func makeMockRequestMicrophonePermissionUseCase(
    isAuthorized: Bool = true
) -> MockRequestMicrophonePermissionUseCase {
    MockRequestMicrophonePermissionUseCase(isAuthorized: isAuthorized)
}

public final class MockRequestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase {
    public var isAuthorized: Bool = true
    public var callCount: Int = 0

    public init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    public func callAsFunction() async -> Bool {
        callCount += 1
        return isAuthorized
    }
}
