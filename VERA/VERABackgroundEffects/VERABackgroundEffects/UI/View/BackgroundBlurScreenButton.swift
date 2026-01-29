//
//  Created by Vonage on 26/1/26.
//

import SwiftUI
import VERACommonUI

public struct BackgroundBlurScreenButton: View {

    @ObservedObject var viewModel: BackgroundBlurButtonViewModel

    public init(viewModel: BackgroundBlurButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        BackgroundBlurButton(
            image: viewModel.currentBlurLevel.image,
            action: viewModel.onTap)
    }
}

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
