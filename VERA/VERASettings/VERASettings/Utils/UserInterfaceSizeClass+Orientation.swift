//
//  Created by Vonage on 05/03/2026.
//

import SwiftUI

/// Extends `UserInterfaceSizeClass` to determine appropriate layout strategies.
extension UserInterfaceSizeClass {

    /// Whether the current device should use the split-view layout.
    ///
    /// - Returns: `true` on macOS or when the size class is `.regular` (typically iPad),
    ///   `false` otherwise (typically iPhone).
    public var isRegularLayout: Bool {
        #if os(macOS)
            return true
        #else
            return self == .regular
        #endif
    }
}
