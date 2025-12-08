//
//  Created by Vonage on 18/11/25.
//

import SwiftUI
import VERACommonUI

struct HorizontalContentView<Left: View, Right: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State private var headerHeight: CGFloat = 0

    private let leftSide: () -> Left
    private let rightSide: () -> Right
    private let showHeader: Bool
    private let showFooter: Bool
    private let footerHeight: CGFloat = 40  // Altura fija del footer derecho

    init(
        showHeader: Bool = true,
        showFooter: Bool = true,
        @ViewBuilder leftSide: @escaping () -> Left,
        @ViewBuilder rightSide: @escaping () -> Right
    ) {
        self.showHeader = showHeader
        self.showFooter = showFooter
        self.leftSide = leftSide
        self.rightSide = rightSide
    }

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Side
            VStack(spacing: 0) {
                if showHeader {
                    HStack(spacing: 0) {
                        BannerLogo()
                        Spacer()
                    }
                    .padding(.top, 20)
                    .overlay(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    headerHeight = geo.size.height
                                }
                                .onChange(of: geo.size.height) { newHeight in
                                    headerHeight = newHeight
                                }
                        }
                    )
                }

                Spacer()

                leftSide()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if showHeader {
                    Color.clear
                        .frame(height: headerHeight)
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
                if showFooter {
                    Color.clear
                        .frame(height: footerHeight)
                }

                Spacer()

                rightSide()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()

                if showFooter {
                    HStack(spacing: 8) {
                        GHRepoButton()
                        Text("Vonage Video Reference Application", bundle: .veraCore)
                            .adaptiveFont(.bodyBase)
                            .foregroundColor(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: footerHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)
            .background(
                VERACommonUIAsset.SemanticColors.background.swiftUIColor
                    .ignoresSafeArea()
            )
        }
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
        .ignoresSafeArea(.keyboard)
        .if(iOS26Available()) {
            $0.ignoresSafeArea(edges: .top)
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
