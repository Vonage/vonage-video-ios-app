//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

struct ArchiveList: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recordings", bundle: .veraCore)
                .font(.largeTitle.bold())
                .padding(.bottom, 10)
            Text("There are no recordings for this meeting", bundle: .veraCore)
                .foregroundStyle(.uiSecondaryLabel)
        }
    }
}

#Preview {
    ArchiveList()
}
