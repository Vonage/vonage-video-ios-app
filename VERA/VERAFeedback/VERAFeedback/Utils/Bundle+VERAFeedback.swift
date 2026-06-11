//
//  Created by Vonage on 3/6/26.
//

import Foundation

/// Provides the resource bundle for the VERAFeedback framework.
extension Bundle {
    /// The bundle associated with the VERAFeedback module.
    public static var veraFeedback: Bundle { Bundle(for: VERAFeedbackBundleToken.self) }
}

private final class VERAFeedbackBundleToken {}
