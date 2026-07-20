//
//  Created by Vonage on 02/07/2026.
//

import SwiftUI

struct ActiveCallWarningText: View {
    var body: some View {
        Text("Cannot be changed during an active call".localized)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
