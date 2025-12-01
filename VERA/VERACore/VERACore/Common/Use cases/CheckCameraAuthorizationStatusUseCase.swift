//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol CheckCameraAuthorizationStatusUseCase {
    func callAsFunction() -> Bool
}

public final class DefaultCheckCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase {

    public init() {}

    public func callAsFunction() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
}
