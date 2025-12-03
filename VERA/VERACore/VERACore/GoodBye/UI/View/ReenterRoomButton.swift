//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

struct ReenterRoomButton: View {
    let onReenter: () -> Void

    var body: some View {
        FilledButton(
            text: Text("Go back to meeting", bundle: .veraCore),
            image: VERACommonUIAsset.Images.enterLine.swiftUIImage,
            onAction: onReenter)
    }
}

#Preview {
    ReenterRoomButton {}
    ReenterRoomButton {}
    ReenterRoomButton {}
}
