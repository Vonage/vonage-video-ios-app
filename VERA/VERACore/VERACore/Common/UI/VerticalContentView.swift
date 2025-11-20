//
//  Created by Vonage on 18/11/25.
//

import SwiftUI
import VERACommonUI

struct VerticalContentView<Top: View, Bottom: View>: View {
    private let topSide: () -> Top
    private let bottomSide: () -> Bottom
    private let showLogo: Bool

    init(
        showLogo: Bool = true,
        @ViewBuilder topSide: @escaping () -> Top,
        @ViewBuilder bottomSide: @escaping () -> Bottom
    ) {
        self.showLogo = showLogo
        self.topSide = topSide
        self.bottomSide = bottomSide
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showLogo {
                HStack(spacing: 0) {
                    BannerLogo()
                        .padding(.horizontal)
                    Spacer()
                }
                .padding()
            }

            topSide()

            bottomSide()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 8) {
                GHRepoButton()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal)
        }
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    VerticalContentView {
        Color.red
    } bottomSide: {
        Color.blue
    }
}
