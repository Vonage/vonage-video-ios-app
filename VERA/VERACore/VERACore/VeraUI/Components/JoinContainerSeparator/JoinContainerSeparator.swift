//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct JoinContainerSeparator: View {
    var body: some View {
        HStack {
            VStack {
                CustomDivider()
            }
            Text("or", bundle: .veraCore)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.textTertiary.swiftUIColor)
                .padding()
            VStack {
                CustomDivider()
            }
        }
    }
}

#Preview {
    JoinContainerSeparator()
}
