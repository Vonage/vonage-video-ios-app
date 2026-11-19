//
//  Created by Vonage on 29/6/26.
//

enum ExpiredSessionKeyE2EScenarios {
    static let expiredSessionKey = ExpiredSessionKeyE2EScenario()

    static let all: [String: any E2ETestScenario] = [
        expiredSessionKey.name: expiredSessionKey
    ]
}

struct ExpiredSessionKeyE2EScenario: E2ETestScenario {
    let name = "expiredSessionKey"
    let fixture: any E2EScenarioFixture = ExpiredSessionKeyE2EFixture()
}
