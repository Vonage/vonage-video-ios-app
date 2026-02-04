//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckCameraAuthorizationStatusUseCase(
    isAuthorized: Bool = true,
    isDenied: Bool = false
) -> CheckCameraAuthorizationStatusUseCase {
    MockCheckCameraAuthorizationStatusUseCase(isAuthorized: isAuthorized, isDenied: isDenied)
}

public final class MockCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {
    public var isAuthorized: Bool = true
    public var isPermissionDenied: Bool = true

    public init(isAuthorized: Bool, isDenied: Bool) {
        self.isAuthorized = isAuthorized
        self.isPermissionDenied = isDenied
    }

    public func callAsFunction() -> Bool {
        isAuthorized
    }
    
    public func isDenied() -> Bool {
        isPermissionDenied
    }
}
