//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct LandingPageFactory {
    
    public init() {}
    
    public func make(
        onNavigateToWaitingRoom: @escaping (String)->Void
    ) -> some View {
        LandingPageScreen(
            viewModel: .init(tryJoinRoomUseCase: .init(roomNameValidator: .init())),
            onNavigateToWaitingRoom: onNavigateToWaitingRoom)
    }
}
