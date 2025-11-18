//
//  Created by Vonage on 18/11/25.
//

import SwiftUI
import VERACommonUI

struct CardView<Content: View>: View {

    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
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
