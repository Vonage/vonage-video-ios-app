//
//  Created by Vonage on 1/11/26.
//

import AVFoundation
import Foundation

protocol DualCaptureAvailabilityChecking: Sendable {
    var isAvailable: Bool { get }
}

/// Simultaneous front and rear capture is a device capability, not an app setting.
struct DeviceDualCaptureAvailability: DualCaptureAvailabilityChecking, Sendable {
    var isAvailable: Bool {
        guard AVCaptureMultiCamSession.isMultiCamSupported else { return false }
        let rear = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        return rear != nil && front != nil
    }
}
