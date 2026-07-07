//
//  Created by Vonage on 29/6/26.
//

enum ForceMuteE2EScenarios {
    static let forceMute = ForceMuteE2EScenario()

    static let all: [String: any E2ETestScenario] = [
        forceMute.name: forceMute
    ]
}

struct ForceMuteE2EScenario: E2ETestScenario {
    let name = "force-mute"
    let fixture: any E2EScenarioFixture = ForceMuteE2EFixture()
}
