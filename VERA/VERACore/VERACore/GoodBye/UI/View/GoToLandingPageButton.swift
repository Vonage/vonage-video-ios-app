//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct GoToLandingPageButton: View {
    let onReturnToLanding: () -> Void

    var body: some View {
        OutlinedButton(
            text: Text("View Landing Page", bundle: .veraCore),
            color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
            isDisabled: false,
            onAction: onReturnToLanding)
    }
}

#Preview {
    GoToLandingPageButton {}
}

#Preview {
    GoToLandingPageButton {}
        .preferredColorScheme(.dark)
}
