//
//  Created by Vonage on 29/6/26.
//

import VERADomain

public protocol E2ETestScenario: Sendable {
    var name: String { get }
    var fixture: any E2EScenarioFixture { get }
}

public protocol E2EScenarioFixture: Sendable {
    @MainActor var participantsState: ParticipantsState { get }
}

extension E2EScenarioFixture {
    @MainActor public var participantsState: ParticipantsState {
        .empty
    }
}
