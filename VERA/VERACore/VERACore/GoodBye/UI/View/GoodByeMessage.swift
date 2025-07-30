//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

struct GoodByeMessage: View {
    let onReenter: () -> Void
    let onReturnToLanding: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("You left the room", bundle: .veraCore)
                .font(.largeTitle.bold())
                .padding(.bottom, 10)
            Text("We hope you had fun", bundle: .veraCore)
                .foregroundStyle(.uiSecondaryLabel)
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
