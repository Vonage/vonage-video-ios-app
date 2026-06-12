//
//  Created by Vonage on 09/06/2026.
//

import VERADomain
import VERAE2E
import VERAMeetingRoomSDK

struct E2EMeetingRoomSessionRepositoryFactory: MeetingRoomSessionRepositoryFactory {
    func callAsFunction(
        _ context: MeetingRoomSessionRepositoryFactoryContext
    ) -> any SessionRepository {
        E2ESessionRepository(
            publisherSettings: context.publisherSettings,
            plugins: context.pluginRegistry.plugins)
    }
}
