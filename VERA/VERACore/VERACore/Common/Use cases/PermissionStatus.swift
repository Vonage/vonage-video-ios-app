//
//  Created by Vonage on 04/02/2026.
//

import AVFoundation

public enum PermissionStatus {

    case notDetermined

    case restricted

    case denied

    case authorized
}

extension PermissionStatus {
    public var isAuthorized: Bool {
        switch self {
        case .authorized: return true
        default: return false
        }
    }

    public var isDenied: Bool {
        switch self {
        case .denied: return true
        default: return false
        }
    }
}

extension AVAuthorizationStatus {

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
