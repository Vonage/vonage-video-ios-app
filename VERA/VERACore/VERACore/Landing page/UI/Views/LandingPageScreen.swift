//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

public struct LandingPageScreen: View {
    @ObservedObject var viewModel: LandingPageViewModel
    private let onNavigateToWaitingRoom: (String) -> Void

    public init(
        viewModel: LandingPageViewModel,
        onNavigateToWaitingRoom: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToWaitingRoom = onNavigateToWaitingRoom
    }

    public var body: some View {
        LandingPageView(
            onHandleNewRoom: viewModel.onHandleNewRoom,
            onJoinRoom: viewModel.onJoinRoom,
            onNavigateToWaitingRoom: onNavigateToWaitingRoom
        )
        .alert(item: $viewModel.error) { $0.view }
        .onReceive(viewModel.$state) { value in
            switch value {
            case .success(let roomName): onNavigateToWaitingRoom(roomName)
            default: break
            }
        }
    }
}
