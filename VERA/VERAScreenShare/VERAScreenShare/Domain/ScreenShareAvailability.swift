//
//  Created by Vonage on 19/11/26.
//

import Foundation

/// Decides whether screen sharing is offered, and which system UI starts it.
public enum ScreenShareAvailability {
    /// `true` when this process can present `SCContentSharingPicker` (iOS 27+).
    public static var usesSystemContentPicker: Bool {
        #if os(iOS) && canImport(ScreenCaptureKit)
            if #available(iOS 27, *) {
                return true
            }
        #endif
        return false
    }

    /// Screen sharing stays available on iPhone and iPad.
    /// An iOS app running on Mac keeps it only when the system content picker exists,
    /// because the ReplayKit broadcast extension does not run there.
    public static func isFeatureAvailable(
        usesSystemContentPicker: Bool,
        isiOSAppOnMac: Bool
    ) -> Bool {
        usesSystemContentPicker || !isiOSAppOnMac
    }
}
