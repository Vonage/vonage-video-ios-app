//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public protocol RequestCameraPermissionUseCase {
    func callAsFunction() async -> Bool
}

public final class DefaultRequestCameraPermissionUseCase: RequestCameraPermissionUseCase {

    public init() {}

    public func callAsFunction() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return if status == .authorized {
            true
        } else {
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}
