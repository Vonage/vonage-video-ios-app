//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol CheckCameraAuthorizationStatusUseCase : CheckPermissionUseCase {
}

public final class DefaultCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {

    public init() {}

    public func callAsFunction() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    public func isDenied() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .denied
    }
}
