//
//  Created by Vonage on 3/12/25.
//

import SwiftUI
import VERACommonUI

struct RejoinTheRoomText: View {
    var body: some View {
        Text("Rejoining the room", bundle: .veraCore)
            .adaptiveFont(.heading4)
            .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
    }
}
