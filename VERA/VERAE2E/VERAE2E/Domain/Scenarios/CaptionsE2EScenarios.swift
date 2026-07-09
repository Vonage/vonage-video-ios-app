//
//  Created by Vonage on 29/6/26.
//

enum CaptionsE2EScenarios {
    static let captions = CaptionsE2EScenario()

    static let all: [String: any E2ETestScenario] = [
        captions.name: captions
    ]
}

struct CaptionsE2EScenario: E2ETestScenario {
    let name = "captions"
    let fixture: any E2EScenarioFixture = CaptionsE2EFixture()
}
