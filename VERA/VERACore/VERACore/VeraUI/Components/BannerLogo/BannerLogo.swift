//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

/// Layout constants for the banner logo component.
private enum BannerLogoConstants {
    /// Height of the logo in compact (mobile) layout.
    static let compactHeight: CGFloat = 30
    /// Height of the logo in regular (desktop/tablet) layout.
    static let regularHeight: CGFloat = 78
}

struct BannerLogo: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            VERACoreAsset.logoMobile.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: BannerLogoConstants.compactHeight)
        } else {
            VERACoreAsset.logoDesktop.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: BannerLogoConstants.regularHeight)
        }
    }
}

#Preview {
    BannerLogo()
}
