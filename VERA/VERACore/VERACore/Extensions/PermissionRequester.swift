//
//  Created by Vonage on 30/01/2026.
//

import VERADomain

/// Requests a media permission, returning the resulting ``PermissionStatus``.
///
/// This is a stateless helper. It was previously an `extension ObservableObject`
/// method purely for call-site visibility inside view models; it never used `self`.
/// After the migration to the `@Observable` macro, view models no longer conform
/// to `ObservableObject`, so the logic lives here as a free static function with
/// the same semantics.
public enum PermissionRequester {
    @MainActor
    public static func request(
        checker permissionChecker: CheckPermissionUseCase,
        requester permissionRequester: RequestPermissionUseCase
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
