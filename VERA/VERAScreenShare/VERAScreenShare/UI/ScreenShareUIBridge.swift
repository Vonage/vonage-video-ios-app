//
//  Created by Vonage on 19/11/26.
//

import Foundation

/// Lets the meeting-room button present the system content picker without owning the capturer.
@MainActor
public final class ScreenShareUIBridge {
    public static let shared = ScreenShareUIBridge()

    /// Installed for the duration of a call when ScreenCaptureKit is available.
    public var presentSystemPicker: (@MainActor () -> Void)?

    public func present() {
        presentSystemPicker?()
    }
}
