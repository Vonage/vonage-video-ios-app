//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI

struct MeetingBackgroundEffectButton: View {

    private let image: Image
    private let action: () -> Void

    public init(image: Image, action: @escaping () -> Void = {}) {
        self.image = image
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: false,
            image: image,
            action: action)
    }
}

#Preview {
    MeetingBackgroundEffectButton(
        image: VERACommonUIAsset.Images.blurLine.swiftUIImage
    ) {}
}
