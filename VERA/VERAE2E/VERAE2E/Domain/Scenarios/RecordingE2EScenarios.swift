//
//  Created by Vonage on 29/6/26.
//

enum RecordingE2EScenarios {
    static let recording = RecordingE2EScenario()

    static let all: [String: any E2ETestScenario] = [
        recording.name: recording
    ]
}

struct RecordingE2EScenario: E2ETestScenario {
    let name = "recording"
    let fixture: any E2EScenarioFixture = RecordingE2EFixture()
}
