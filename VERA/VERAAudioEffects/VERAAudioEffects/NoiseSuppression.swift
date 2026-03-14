//
//  Created by Vonage on 12/3/26.
//

import Foundation

public struct NoiseSuppression {
    public static let key = "NoiseSuppression"

    public init() {}

    // Vonage noise suppression typically doesn't require parameters
    public func params() -> String {
        return ""
    }
}
