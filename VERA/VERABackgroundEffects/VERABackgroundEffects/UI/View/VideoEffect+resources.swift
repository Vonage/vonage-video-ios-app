//
//  Created by Vonage on 18/05/2026.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

extension VideoEffect {
    /// The icon representing this effect in the toolbar and effects picker.
    public var image: Image {
        switch self {
        case .none: VERACommonUIAsset.Images.removeLine.swiftUIImage
        case .blurLow: VERACommonUIAsset.Images.blurLine.swiftUIImage
        case .blurHigh: VERACommonUIAsset.Images.blurSolid.swiftUIImage
        case .backgroundImage: VERACommonUIAsset.Images.videoActiveLine.swiftUIImage
        }
    }

    /// A short localised label suitable for accessibility and bottom-bar tooltips.
    public var label: String {
        switch self {
        case .none: String(localized: "None")
        case .blurLow: String(localized: "Low")
        case .blurHigh: String(localized: "High")
        case .backgroundImage: String(localized: "Background")
        }
    }
}
