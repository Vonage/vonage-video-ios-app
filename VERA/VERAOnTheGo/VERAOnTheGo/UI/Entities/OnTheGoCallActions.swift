//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Actions ``OnTheGoViewModel`` performs on the host call. The host supplies
/// the closures; state changes always flow back through
/// ``OnTheGoCallSnapshot`` (single source of truth).
public struct OnTheGoCallActions {
    /// Toggles the local microphone.
    public var toggleMic: @MainActor () -> Void

    /// Toggles the local camera.
    public var toggleCamera: @MainActor () -> Void

    /// Leaves the call.
    public var endCall: @MainActor () -> Void

    public init(
        toggleMic: @escaping @MainActor () -> Void,
        toggleCamera: @escaping @MainActor () -> Void,
        endCall: @escaping @MainActor () -> Void
    ) {
        self.toggleMic = toggleMic
        self.toggleCamera = toggleCamera
        self.endCall = endCall
    }
}
