//
//  Created by Vonage on 29/6/26.
//

import VERADomain

public protocol E2ETestScenario {
    var name: String { get }
    var fixture: any E2EScenarioFixture { get }
}

public protocol E2EScenarioFixture {
    var participantsState: ParticipantsState { get }
}

extension E2EScenarioFixture {
    public var participantsState: ParticipantsState {
        .empty
    }
}
