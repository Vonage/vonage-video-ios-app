//
//  Created by Vonage on 26/1/26.
//

import SwiftUI
import VERACommonUI

struct BackgroundBlurButton: View {

    private let image: Image
    private let action: () -> Void

    public init(image: Image, action: @escaping () -> Void = {}) {
        self.image = image
        self.action = action
    }

    var body: some View {
        CircularControlImageButton(
            isActive: true,
            image: image, action: action)
    }
}

#Preview {
    BackgroundBlurButton(
        image: VERACommonUIAsset.Images.blurLine.swiftUIImage,
        action: {}
    )
}
