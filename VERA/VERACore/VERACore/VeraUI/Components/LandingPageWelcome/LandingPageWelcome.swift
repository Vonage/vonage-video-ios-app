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
    }
}

struct LandingPageWelcomeCompact: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LandingTitleCompact()
                .padding(.bottom, 10)
                .adaptiveFont(.headline)
                .minimumScaleFactor(0.5)
        }
    }
}

struct LandingPageWelcomeRegular: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LandingTitleRegular()
                .adaptiveFont(.headline)
                .minimumScaleFactor(0.5)
                .padding(.bottom, 10)

            Text("Power your business with video that transforms customer satisfaction.", bundle: .veraCore)
                .adaptiveFont(.heading2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
        }
    }
}

struct LandingTitleRegular: View {
    var body: some View {
        (Text("Upgrade \n", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
            + Text("video \n", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            + Text("communication", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor))
    }
}

struct LandingTitleCompact: View {
    var body: some View {
        (Text("Upgrade ", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
            + Text("video \n", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.primary.swiftUIColor)
            + Text("communication", bundle: .veraCore)
            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor))
    }
}

#Preview {
    LandingPageWelcome()
}
