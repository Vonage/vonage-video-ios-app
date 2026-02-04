//
//  Created by Vonage on 04/02/2026.
//

import AVFoundation

/// Represents the authorization status for device permissions such as camera and microphone.
///
/// This enum provides a unified way to handle permission states across the application,
/// abstracting away the underlying system-specific authorization status types.
public enum PermissionStatus {

    /// The user has not yet been asked for permission.
    /// This is the initial state before any permission request has been made.
    case notDetermined

    /// The user cannot grant permission due to system restrictions.
    /// This typically occurs when parental controls or device management policies prevent access.
    case restricted

    /// The user has explicitly denied permission.
    /// The app should guide the user to Settings to enable the permission if needed.
    case denied

    /// The user has granted permission.
    /// The app can freely access the requested resource.
    case authorized
}

// MARK: - Computed Properties

extension PermissionStatus {
    /// A Boolean value indicating whether the permission has been granted.
    ///
    /// Returns `true` only when the status is `.authorized`, `false` for all other states.
    public var isAuthorized: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }

    /// A Boolean value indicating whether the permission has been explicitly denied by the user.
    ///
    /// Returns `true` only when the status is `.denied`, `false` for all other states.
    /// Note: This does not include `.restricted` status, which represents system-level restrictions.
    public var isDenied: Bool {
        switch self {
        case .denied: return true
        default: return false
        }
    }
}

// MARK: - AVAuthorizationStatus Conversion

extension AVAuthorizationStatus {

    /// Converts the system's `AVAuthorizationStatus` to the app's `PermissionStatus` type.
    ///
    /// This method provides a bridge between Apple's AVFoundation authorization status
    /// and the application's unified permission status representation.
    ///
    /// - Returns: The corresponding `PermissionStatus` value.
    ///   Unknown future cases default to `.notDetermined` for forward compatibility.
    func toPermissionStatus() -> PermissionStatus {
        switch self {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .notDetermined
        }
    }
}
