//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckCameraAuthorizationStatusUseCase(
    isAuthorized: Bool = true
) -> CheckCameraAuthorizationStatusUseCase {
    MockCheckCameraAuthorizationStatusUseCase(isAuthorized: isAuthorized)
}

public final class MockCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {
    public var isAuthorized: Bool = true

    public init(isAuthorized: Bool) {
        self.isAuthorized = isAuthorized
    }

    public func callAsFunction() -> Bool {
        isAuthorized
    }
}
