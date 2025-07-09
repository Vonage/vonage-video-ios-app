//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct LandingPageScreen: View {
    
    private let viewModel: LandingPageViewModel
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
            onNavigateToWaitingRoom: onNavigateToWaitingRoom)
        .onReceive(viewModel.$state) { value in
            switch value {
            case let .success(roomName): onNavigateToWaitingRoom(roomName)
                default: break
            }
        }
    }
}
