//
//  Created by Vonage on 13/11/25.
//

import SwiftUI

// MARK: - Border Radius

public enum BorderRadius {
    case none
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    public var value: CGFloat {
        switch self {
        case .none: return 0
        case .extraSmall: return 2
        case .small: return 4
        case .medium: return 8
        case .large: return 12
        case .extraLarge: return 24
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies semantic border radius
    /// - Parameter radius: The border radius style to apply
    /// - Returns: A view with rounded corners
    public func cornerRadius(_ radius: BorderRadius) -> some View {
        self.cornerRadius(radius.value)
    }
}
