//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing
import VERABackgroundEffects
import VERADomain

@Suite("Background blur value transfer")
struct BlurValueTransferTests {

    @Test("All blur levels preserve their raw values and Codable representation across tasks")
    func levelsAcrossTasks() async throws {
        let levels: [BlurLevel] = [.low, .high, .none]
        let rawValues = ["Low", "High", "None"]
        let received = await Task.detached { levels }.value

        #expect(received == levels)
        #expect(received.map(\.rawValue) == rawValues)
        for (level, rawValue) in zip(received, rawValues) {
            let encoded = try JSONEncoder().encode(level)
            #expect(try JSONDecoder().decode(String.self, from: encoded) == rawValue)
            #expect(try JSONDecoder().decode(BlurLevel.self, from: encoded) == level)
        }
    }

    @Test("Radius values preserve their JSON parameters across task and actor round trips")
    func radiiAcrossTasksAndActor() async throws {
        let levels: [BlurLevel] = [.low, .high, .none]
        let radii = levels.map { Radius(radius: $0) }
        let received = await Task.detached { radii }.value
        #expect(received.map(\.radius) == levels)

        let selection = BlurSelection()
        for (radius, level) in zip(received, levels) {
            await selection.update(radius)
            let selected = await selection.radius
            #expect(selected.radius == level)

            let encoded = try JSONEncoder().encode(selected)
            #expect(try JSONDecoder().decode([String: String].self, from: encoded) == ["radius": level.rawValue])
            #expect(try JSONDecoder().decode(Radius.self, from: encoded).radius == level)

            let parameters = try BackgroundBlur().params(blurLevel: selected.radius)
            let parameterData = Data(parameters.utf8)
            #expect(try JSONDecoder().decode([String: String].self, from: parameterData) == ["radius": level.rawValue])
        }
    }
}

private actor BlurSelection {
    private(set) var radius = Radius(radius: .none)

    func update(_ value: Radius) {
        radius = value
    }
}
