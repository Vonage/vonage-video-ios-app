//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct BannerLogo: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            Image("vonage-logo-mobile", bundle: .veraCore)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 30)
        } else {
            Image("vonage-logo-desktop", bundle: .veraCore)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 72)
        }

    }
}

#Preview {
    BannerLogo()
}
