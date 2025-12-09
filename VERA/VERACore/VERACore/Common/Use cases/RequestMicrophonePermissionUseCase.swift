//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol RequestMicrophonePermissionUseCase {
    func callAsFunction() async -> Bool
}

public final class DefaultRequestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase {

    public init() {}

    public func callAsFunction() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }
}
