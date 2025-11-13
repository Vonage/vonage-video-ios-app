//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct GHRepoButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = URL(string: "https://github.com/Vonage/vonage-video-ios-app") {
                openURL(url)
            }
        } label: {
            Image("github-mark", bundle: .veraCore)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
                .tint(VERACommonUIAsset.Colors.uiLabel.swiftUIColor.opacity(0.5))
        }
    }
}

#Preview {
    GHRepoButton()
}
