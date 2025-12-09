//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI

struct EndCallControlButton: View {
    private let action: () -> Void

    init(action: @escaping () -> Void = {}) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VERACommonUIAsset.Images.endCallSolid.swiftUIImage
                .font(.title2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.red)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        EndCallControlButton()
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        EndCallControlButton()
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
