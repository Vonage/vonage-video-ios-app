//
//  Created by Vonage on 2/12/25.
//

import Foundation
import VERACore

public func makeMockRequestCameraPermissionUseCase(
    isAuthorized: Bool = true
) -> MockRequestCameraPermissionUseCase {
    MockRequestCameraPermissionUseCase(isAuthorized: isAuthorized)
}

public final class MockRequestCameraPermissionUseCase: RequestCameraPermissionUseCase {
    public var isAuthorized: Bool = true

    public init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    public func callAsFunction() async -> Bool {
        isAuthorized
    }
}
