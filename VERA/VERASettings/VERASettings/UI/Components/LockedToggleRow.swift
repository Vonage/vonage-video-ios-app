//
//  Created by Vonage on 23/06/2026.
//

import SwiftUI

public struct LockedToggleRow: View {
    let title: String
    let value: Bool

    public var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ? "Enabled".localized : "Disabled".localized)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 2)
    }
}
