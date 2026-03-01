//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// Factory for creating the ScreenShare feature components.
///
/// Builds a pre-configured `ScreenShareView` ready for
/// embedding in the meeting room controls bar.
public final class ScreenShareFactory {
    
    public init() {
    }
    
    #if os(iOS)
    /// Creates the screen share button.
    ///
    /// - Parameters:
    ///   - broadcastExtensionBundleId: Bundle ID of the Broadcast Upload Extension.
    ///     Defaults to `"com.vonage.VERA.BroadcastExtension"`.
    /// - Returns: A `ScreenSharingButton`.
    @MainActor
    public static func make(
        broadcastExtensionBundleId: String = "com.vonage.VERA.BroadcastExtension"
    ) -> ScreenSharingButton {
        ScreenSharingButton(
            preferredExtension: broadcastExtensionBundleId)
    }
    #endif
}
