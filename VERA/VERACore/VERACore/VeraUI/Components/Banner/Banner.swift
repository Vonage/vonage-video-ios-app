//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct Banner: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        HStack {
            BannerLogo()
            Spacer()
            if horizontalSizeClass == .regular {
                BannerDateTime()
            }
            BannerLinks()
        }
    }
}

#Preview {
    Banner()
}
