//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct JoinButton: View {
    let color: Color
    let onJoinRoom: () -> Void

    var body: some View {
        OutlinedButton(
            text: Text("Join waiting room", bundle: .veraCore),
            color: color,
            onAction: onJoinRoom)
    }
}

#Preview {
    JoinButton(color: VERACommonUIAsset.Colors.vGray0.swiftUIColor) {}
    JoinButton(color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor) {}
    JoinButton(color: .red) {}
}
