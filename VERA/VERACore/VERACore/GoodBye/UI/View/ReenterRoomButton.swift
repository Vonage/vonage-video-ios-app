//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct ReenterRoomButton: View {
    let onReenter: () -> Void

    var body: some View {
        OutlinedButton(
            text: Text("Re-enter", bundle: .veraCore),
            color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
            isDisabled: false,
            onAction: onReenter)
    }
}

#Preview {
    ReenterRoomButton {}
    ReenterRoomButton {}
    ReenterRoomButton {}
}
