//
//  Created by Vonage on 30/01/2026.
//

/// A protocol that defines the contract for requesting system permissions asynchronously.
///
/// Conforming types encapsulate the logic to prompt the user for a specific permission
/// (e.g., camera, microphone). Use this protocol when you need to trigger the system
/// permission dialog.
///
/// ## Conforming Types
/// - ``RequestCameraPermissionUseCase``
/// - ``RequestMicrophonePermissionUseCase``
///
/// ## Usage
/// ```swift
/// let requester: RequestPermissionUseCase = DefaultRequestCameraPermissionUseCase()
/// let granted = await requester()
/// ```
public protocol RequestPermissionUseCase {
    /// Requests the permission from the user asynchronously.
    /// - Returns: `true` if the permission was granted, `false` otherwise.
    func callAsFunction() async -> Bool
}

/// A protocol that defines the contract for checking the current authorization status of a system permission.
///
/// Conforming types provide synchronous methods to verify whether a permission has been granted
/// or explicitly denied by the user. This is useful for determining UI state or deciding whether
/// to request permission.
///
/// ## Conforming Types
/// - ``CheckCameraAuthorizationStatusUseCase``
/// - ``CheckMicrophoneAuthorizationStatusUseCase``
///
/// ## Usage
/// ```swift
/// let checker: CheckPermissionUseCase = DefaultCheckCameraAuthorizationStatusUseCase()
/// if checker.isDenied() {
///     // Show settings prompt
/// } else if !checker() {
///     // Request permission
/// }
/// ```
public protocol CheckPermissionUseCase {
    /// Checks whether the permission is currently authorized.
    /// - Returns: `true` if the permission is granted, `false` otherwise.
    func callAsFunction() -> Bool
    
    /// Checks whether the permission has been explicitly denied by the user.
    /// - Returns: `true` if the permission was denied, `false` if it's in another state
    ///   (e.g., not determined, authorized, or restricted).
    func isDenied() -> Bool
}


