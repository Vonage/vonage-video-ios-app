//
//  Created by Vonage on 18/11/25.
//

import SwiftUI

public struct CardView<Content: View>: View {

    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        VStack {
            content()
        }
        .padding()
        .background(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
        .cornerRadius(.medium)
    }
}

#Preview {
    CardView {
        Color.red
    }
}
