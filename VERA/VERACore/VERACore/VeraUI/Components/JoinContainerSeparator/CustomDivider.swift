//
//  Created by Vonage on 9/7/25.
//

import SwiftUI
import VERACommonUI

struct CustomDivider: View {
    let color: Color
    let height: CGFloat

    init(color: Color = VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor, height: CGFloat = 1) {
        self.color = color
        self.height = height
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}
