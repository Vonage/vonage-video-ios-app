//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct GoodByeMessage: View {
    let onReenter: () -> Void
    let onReturnToLanding: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("You left the room", bundle: .veraCore)
                .adaptiveFont(.headline)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                .padding(.bottom, 10)
            Text("We hope you had fun", bundle: .veraCore)
                .adaptiveFont(.heading2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                .padding(.bottom, 20)
            HStack {
                ReenterRoomButton(onReenter: onReenter)
                GoToLandingPageButton(onReturnToLanding: onReturnToLanding)
            }
        }
    }
}

#Preview {
    GoodByeMessage {
    } onReturnToLanding: {
    }
}

#Preview {
    GoodByeMessage {
    } onReturnToLanding: {
    }
    .preferredColorScheme(.dark)
}
