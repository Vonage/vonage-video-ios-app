//
//  Created by Vonage on 21/7/25.
//

import AVFoundation
import Foundation

public final class RequestMicrophonePermissionUseCase {

    public init() {}

    public func callAsFunction() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return switch status {
        case .authorized: true
        case .notDetermined:
            await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .restricted, .denied: false
        @unknown default: false
        }
    }
}
