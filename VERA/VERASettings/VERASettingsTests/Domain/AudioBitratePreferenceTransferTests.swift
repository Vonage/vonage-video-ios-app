//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("Audio bitrate preference value transfer")
struct AudioBitratePreferenceTransferTests {

    @Test("Default and custom bitrate preferences survive task and actor round trips")
    func preferencesAcrossTasksAndActor() async {
        let customValues: [Int32] = [.min, -1, 0, 64_000, .max]
        let preferences: [SettingsAudioBitratePreference] = [.default] + customValues.map { .custom($0) }
        let transferred = await Task.detached { preferences }.value
        #expect(transferred == preferences)

        let storage = AudioBitratePreferenceStorage()
        await storage.storePreferences(transferred)
        let received = await storage.preferences
        #expect(received == preferences)
        #expect(received.map(\.customValue) == [nil] + customValues.map { Optional($0) })
    }

    @Test("Transferred preferences preserve the existing Codable representation")
    func codableRepresentationAcrossTasks() async throws {
        let customValues: [Int32] = [.min, -1, 0, 64_000, .max]
        let fixtures: [(SettingsAudioBitratePreference, String)] =
            [(.default, "{\"default\":{}}")]
            + customValues.map { (.custom($0), "{\"custom\":{\"_0\":\($0)}}") }
        for (expected, json) in fixtures {
            let persisted = Data(json.utf8)
            let decoded = try JSONDecoder().decode(SettingsAudioBitratePreference.self, from: persisted)
            let transferred = await Task.detached { decoded }.value
            #expect(transferred == expected)
            #expect(try JSONEncoder().encode(transferred) == persisted)
        }
    }

    @Test("Selection mode raw values and identifiers survive task and actor round trips")
    func modesAcrossTasksAndActor() async {
        let modes = SettingsAudioBitrateMode.allCases
        let transferred = await Task.detached { modes }.value
        let storage = AudioBitratePreferenceStorage()
        await storage.storeModes(transferred)
        let received = await storage.modes
        #expect(received == [.default, .custom])
        #expect(received.map(\.rawValue) == ["default", "custom"])
        #expect(received.map(\.id) == ["default", "custom"])
        #expect(SettingsAudioBitrateMode(rawValue: "default") == .default)
        #expect(SettingsAudioBitrateMode(rawValue: "custom") == .custom)
        #expect(SettingsAudioBitrateMode(rawValue: "unsupported") == nil)
    }
}

private actor AudioBitratePreferenceStorage {
    private(set) var preferences: [SettingsAudioBitratePreference] = []
    private(set) var modes: [SettingsAudioBitrateMode] = []

    func storePreferences(_ values: [SettingsAudioBitratePreference]) {
        preferences = values
    }

    func storeModes(_ values: [SettingsAudioBitrateMode]) {
        modes = values
    }
}
