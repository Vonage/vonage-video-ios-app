//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct LandingPageWelcome: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to the Vonage Video iOS App", bundle: .veraCore)
                .font(.largeTitle.bold())
                .padding(.bottom, 10)
            Text("Create a new room or join an existing one.", bundle: .veraCore)
                .foregroundStyle(VERACommonUIAsset.uiSecondaryLabel.swiftUIColor)
        }
    }
}

#Preview {
    LandingPageWelcome()
}
