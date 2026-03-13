//
//  Created by Vonage on 12/3/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct WaitingNoiseSuppressionButton: View {

    private let state: NoiseSuppressionState
    private let action: () -> Void

    public init(
        state: NoiseSuppressionState,
        action: @escaping OnTap = {}
    ) {
        self.state = state
        self.action = action
    }

    var body: some View {
        CircularControlImageButton(
            isActive: true,
            image: state.image,
            action: action)
    }
}

#if DEBUG
    #Preview("Disabled") {
        WaitingNoiseSuppressionButton(
            state: .disabled
        )
    }

    #Preview("Enabled") {
        WaitingNoiseSuppressionButton(
            state: .enabled
        )
    }
#endif
