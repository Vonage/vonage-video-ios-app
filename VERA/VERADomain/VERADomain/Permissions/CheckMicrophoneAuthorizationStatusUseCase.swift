//
//  Created by Vonage on 1/12/25.
//

import AVFoundation
import Foundation

public protocol CheckMicrophoneAuthorizationStatusUseCase: CheckPermissionUseCase {}

public final class DefaultCheckMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase {

    public init() {}

    public func callAsFunction() -> PermissionStatus {
        AVCaptureDevice.authorizationStatus(for: .audio).permissionStatus
    }
}
