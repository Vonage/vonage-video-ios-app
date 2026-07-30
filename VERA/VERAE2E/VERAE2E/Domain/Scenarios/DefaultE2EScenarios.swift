//
//  Created by Vonage on 29/6/26.
//

enum DefaultE2EScenarios {
    static let defaultScenario = DefaultE2EScenario()

    static let all: [String: any E2ETestScenario] = [
        defaultScenario.name: defaultScenario
    ]
}

struct DefaultE2EScenario: E2ETestScenario {
    let name = E2ETestScenarioRegistry.defaultScenarioName
    let fixture: any E2EScenarioFixture = DefaultE2EFixture()
}
