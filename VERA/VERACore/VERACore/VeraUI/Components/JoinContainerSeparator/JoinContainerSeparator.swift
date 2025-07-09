//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct JoinContainerSeparator: View {
    var body: some View {
        HStack {
            VStack {
                CustomDivider()
            }
            Text("or")
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
