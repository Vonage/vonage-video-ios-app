//
//  Created by Vonage on 12/3/26.
//

import Foundation
import SwiftUI
import VERACommonUI

public struct MeetingNoiseSuppressionButtonContainer: View {

    @ObservedObject var viewModel: MeetingNoiseSuppressionViewModel

    public init(viewModel: MeetingNoiseSuppressionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        MeetingNoiseSuppressionButton(
            state: viewModel.state,
            action: viewModel.onTap)
    }
}

#if DEBUG
    #Preview("Disabled") {
        MeetingNoiseSuppressionButtonContainer(
            viewModel: .meetingPreviewDisabled
        )
    }

    #Preview("Enabled") {
        MeetingNoiseSuppressionButtonContainer(
            viewModel: .meetingPreviewEnabled
        )
    }
#endif
