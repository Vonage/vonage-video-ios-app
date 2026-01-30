//
//  Created by Vonage on 30/01/2026.
//

import Combine

extension ObservableObject {
    public func checkAndRequestPermissionIfneeded(
        permissionChecker: CheckPermissionUseCase,
        permissionRequester: RequestPermissionUseCase
    ) async -> Bool {
        var granted = permissionChecker()
        if !granted {
            granted = await permissionRequester()
        }
        return granted
    }
}
