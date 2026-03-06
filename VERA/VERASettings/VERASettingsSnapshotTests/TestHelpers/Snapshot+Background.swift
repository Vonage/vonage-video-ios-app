//
//  Created by Vonage on 05/03/2026.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func snapshotSafeUltraThinMaterial() -> some View {
        if ProcessInfo.processInfo.environment["IS_SNAPSHOT_TEST"] == "true" {
            self.background(Color.white.opacity(0.8))
        } else {
            self.background(.ultraThinMaterial)
        }
    }
}
