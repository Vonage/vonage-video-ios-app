//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// Provides the resource bundle for the VERAScreenShare framework.
extension Bundle {
    /// The bundle associated with the VERAScreenShare module.
    public static var veraScreenShare: Bundle { Bundle(for: VERAScreenShareBundleToken.self) }
}

private final class VERAScreenShareBundleToken {}
