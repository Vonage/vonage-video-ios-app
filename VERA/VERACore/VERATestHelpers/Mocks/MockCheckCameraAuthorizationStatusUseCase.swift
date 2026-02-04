//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckCameraAuthorizationStatusUseCase(
    permissionStatus: PermissionStatus = .authorized,
) -> CheckCameraAuthorizationStatusUseCase {
    MockCheckCameraAuthorizationStatusUseCase(permissionStatus: permissionStatus)
}

public final class MockCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {
    public let permissionStatus: PermissionStatus

    public init(permissionStatus: PermissionStatus) {
        self.permissionStatus = permissionStatus
    }

    public func callAsFunction() -> PermissionStatus {
        permissionStatus
    }
}
