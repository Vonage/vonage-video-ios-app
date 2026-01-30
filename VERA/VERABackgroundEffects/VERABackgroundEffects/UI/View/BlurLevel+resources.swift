//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI

extension BlurLevel {
    public var image: Image {
        switch self {
        case .low: VERACommonUIAsset.Images.blurLine.swiftUIImage
        case .high: VERACommonUIAsset.Images.blurSolid.swiftUIImage
        case .none: VERACommonUIAsset.Images.removeLine.swiftUIImage
        }
    }

    public var label: String {
        switch self {
        case .low: String(localized: "Low")
        case .high: String(localized: "High")
        case .none: String(localized: "None")
        }
    }
}
