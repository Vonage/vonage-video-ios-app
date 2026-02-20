//
//  Created by Vonage on 6/2/26.
//

import SwiftUI

public struct CaptionsButtonContainer: View {

    @ObservedObject var viewModel: CaptionsButtonViewModel

    public init(viewModel: CaptionsButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CaptionsButton(
            state: viewModel.state,
            action: viewModel.onTap
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Disabled") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsButton(state: .disabled)
        }
        .padding(.bottom, 16)
    }
}

#Preview("Enabled") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsButton(state: .enabled(""))
        }
        .padding(.bottom, 16)
    }
}

#Preview("Enabled - With Captions") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsView(captions: [.previewAlice, .previewBob, .previewCharlie])
            CaptionsButton(state: .enabled(""))
        }
        .padding(.bottom, 16)
    }
}

#Preview("Enabled - Scrollable Captions") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            CaptionsView(captions: [
                .previewAlice, .previewBob, .previewCharlie,
                .previewDiana, .previewAlice2, .previewDiana2
            ])
            CaptionsButton(state: .enabled(""))
        }
        .padding(.bottom, 16)
    }
}
#endif
