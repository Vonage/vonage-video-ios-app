//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct GoToLandingPageButton: View {
    let onReturnToLanding: () -> Void

    var body: some View {
        FilledButton(
            text: Text("Return to landing page", bundle: .veraCore),
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
