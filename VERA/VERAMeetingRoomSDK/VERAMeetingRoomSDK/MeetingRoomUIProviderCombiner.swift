//
//  Created by Vonage on 30/6/26.
//

import Combine
import SwiftUI
import VERAMeetingRoom

enum MeetingRoomUIProviderCombiner {
    static func combine(
        sdkProvider: any MeetingRoomUIProvider,
        customProvider: (any MeetingRoomUIProvider)?
    ) -> any MeetingRoomUIProvider {
        guard let customProvider else {
            return sdkProvider
        }

        let bottomBarContent: @MainActor (MeetingRoomBottomBarContext) -> AnyView? = { context in
            customProvider.bottomBarContent(context: context)
        }

        return DefaultMeetingRoomUIProvider(
            bottomBarButtons: {
                sdkProvider.bottomBarButtons() + customProvider.bottomBarButtons()
            },
            updates: Publishers.Merge(
                sdkProvider.updates,
                customProvider.updates
            )
            .eraseToAnyPublisher(),
            bottomBarContent: bottomBarContent
        )
    }
}
