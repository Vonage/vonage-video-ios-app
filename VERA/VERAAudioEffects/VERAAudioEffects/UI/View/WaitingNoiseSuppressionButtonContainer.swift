//
//  Created by Vonage on 12/3/26.
//

import SwiftUI
import VERACommonUI

public struct WaitingNoiseSuppressionButtonContainer: View {

    @ObservedObject var viewModel: WaittingNoiseSuppressionViewModel

    public init(viewModel: WaittingNoiseSuppressionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        WaitingNoiseSuppressionButton(
            state: viewModel.state,
            action: viewModel.onTap)
    }
}

#if DEBUG
    #Preview("Disabled") {
        WaitingNoiseSuppressionButtonContainer(
            viewModel: .previewDisabled
        )
    }

    #Preview("Enabled") {
        WaitingNoiseSuppressionButtonContainer(
            viewModel: .previewEnabled
        )
    }
#endif
