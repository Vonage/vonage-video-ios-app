//
//  Created by Vonage on 1/12/25.
//

import AVFoundation
import Foundation

public protocol CheckMicrophoneAuthorizationStatusUseCase : CheckPermissionUseCase {}

public final class DefaultCheckMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase {

    public init() {}

    public func callAsFunction() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    public func isDenied() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .denied
    }
}
