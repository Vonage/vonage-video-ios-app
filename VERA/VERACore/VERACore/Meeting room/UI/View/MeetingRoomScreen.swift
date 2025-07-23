//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

public struct MeetingRoomScreen: View {
    @ObservedObject var viewModel: MeetingRoomViewModel

    public init(viewModel: MeetingRoomViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if case let .content(state) = viewModel.state {
            MeetingRoomView(state: state)
                .task {
                    await viewModel.loadUI()
                }
        }

        if case .loading = viewModel.state {
            LoaderModalView()
        }

        if case let .error(error) = viewModel.state {
            Text("Error: \(error)")
        }
    }
}
