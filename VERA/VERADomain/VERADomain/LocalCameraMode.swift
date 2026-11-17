//
//  Created by Vonage on 1/11/26.
//

import Combine
import Foundation

/// How the local camera is published to the rest of the call.
///
/// `.dual` sends one video stream: the rear camera fills the frame and the front
/// camera sits in a small window. Other clients render it as a normal camera tile.
public enum LocalCameraMode: Sendable, Equatable {
    case front
    case back
    case dual

    /// The rear camera is the picture being aimed, in a one-to-one call or on its own.
    public var isShowingTheRoom: Bool {
        self == .dual || self == .back
    }

    /// The other single camera. Dual capture counts as the rear camera, so one flip returns to the front.
    public func flipped() -> LocalCameraMode {
        self == .front ? .back : .front
    }

    /// Shows or hides the front-camera window while the rear camera is the main view.
    ///
    /// Hiding the window leaves the rear camera on its own. Showing it returns to dual capture.
    public func hidingFrontCamera(_ hidden: Bool) -> LocalCameraMode {
        switch (self, hidden) {
        case (.dual, true):
            return .back
        case (.back, false):
            return .dual
        default:
            return self
        }
    }
}

/// Local camera controls for publishing the front and rear cameras together.
public protocol DualCaptureControllable: AnyObject {
    var localCameraMode: LocalCameraMode { get }
    var isDualCaptureAvailable: Bool { get }
    var localCameraModePublisher: AnyPublisher<LocalCameraMode, Never> { get }

    /// Hides the front camera while the rear camera stays on, or shows it again.
    func setFrontCameraHidden(_ hidden: Bool)
}
