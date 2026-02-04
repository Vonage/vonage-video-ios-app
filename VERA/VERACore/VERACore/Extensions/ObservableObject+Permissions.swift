//
//  Created by Vonage on 30/01/2026.
//

import Combine

extension ObservableObject {
    @MainActor
    public func requestPermission(
        permissionChecker: CheckPermissionUseCase,
        permissionRequester: RequestPermissionUseCase
    ) async -> PermissionStatus {
        let permissionStatus = permissionChecker()
        if !permissionStatus.isDenied {
            if !permissionStatus.isAuthorized {
                _ = await permissionRequester()
            }
        }
        return permissionStatus
    }
}
