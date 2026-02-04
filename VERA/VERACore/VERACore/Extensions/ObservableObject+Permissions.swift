//
//  Created by Vonage on 30/01/2026.
//

import Combine

public typealias OnDenied = () -> Void

extension ObservableObject {
    public func ensurePermissionGranted(
        permissionChecker: CheckPermissionUseCase,
        onDenied: OnDenied?
    ) -> Bool {
        defer {
            if permissionChecker.isDenied() {
                onDenied?()
            }
        }
        return permissionChecker()
    }
    
    @MainActor
    public func requestPermission(
        permissionChecker: CheckPermissionUseCase,
        permissionRequester: RequestPermissionUseCase,
        onDenied: OnDenied?
    ) async -> Bool {
        var granted = false
        let wasPreviouslyDenied = permissionChecker.isDenied()
        if !wasPreviouslyDenied {
            granted = permissionChecker()
            if !granted {
                granted = await permissionRequester()
            }
        } else {
            onDenied?()
        }
        return granted
    }
}
