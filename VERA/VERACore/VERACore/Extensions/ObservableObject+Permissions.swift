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

        let currentStatus = permissionChecker()

        guard !currentStatus.isDenied,
            !currentStatus.isAuthorized
        else {
            return currentStatus
        }

        return await permissionRequester() ? .authorized : .denied
    }
}
