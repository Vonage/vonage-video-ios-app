//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct LandingPageWelcome: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        VStack(alignment: .leading) {
            if verticalSizeClass == .compact {
                LandingPageWelcomeRegular()
            } else if horizontalSizeClass == .compact {
                LandingPageWelcomeCompact()
            } else {
                LandingPageWelcomeRegular()
            }
        }
        .padding()
    }
}

struct LandingPageWelcomeCompact: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        VStack(alignment: .leading) {
            Text("Upgrade video communication", bundle: .veraCore)
                .padding(.bottom, 10)
                .adaptiveFont(.headline)
        }
    }
}

struct LandingPageWelcomeRegular: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        VStack(alignment: .leading) {
            (Text("Upgrade\n", bundle: .veraCore) +
             Text("video\n", bundle: .veraCore)
                .foregroundColor(VERACommonUIAsset.SemanticColors.primary.swiftUIColor) +
             Text("communication", bundle: .veraCore))
                .adaptiveFont(.headline)
                .minimumScaleFactor(0.5)
                .padding(.bottom, 10)

            Text("Power your business with video that transforms customer satisfaction.", bundle: .veraCore)
                .adaptiveFont(.heading2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
        }
    }
}

#Preview {
    LandingPageWelcome()
}
