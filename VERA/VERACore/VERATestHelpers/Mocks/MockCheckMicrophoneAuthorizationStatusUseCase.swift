//
//  Created by Vonage on 1/12/25.
//

import Foundation
import VERACore

public func makeMockCheckMicrophoneAuthorizationStatusUseCase(
    permissionStatus: PermissionStatus = .authorized,
) -> CheckMicrophoneAuthorizationStatusUseCase {
    MockCheckMicrophoneAuthorizationStatusUseCase(permissionStatus: permissionStatus)
}

public final class MockCheckMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase {
    public let permissionStatus: PermissionStatus

    public init(permissionStatus: PermissionStatus) {
        self.permissionStatus = permissionStatus
    }

    public func callAsFunction() -> PermissionStatus {
        permissionStatus
    }
}
