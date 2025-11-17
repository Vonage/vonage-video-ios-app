//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct NewRoomButton: View {

    let onHandleNewRoom: () -> Void

    var body: some View {
        FilledButton(
            text: Text("Create room", bundle: .veraCore),
            image: VERACommonUIAsset.Images.plusLine.swiftUIImage,
            onAction: onHandleNewRoom)
    }
}

#Preview {
    NewRoomButton {}
}
