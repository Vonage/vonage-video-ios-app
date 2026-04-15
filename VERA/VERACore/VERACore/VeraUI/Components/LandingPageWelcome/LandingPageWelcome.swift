//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

/// Layout constants for the landing page welcome section.
private enum LandingPageWelcomeConstants {
    /// Bottom padding beneath the headline title.
    static let titleBottomPadding: CGFloat = 10
    /// Minimum scale factor for the headline text.
    static let minimumScaleFactor: CGFloat = 0.5
}

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
                .lineLimit(2)
                .padding(.bottom, LandingPageWelcomeConstants.titleBottomPadding)
                .adaptiveFont(.headline)
                .minimumScaleFactor(LandingPageWelcomeConstants.minimumScaleFactor)
        }
    }
}

struct LandingPageWelcomeRegular: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LandingTitleRegular()
                .adaptiveFont(.headline)
                .lineLimit(3)
                .minimumScaleFactor(LandingPageWelcomeConstants.minimumScaleFactor)
                .padding(.bottom, LandingPageWelcomeConstants.titleBottomPadding)

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
