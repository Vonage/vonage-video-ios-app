//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import VERACommonUI
import VERADomain

public typealias OnTap = () -> Void

struct MeetingNoiseSuppressionButton: View {

    private let state: NoiseSuppressionState
    private let action: OnTap

    public init(
        state: NoiseSuppressionState,
        action: @escaping OnTap = {}
    ) {
        self.state = state
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: false,
            image: state.image,
            action: action)
    }
}


#if DEBUG
    #Preview("Disabled") {
        MeetingNoiseSuppressionButton(
            state: .disabled
        )
    }

    #Preview("Enabled") {
        MeetingNoiseSuppressionButton(
            state: .enabled
        )
    }
#endif
