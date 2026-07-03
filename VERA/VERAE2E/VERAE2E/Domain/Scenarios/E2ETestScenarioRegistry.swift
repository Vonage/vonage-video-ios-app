//
//  Created by Vonage on 29/6/26.
//

public enum E2ETestScenarioRegistry {
    public static let defaultScenarioName = "default"

    private static let scenarioFamilies: [[String: any E2ETestScenario]] = [
        DefaultE2EScenarios.all,
        CaptionsE2EScenarios.all,
        ForceMuteE2EScenarios.all,
        RecordingE2EScenarios.all,
    ]

    public static func scenario(named name: String?) -> any E2ETestScenario {
        guard let name, !name.isEmpty else {
            return DefaultE2EScenarios.defaultScenario
        }

        return scenarioFamilies
            .lazy
            .compactMap { $0[name] }
            .first ?? DefaultE2EScenarios.defaultScenario
    }
}
