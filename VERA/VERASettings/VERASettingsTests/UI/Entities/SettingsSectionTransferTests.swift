//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERASettings

@Suite("Settings section selection transfer")
struct SettingsSectionTransferTests {
    @Test("Selections retain case order, identifiers, raw values and icons across tasks and an actor")
    func selectionsAcrossTasksAndActor() async {
        let original = SettingsSection.allCases
        let transferred = await transfer(original)
        let storage = SettingsSectionStorage()
        await storage.update(transferred)
        let received = await storage.sections
        #expect(received == [.general, .video, .audio, .stats])
        #expect(received.map(\.id) == original)
        #expect(received.map(\.rawValue) == ["General", "Video", "Audio", "Stats"])
        #expect(received.map(\.iconName) == ["gear", "video", "waveform", "chart.bar"])
        #expect(received.map(\.displayName) == original.map(\.displayName))
        #expect(Set(received) == Set(original))
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }
}

private actor SettingsSectionStorage {
    private(set) var sections: [SettingsSection] = []

    func update(_ values: [SettingsSection]) {
        sections = values
    }
}
