//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct GoodByeMessage: View {

    let showSubtitle: Bool

    init(showSubtitle: Bool = true) {
        self.showSubtitle = showSubtitle
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("You have left the meeting.", bundle: .veraCore)
                .adaptiveFont(.headline)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                .padding(.bottom, 10)
            if showSubtitle {
                Text("Thank you for joining!", bundle: .veraCore)
                    .adaptiveFont(.heading2)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                    .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    GoodByeMessage(showSubtitle: true)
    GoodByeMessage(showSubtitle: false)
}

#Preview {
    GoodByeMessage(showSubtitle: true)
        .preferredColorScheme(.dark)
}
