//
//  Created by Vonage on 18/11/25.
//

import SwiftUI
import VERACommonUI

struct VerticalContentView<Top: View, Bottom: View>: View {
    private let topSide: () -> Top
    private let bottomSide: () -> Bottom

    init(
        @ViewBuilder topSide: @escaping () -> Top,
        @ViewBuilder bottomSide: @escaping () -> Bottom
    ) {
        self.topSide = topSide
        self.bottomSide = bottomSide
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                BannerLogo()
                    .padding(.horizontal)
                Spacer()
            }
            .padding()

            topSide()
                .padding(.horizontal)

            bottomSide()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 8) {
                GHRepoButton()
                Text("Vonage Video Reference Application", bundle: .veraCore)
                    .adaptiveFont(.bodyBase)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal)
        }
        .background(
            VERACommonUIAsset.SemanticColors.background.swiftUIColor
                .ignoresSafeArea()
        )
    }
}

#Preview {
    VerticalContentView {
        Color.red
    } bottomSide: {
        Color.blue
    }
}
