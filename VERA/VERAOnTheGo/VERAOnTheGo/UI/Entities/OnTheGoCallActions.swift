//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Actions ``OnTheGoViewModel`` performs on the host call. The host supplies
/// the closures; state changes always flow back through
/// ``OnTheGoCallSnapshot`` (single source of truth).
public struct OnTheGoCallActions {
    /// Toggles the local microphone.
    public var toggleMic: () -> Void

    /// Toggles the local camera.
    public var toggleCamera: () -> Void

    /// Leaves the call.
    public var endCall: () -> Void

    public init(
        toggleMic: @escaping () -> Void,
        toggleCamera: @escaping () -> Void,
        endCall: @escaping () -> Void
    ) {
        self.toggleMic = toggleMic
        self.toggleCamera = toggleCamera
        self.endCall = endCall
    }
}
