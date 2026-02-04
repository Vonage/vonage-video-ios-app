//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol CheckCameraAuthorizationStatusUseCase: CheckPermissionUseCase {
}

public final class DefaultCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {

    public init() {}

    public func callAsFunction() -> PermissionStatus {
        AVCaptureDevice.authorizationStatus(for: .video).toPermissionStatus()
    }
}
