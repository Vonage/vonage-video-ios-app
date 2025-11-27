//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct JoinButton: View {
    @Binding var roomName: String
    let color: Color
    let onJoinRoom: () -> Void

    var body: some View {
        OutlinedButton(
            text: Text("Join waiting room", bundle: .veraCore),
            color: color,
            isDisabled: roomName.isEmpty,
            onAction: onJoinRoom)
    }
}

#Preview {
    JoinButton(roomName: .constant(""), color: VERACommonUIAsset.Colors.vGray0.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: .red) {}
}
