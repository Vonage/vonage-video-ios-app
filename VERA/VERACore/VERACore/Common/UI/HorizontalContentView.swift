//
//  Created by Vonage on 18/11/25.
//

import SwiftUI
import VERACommonUI

struct HorizontalContentView<Left: View, Right: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    private let leftSide: () -> Left
    private let rightSide: () -> Right

    init(
        @ViewBuilder leftSide: @escaping () -> Left,
        @ViewBuilder rightSide: @escaping () -> Right
    ) {
        self.leftSide = leftSide
        self.rightSide = rightSide
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    BannerLogo()
                    Spacer()
                }

                Spacer()
                leftSide()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()

                if verticalSizeClass == .regular {
                    Color.clear
                        .frame(height: 50)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .background(
                Color.clear
                    .ignoresSafeArea()
            )

            // MARK: - Right Side
            VStack(alignment: .center, spacing: 0) {
                Spacer()

                rightSide()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()

                HStack(spacing: 8) {
                    GHRepoButton()
                    Text("Vonage Video Reference Application", bundle: .veraCore)
                        .adaptiveFont(.bodyBase)
                        .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .background(
                VERACommonUIAsset.SemanticColors.background.swiftUIColor
                    .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    HorizontalContentView {
        Color.red
    } rightSide: {
        Color.blue
    }

}
